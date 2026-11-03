use std::sync::atomic::{AtomicU8, Ordering};
use std::sync::Arc;
use std::time::{Duration, Instant};

const BATCH: u32 = 1_048_576;
const CAPACITY: u32 = 256;
/// Vector de comprobación del shader WGSL u32 (preestado y objetivos igual/menor) calculado en CPU.
pub const VECTOR: &str = include_str!("../shaders/quantus-vector.json");

pub struct QuantusWebGpu {
    device: wgpu::Device,
    queue: wgpu::Queue,
    params: wgpu::Buffer,
    results: wgpu::Buffer,
    staging: wgpu::Buffer,
    _constants: wgpu::Buffer,
    pipeline: wgpu::ComputePipeline,
    group: wgpu::BindGroup,
    name: String,
}

impl QuantusWebGpu {
    pub async fn new() -> Result<Self, Box<dyn std::error::Error>> {
        let backends = match std::env::var("TOKENMINER_WGPU_BACKEND").as_deref() {
            Ok("dx12") => wgpu::Backends::DX12,
            Ok("vulkan") => wgpu::Backends::VULKAN,
            _ => wgpu::Backends::PRIMARY,
        };
        let instance = wgpu::Instance::new(&wgpu::InstanceDescriptor {
            backends,
            ..Default::default()
        });
        let mut adapters = instance.enumerate_adapters(backends);
        adapters.retain(|adapter| adapter.get_info().device_type == wgpu::DeviceType::DiscreteGpu);
        adapters.sort_by_key(|adapter| match adapter.get_info().backend {
            wgpu::Backend::Vulkan => 0,
            wgpu::Backend::Dx12 => 1,
            _ => 2,
        });
        let adapter = adapters
            .into_iter()
            .next()
            .ok_or("No se encontró una GPU discreta")?;
        let name = adapter.get_info().name;
        let (device, queue) = adapter
            .request_device(&wgpu::DeviceDescriptor {
                label: Some("TokenMiner Quantus u32"),
                required_features: wgpu::Features::empty(),
                required_limits: wgpu::Limits::default(),
                memory_hints: Default::default(),
                ..Default::default()
            })
            .await?;
        let params = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("Preestado Quantus"),
            size: 240,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let results = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("Candidatos Quantus"),
            size: (CAPACITY as u64 + 1) * 4,
            usage: wgpu::BufferUsages::STORAGE
                | wgpu::BufferUsages::COPY_SRC
                | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let staging = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("Lectura Quantus"),
            size: (CAPACITY as u64 + 1) * 4,
            usage: wgpu::BufferUsages::MAP_READ | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let constants = device.create_buffer(&wgpu::BufferDescriptor {
            label: Some("Constantes Quantus"),
            size: 118 * 16,
            usage: wgpu::BufferUsages::UNIFORM | wgpu::BufferUsages::COPY_DST,
            mapped_at_creation: false,
        });
        let layout = device.create_bind_group_layout(&wgpu::BindGroupLayoutDescriptor {
            label: Some("TokenMiner Quantus"),
            entries: &[
                wgpu::BindGroupLayoutEntry {
                    binding: 0,
                    visibility: wgpu::ShaderStages::COMPUTE,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Uniform,
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 1,
                    visibility: wgpu::ShaderStages::COMPUTE,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Storage { read_only: false },
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                },
                wgpu::BindGroupLayoutEntry {
                    binding: 2,
                    visibility: wgpu::ShaderStages::COMPUTE,
                    ty: wgpu::BindingType::Buffer {
                        ty: wgpu::BufferBindingType::Uniform,
                        has_dynamic_offset: false,
                        min_binding_size: None,
                    },
                    count: None,
                },
            ],
        });
        let pipeline_layout = device.create_pipeline_layout(&wgpu::PipelineLayoutDescriptor {
            label: None,
            bind_group_layouts: &[&layout],
            push_constant_ranges: &[],
        });
        let shader = device.create_shader_module(wgpu::ShaderModuleDescriptor {
            label: Some("Shader Quantus TokenMiner u32"),
            source: wgpu::ShaderSource::Wgsl(
                include_str!("../shaders/quantus-tokenminer-u32.wgsl").into(),
            ),
        });
        let pipeline = device.create_compute_pipeline(&wgpu::ComputePipelineDescriptor {
            label: Some("Quantus u32"),
            layout: Some(&pipeline_layout),
            module: &shader,
            entry_point: Some("minar"),
            compilation_options: Default::default(),
            cache: None,
        });
        let group = device.create_bind_group(&wgpu::BindGroupDescriptor {
            label: None,
            layout: &layout,
            entries: &[
                wgpu::BindGroupEntry {
                    binding: 0,
                    resource: params.as_entire_binding(),
                },
                wgpu::BindGroupEntry {
                    binding: 1,
                    resource: results.as_entire_binding(),
                },
                wgpu::BindGroupEntry {
                    binding: 2,
                    resource: constants.as_entire_binding(),
                },
            ],
        });
        Ok(Self {
            device,
            queue,
            params,
            results,
            staging,
            _constants: constants,
            pipeline,
            group,
            name,
        })
    }

