//! Motor CUDA: ruta densa exacta (respaldo y autocomprobación) y motor disperso `sparse`.
use cudarc::driver::{
    sys, CudaContext, CudaFunction, CudaSlice, CudaStream, LaunchConfig, PushKernelArg,
};
use cudarc::nvrtc::Ptx;
use primitive_types::U512;
use std::sync::Arc;
use std::time::Instant;

#[path = "sparse.rs"]
pub mod sparse;

pub type Error = Box<dyn std::error::Error>;
pub fn valid_candidate(header: [u8; 32], nonce: [u8; 64], target: U512) -> bool {
    pow_core::get_nonce_hash(header, nonce) < target
}
pub const BATCH: u32 = 1_048_576;
/// Lote por lanzamiento del motor disperso: ~65 ms a 250 MH/s; amortiza la sincronización por lote.
pub const SPARSE_BATCH: u32 = 1 << 24;
const P: u64 = 0xffffffff00000001;
const GUARD: u64 = 0xa5a55a5ac33c3cc3;
const MAX_RETURNED: usize = 4096;

pub struct QuantusCuda {
    stream: Arc<CudaStream>,
    mine_fn: CudaFunction,
    hash_fn: CudaFunction,
    pre: CudaSlice<u64>,
    target: CudaSlice<u64>,
    results: CudaSlice<u32>,
    capacity: u32,
    name: String,
    variant: String,
    threads_per_block: u32,
    max_batch: u32,
    /// PTX genérico (cualquier NVIDIA desde Maxwell) en vez del ajustado para RTX 50.
    generic: bool,
}

#[derive(serde::Serialize)]
pub struct BatchResult {
    pub indices: Vec<u32>,
    pub unique_attempts: u64,
    pub physical_attempts: u64,
    pub launches: u32,
    pub kernel_ms: f64,
    pub api_ms: f64,
}

fn valid_range(counter: u64, count: u32, max: u32) -> Result<(), Error> {
    if count == 0 || count > max {
        return Err("Lote Quantus fuera de rango".into());
    }
    counter
        .checked_add(count as u64 - 1)
        .ok_or("Rango de nonces Quantus agotado")?;
    Ok(())
}

impl QuantusCuda {
    pub fn new(capacity: u32) -> Result<Self, Error> {
        let variant =
            std::env::var("TOKENMINER_QUANTUS_CUDA_VARIANT").unwrap_or_else(|_| "baseline".into());
        Self::new_variant(capacity, &variant)
    }
    pub fn new_variant(capacity: u32, variant: &str) -> Result<Self, Error> {
        Self::new_variant_en(0, capacity, variant)
    }
    /// Como `new_variant`, en la GPU `dispositivo` (orden de CUDA). Cada GPU lleva su propio motor.
    pub fn new_variant_en(dispositivo: usize, capacity: u32, variant: &str) -> Result<Self, Error> {
        if capacity == 0 || capacity > MAX_RETURNED as u32 {
            return Err("Capacidad Quantus incorrecta".into());
        }
        let context = CudaContext::new(dispositivo)
            .map_err(|e| format!("Quantus CUDA driver/context: {e}"))?;
        let major = context
            .attribute(sys::CUdevice_attribute::CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MAJOR)?;
        let minor = context
            .attribute(sys::CUdevice_attribute::CU_DEVICE_ATTRIBUTE_COMPUTE_CAPABILITY_MINOR)?;
        if (major, minor) < (5, 2) {
            return Err(
                "Quantus CUDA requiere una GPU NVIDIA GTX 900 (Maxwell) o posterior".into(),
            );
        }
        // RTX 50 (SM120): PTX ajustado. Resto (o TOKENMINER_CUDA_ARCH=generic, para validarlo en una RTX 50):
        // PTX genérico compute_52 compilado desde las mismas fuentes; el driver lo traduce a cada GPU al cargarlo.
        let generic =
            major < 12 || std::env::var("TOKENMINER_CUDA_ARCH").as_deref() == Ok("generic");
        let source = if generic {
            match variant {
                "baseline" => include_str!("../shaders/quantus-cuda-exact-compute_52.ptx"),
                "internal" => include_str!("../shaders/quantus-cuda-internal-compute_52.ptx"),
                _ => return Err("Variante CUDA Quantus sólo disponible en RTX 50 (SM120)".into()),
            }
        } else {
            match variant {
                "baseline" => include_str!("../shaders/quantus-cuda-exact-compute_120.ptx"),
                "internal" => include_str!("../shaders/quantus-cuda-internal-compute_120.ptx"),
                _ => return Err("Variante CUDA Quantus incorrecta".into()),
            }
        };
        // Esperar a la GPU durmiendo el hilo en vez de sondear: libera el núcleo que ocupaba la espera activa
        // (lotes de ~60 ms; la latencia de despertar es despreciable). Si el driver no lo admite, sigue por defecto.
        if std::env::var_os("TOKENMINER_CUDA_SPIN").is_none() {
            let _ = context.set_flags(sys::CUctx_flags::CU_CTX_SCHED_BLOCKING_SYNC);
        }
        let name = context.name()?;
        let module = context.load_module(Ptx::from_src(source)).map_err(|e| {
            format!(
                "Quantus CUDA PTX/JIT {}: {e}",
                if generic { "compute_52" } else { "compute_120" }
            )
        })?;
        let stream = context.new_stream()?;
        Ok(Self {
            mine_fn: module.load_function("quantus_mine")?,
            hash_fn: module.load_function("quantus_hashes")?,
            pre: stream.alloc_zeros(12)?,
            target: stream.alloc_zeros(4)?,
            results: stream.alloc_zeros(capacity as usize + 1)?,
            stream,
            name,
            capacity,
            variant: variant.into(),
            threads_per_block: 128,
            max_batch: BATCH,
            generic,
        })
    }