    pub fn name(&self) -> &str {
        &self.name
    }

    fn mine_slice(
        &self,
        prestate: &[u32; 24],
        target: &[u32; 8],
        counter: u64,
        count: u32,
    ) -> Result<Vec<u32>, Box<dyn std::error::Error>> {
        let mut data = [0u32; 60];
        for i in 0..12 {
            data[i * 4] = prestate[i * 2];
            data[i * 4 + 1] = prestate[i * 2 + 1];
        }
        data[48..56].copy_from_slice(target);
        data[56] = counter as u32;
        data[57] = (counter >> 32) as u32;
        data[58] = count;
        self.queue
            .write_buffer(&self.params, 0, bytemuck::cast_slice(&data));
        self.queue.write_buffer(&self.results, 0, &[0, 0, 0, 0]);
        let mut encoder = self
            .device
            .create_command_encoder(&wgpu::CommandEncoderDescriptor { label: None });
        {
            let mut pass = encoder.begin_compute_pass(&wgpu::ComputePassDescriptor {
                label: None,
                timestamp_writes: None,
            });
            pass.set_pipeline(&self.pipeline);
            pass.set_bind_group(0, &self.group, &[]);
            pass.dispatch_workgroups(count.div_ceil(512), 1, 1);
        }
        encoder.copy_buffer_to_buffer(
            &self.results,
            0,
            &self.staging,
            0,
            (CAPACITY as u64 + 1) * 4,
        );
        self.queue.submit(Some(encoder.finish()));
        let slice = self.staging.slice(..);
        let state = Arc::new(AtomicU8::new(0));
        let callback_state = state.clone();
        slice.map_async(wgpu::MapMode::Read, move |result| {
            callback_state.store(if result.is_ok() { 1 } else { 2 }, Ordering::Release)
        });
        let start = Instant::now();
        while state.load(Ordering::Acquire) == 0 {
            let _ = self.device.poll(wgpu::PollType::Wait {
                submission_index: None,
                timeout: Some(Duration::from_millis(10)),
            });
            if start.elapsed() > Duration::from_secs(30) {
                return Err("La GPU Quantus no respondió".into());
            }
        }
        if state.load(Ordering::Acquire) != 1 {
            return Err("No se pudieron leer los candidatos Quantus".into());
        }
        let bytes = slice.get_mapped_range().to_vec();
        self.staging.unmap();
        let found = u32::from_le_bytes(bytes[..4].try_into()?);
        if found > CAPACITY {
            if count == 1 {
                return Err("Registro Quantus desbordado".into());
            }
            let half = count / 2;
            let mut first = self.mine_slice(prestate, target, counter, half)?;
            let second = self.mine_slice(prestate, target, counter + half as u64, count - half)?;
            first.extend(second.into_iter().map(|index| index + half));
            if first.len() > 4096 {
                return Err("Demasiados candidatos Quantus por lote".into());
            }
            return Ok(first);
        }
        let mut indices = Vec::new();
        for i in 0..found as usize {
            let offset = (i + 1) * 4;
            let index = u32::from_le_bytes(bytes[offset..offset + 4].try_into()?);
            if index >= count {
                return Err("Índice Quantus fuera de rango".into());
            }
            indices.push(index);
        }
        Ok(indices)
    }

    pub fn mine(
        &self,
        prestate: &[u32; 24],
        target: &[u32; 8],
        counter: u64,
    ) -> Result<(Vec<u32>, f64), Box<dyn std::error::Error>> {
        let start = Instant::now();
        let indices = self.mine_slice(prestate, target, counter, BATCH)?;
        Ok((indices, start.elapsed().as_secs_f64() * 1000.0))
    }

    pub fn check_one(
        &self,
        prestate: &[u32; 24],
        target: &[u32; 8],
    ) -> Result<bool, Box<dyn std::error::Error>> {
        Ok(self.mine_slice(prestate, target, 0, 1)?.contains(&0))
    }

    pub const fn batch() -> u32 {
        BATCH
    }
}