    pub fn name(&self) -> &str {
        &self.name
    }
    pub fn variant(&self) -> &str {
        &self.variant
    }
    #[cfg(test)]
    pub fn resources(&self) -> Result<serde_json::Value, Error> {
        Ok(
            serde_json::json!({"registersPerThread": self.mine_fn.get_attribute(sys::CUfunction_attribute::CU_FUNC_ATTRIBUTE_NUM_REGS)?,
            "localBytesPerThread": self.mine_fn.get_attribute(sys::CUfunction_attribute::CU_FUNC_ATTRIBUTE_LOCAL_SIZE_BYTES)?,
            "threadsPerBlock": self.threads_per_block, "ptx": if self.generic {"compute_52"} else {"compute_120"}, "variant":self.variant,"runtimeNvrtcRequired": false}),
        )
    }
    pub fn prepare(
        &mut self,
        header: [u8; 32],
        nonce: [u8; 64],
        target: U512,
    ) -> Result<(), Error> {
        self.set_prestate(&pow_core::mining_prestate_low64(header, nonce))?;
        self.set_target(target)
    }
    pub fn set_prestate(&mut self, pre: &[u64; 12]) -> Result<(), Error> {
        if pre.iter().any(|x| *x >= P) {
            return Err("Preestado Quantus no canónico".into());
        }
        self.stream.memcpy_htod(pre.as_slice(), &mut self.pre)?;
        Ok(())
    }
    pub fn set_target(&mut self, target: U512) -> Result<(), Error> {
        let bytes = target.to_big_endian();
        let words: [u64; 4] = std::array::from_fn(|i| {
            u64::from_be_bytes(bytes[i * 8..i * 8 + 8].try_into().unwrap())
        });
        self.stream
            .memcpy_htod(words.as_slice(), &mut self.target)?;
        Ok(())
    }
    fn configuration(&self, count: u32) -> LaunchConfig {
        LaunchConfig {
            grid_dim: (count.div_ceil(self.threads_per_block), 1, 1),
            block_dim: (self.threads_per_block, 1, 1),
            shared_mem_bytes: 0,
        }
    }
    fn mine_slice(
        &mut self,
        counter: u64,
        count: u32,
        result: &mut BatchResult,
    ) -> Result<(), Error> {
        valid_range(counter, count, self.max_batch)?;
        self.stream.memcpy_htod(
            vec![0u32; self.capacity as usize + 1].as_slice(),
            &mut self.results,
        )?;
        let start = self
            .stream
            .record_event(Some(sys::CUevent_flags::CU_EVENT_DEFAULT))?;
        let launch = self.configuration(count);
        unsafe {
            self.stream
                .launch_builder(&self.mine_fn)
                .arg(&self.pre)
                .arg(&self.target)
                .arg(&counter)
                .arg(&count)
                .arg(&self.capacity)
                .arg(&mut self.results)
                .launch(launch)?;
        }
        let end = self
            .stream
            .record_event(Some(sys::CUevent_flags::CU_EVENT_DEFAULT))?;
        let found = self.stream.clone_dtoh(&self.results)?;
        result.kernel_ms += start.elapsed_ms(&end)? as f64;
        result.physical_attempts += count as u64;
        result.launches += 1;
        if found[0] > self.capacity {
            if count as usize > MAX_RETURNED && result.indices.len() >= MAX_RETURNED {
                return Err("Demasiados candidatos Quantus; reducir lote/target".into());
            }
            if count == 1 {
                return Err("Overflow Quantus en un único nonce".into());
            }
            let half = count / 2;
            let before = result.indices.len();
            self.mine_slice(counter, half, result)?;
            let middle = result.indices.len();
            self.mine_slice(counter + half as u64, count - half, result)?;
            for index in &mut result.indices[middle..] {
                *index += half;
            }
            if result.indices.len() - before > MAX_RETURNED {
                return Err("Demasiados candidatos Quantus por lote".into());
            }
        } else {
            if result.indices.len() + found[0] as usize > MAX_RETURNED {
                return Err("Demasiados candidatos Quantus por lote".into());
            }
            for &i in &found[1..1 + found[0] as usize] {
                if i >= count {
                    return Err("Índice CUDA Quantus fuera de rango".into());
                }
                result.indices.push(i);
            }
        }
        Ok(())
    }
    pub fn mine(&mut self, counter: u64, count: u32) -> Result<BatchResult, Error> {
        valid_range(counter, count, self.max_batch)?;
        let started = Instant::now();
        let mut r = BatchResult {
            indices: Vec::new(),
            unique_attempts: count as u64,
            physical_attempts: 0,
            launches: 0,
            kernel_ms: 0.,
            api_ms: 0.,
        };
        self.mine_slice(counter, count, &mut r)?;
        r.indices.sort_unstable();
        if r.indices.windows(2).any(|w| w[0] == w[1]) {
            return Err("Candidato Quantus duplicado".into());
        }
        r.api_ms = started.elapsed().as_secs_f64() * 1000.;
        Ok(r)
    }
    pub fn hashes(&self, counter: u64, count: u32) -> Result<Vec<[u8; 64]>, Error> {
        valid_range(counter, count, BATCH)?;
        let mut output = self
            .stream
            .clone_htod(vec![GUARD; count as usize * 8 + 64].as_slice())?;
        unsafe {
            self.stream
                .launch_builder(&self.hash_fn)
                .arg(&self.pre)
                .arg(&counter)
                .arg(&count)
                .arg(&mut output)
                .launch(self.configuration(count))?;
        }
        let data = self.stream.clone_dtoh(&output)?;
        if data[..32]
            .iter()
            .chain(data[data.len() - 32..].iter())
            .any(|v| *v != GUARD)
        {
            return Err("Guarda CUDA Quantus modificada".into());
        }
        Ok((0..count as usize)
            .map(|i| {
                let mut bytes = [0u8; 64];
                for w in 0..8 {
                    bytes[w * 8..w * 8 + 8]
                        .copy_from_slice(&data[32 + w * count as usize + i].to_le_bytes());
                }
                bytes
            })
            .collect())
    }
    pub fn self_check(&mut self) -> Result<(), Error> {
        for kv in pow_core::NONCE_HASH_KVS {
            let header: [u8; 32] = hex::decode(kv.header)?
                .try_into()
                .map_err(|_| "Header vector")?;
            let nonce: [u8; 64] = hex::decode(kv.nonce)?
                .try_into()
                .map_err(|_| "Nonce vector")?;
            self.prepare(header, nonce, U512::zero())?;
            let counter = u64::from_be_bytes(nonce[56..].try_into()?);
            if hex::encode(self.hashes(counter, 1)?[0]) != kv.hash {
                return Err("Autocheck CUDA Quantus: hash distinto".into());
            }
        }
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn range_bounds_do_not_wrap_or_skip_last_nonce() {
        assert!(valid_range(u64::MAX, 1, BATCH).is_ok());
        assert!(valid_range(u64::MAX, 2, BATCH).is_err());
        assert!(valid_range(0, 0, BATCH).is_err());
        assert!(valid_range(0, BATCH + 1, BATCH).is_err());
        assert!(valid_range(0, SPARSE_BATCH, SPARSE_BATCH).is_ok());
        assert!(valid_range(0, SPARSE_BATCH + 1, SPARSE_BATCH).is_err());
    }
    #[test]
    #[ignore = "Requires NVIDIA SM120; run serially"]
    fn cuda_official_full512_vectors() {
        QuantusCuda::new(256).unwrap().self_check().unwrap();
    }
    #[test]
    #[ignore = "Requires NVIDIA SM120; GPU libre; tasa de la ruta densa anterior del helper"]
    fn dense_helper_rate() {
        let mut gpu = QuantusCuda::new(256).unwrap();
        gpu.prepare([0x3c; 32], [0x5a; 64], U512::one() << 300)
            .unwrap();
        let (mut counter, mut attempts) = (0u64, 0u64);
        let begin = Instant::now();
        while begin.elapsed().as_secs_f64() < 45.0 {
            let batch = gpu.mine(counter, BATCH).unwrap();
            if begin.elapsed().as_secs_f64() > 30.0 {
                attempts += batch.unique_attempts;
            }
            counter += BATCH as u64;
        }
        eprintln!(
            "dense helper: API {:.1} MH/s",
            attempts as f64 / (begin.elapsed().as_secs_f64() - 30.0) / 1e6
        );
    }
}
