//! Motor disperso: nonce estructurado con caché por trabajo, reducciones v6 y filtro de 64 bits.
use super::*;
pub const LOCAL_MAX: u64 = 0x40000000 / 17;
const BASE: u64 = 0x40000000;

pub fn nonce(upper: [u8; 32], group: u64, local: u64) -> Result<[u8; 64], Error> {
    if local > LOCAL_MAX {
        return Err("Local disperso agotado".into());
    }
    let g0 = group & 0x3fffff;
    let g1 = (group >> 22) & 0x3fffff;
    let g2 = group >> 44;
    let words = [
        BASE + 17 * local,
        BASE + g0 - 11 * local,
        BASE + g1 + 3 * local,
        BASE + g2 - 4 * local,
        BASE - 17 * local,
        BASE + 11 * local,
        BASE - 3 * local,
        BASE + 4 * local,
    ];
    let mut output = [0u8; 64];
    output[..32].copy_from_slice(&upper);
    for (i, w) in words.iter().enumerate() {
        output[32 + i * 4..36 + i * 4].copy_from_slice(&u32::try_from(*w)?.to_le_bytes());
    }
    Ok(output)
}
#[cfg(test)]
pub fn inverse(value: [u8; 64]) -> Result<(u64, u64), Error> {
    let words: [u64; 8] = std::array::from_fn(|i| {
        u32::from_le_bytes(value[32 + i * 4..36 + i * 4].try_into().unwrap()) as u64
    });
    let delta = words[0]
        .checked_sub(BASE)
        .ok_or("Nonce disperso incorrecto")?;
    if delta % 17 != 0 {
        return Err("Nonce disperso fuera de dirección".into());
    }
    let local = delta / 17;
    if local > LOCAL_MAX {
        return Err("Local disperso incorrecto".into());
    }
    let g0 = words[1]
        .checked_add(11 * local)
        .and_then(|x| x.checked_sub(BASE))
        .ok_or("Grupo 0")?;
    let g1 = words[2].checked_sub(BASE + 3 * local).ok_or("Grupo 1")?;
    let g2 = words[3]
        .checked_add(4 * local)
        .and_then(|x| x.checked_sub(BASE))
        .ok_or("Grupo 2")?;
    if g0 > 0x3fffff || g1 > 0x3fffff || g2 > 0xfffff {
        return Err("Grupo disperso fuera de rango".into());
    }
    let group = g0 | (g1 << 22) | (g2 << 44);
    if nonce(value[..32].try_into()?, group, local)? != value {
        return Err("Nonce disperso no reconstruible".into());
    }
    Ok((group, local))
}
#[cfg(test)]
pub fn count_at(local: u64) -> Result<u32, Error> {
    count_at_max(local, BATCH)
}
fn count_at_max(local: u64, max: u32) -> Result<u32, Error> {
    if local > LOCAL_MAX {
        return Err("Local disperso agotado".into());
    }
    Ok((LOCAL_MAX - local + 1).min(max as u64) as u32)
}
fn range(local: u64, count: u32, max: u32) -> Result<(), Error> {
    valid_range(local, count, max)?;
    if local + count as u64 - 1 > LOCAL_MAX {
        return Err("Dividir lote antes del límite disperso".into());
    }
    Ok(())
}
fn linear(state: [u64; 12]) -> [u64; 12] {
    let mut block = [0u128; 12];
    for j in (0..12).step_by(4) {
        let total: u128 = state[j..j + 4].iter().map(|x| *x as u128).sum();
        for i in 0..4 {
            block[j + i] = total + state[j + i] as u128 + 2 * state[j + (i + 1) % 4] as u128;
        }
    }
    std::array::from_fn(|i| {
        ((block[i] + block[i % 4] + block[i % 4 + 4] + block[i % 4 + 8]) % P as u128) as u64
    })
}
fn power7(x: u64) -> u64 {
    let p = P as u128;
    let x = x as u128;
    let x2 = x * x % p;
    let x4 = x2 * x2 % p;
    ((x4 * x2 % p) * x % p) as u64
}
/// Hilos por bloque para un kernel que admite `max` en esta GPU: warps enteros, hasta 1.024. Los registros de un
/// multiprocesador se reparten entre los hilos que tiene dentro, así que el bloque más grande que cabe es el que lo
/// llena. Antes sólo se elegía entre 1.024 y 512: con 72 registros por hilo caben 910, y con 512 se quedaba un solo
/// bloque por multiprocesador, medio vacío (en una RTX 5070 portátil, 17 warps rinden un 12 % menos que 32); y con más
/// de 128 registros no caben ni 512, y el kernel no arrancaba.
fn hilos_por_bloque(max: i32) -> u32 {
    (max.clamp(32, 1024) as u32) / 32 * 32
}
pub struct SparseCuda {
    base: QuantusCuda,
    // El kernel lee la caché de 14 palabras de la constante de módulo Q61_PRE, no del puntero `pre`.
    constant_module: Arc<cudarc::driver::CudaModule>,
    upper: [u8; 32],
    group: u64,
    header: [u8; 32],
    target: U512,
    prepared: bool,
    base_pre: [u64; 12],
}
impl SparseCuda {
    pub fn new(capacity: u32, kind: &str) -> Result<Self, Error> {
        Self::new_en(0, capacity, kind)
    }
    /// Como `new`, en la GPU `dispositivo` (orden de CUDA).
    pub fn new_en(dispositivo: usize, capacity: u32, kind: &str) -> Result<Self, Error> {
        if kind != "q106" {
            return Err("Variante dispersa incorrecta".into());
        }
        let mut base = QuantusCuda::new_variant_en(dispositivo, capacity, "internal")?;
        // RTX 50 (SM120): PTX ajustado. Resto: PTX genérico compute_52 desde las mismas fuentes.
        let source = if base.generic {
            include_str!("../shaders/quantus-cuda-q106-red6-compute_52.ptx")
        } else {
            include_str!("../shaders/quantus-cuda-q106-red6-compute_120.ptx")
        };
        let module = base.stream.context().load_module(Ptx::from_src(source))?;
        base.mine_fn = module.load_function("quantus_sparse_mine")?;
        base.hash_fn = module.load_function("quantus_sparse_hashes")?;
        if module.get_global("Q61_PRE", &base.stream)?.len() != 14 * 8 {
            return Err("Q61_PRE con tamaño inesperado".into());
        }
        // El bloque más grande que admiten en esta GPU todos los kernels que se lanzan con este tamaño (minado, hashes
        // del autocheck y primera ronda). El driver lo fija según los registros que da a cada hilo, y eso cambia de
        // una GPU a otra.
        let max_of = |f: &CudaFunction| {
            f.get_attribute(sys::CUfunction_attribute::CU_FUNC_ATTRIBUTE_MAX_THREADS_PER_BLOCK)
        };
        let max_threads = max_of(&base.mine_fn)?
            .min(max_of(&base.hash_fn)?)
            .min(max_of(&module.load_function("quantus_sparse_first")?)?);
        base.threads_per_block = hilos_por_bloque(max_threads);
        base.max_batch = SPARSE_BATCH;
        base.variant = format!("sparse-{kind}");
        base.pre = base.stream.alloc_zeros(24)?;
        Ok(Self {
            constant_module: module,
            base,
            upper: [0; 32],
            group: 0,
            header: [0; 32],
            target: U512::zero(),
            prepared: false,
            base_pre: [0; 12],
        })
    }
    #[cfg(test)]
    pub fn resources(&self) -> Result<serde_json::Value, Error> {
        self.base.resources()
    }
    pub fn variant(&self) -> &str {
        self.base.variant()
    }
    pub fn group(&self) -> u64 {
        self.group
    }
    pub fn prepare(
        &mut self,
        header: [u8; 32],
        upper: [u8; 32],
        group: u64,
        target: U512,
    ) -> Result<(), Error> {
        let mut empty = [0u8; 64];
        empty[..32].copy_from_slice(&upper);
        self.base_pre = pow_core::mining_prestate_low64(header, empty);
        self.header = header;
        self.upper = upper;
        self.group = group;
        self.target = target;
        self.upload_cache()?;
        self.base.set_target(target)?;
        self.prepared = true;
        Ok(())
    }
    fn upload_cache(&mut self) -> Result<(), Error> {
        let value = nonce(self.upper, self.group, 0)?;
        let words: [u64; 12] = std::array::from_fn(|i| {
            if i < 8 {
                u32::from_le_bytes(value[32 + 4 * i..36 + 4 * i].try_into().unwrap()) as u64
            } else {
                0
            }
        });
        let contribution = linear(words);
        let pre: [u64; 12] = std::array::from_fn(|i| {
            ((self.base_pre[i] as u128 + contribution[i] as u128) % P as u128) as u64
        });
        let mut cache = [0u64; 24];
        let fixed = std::array::from_fn(|i| if i == 3 || i == 7 { 0 } else { power7(pre[i]) });
        cache[..12].copy_from_slice(&linear(fixed));
        cache[12] = pre[3];
        cache[13] = pre[7];
        self.base
            .stream
            .memcpy_htod(cache.as_slice(), &mut self.base.pre)?;
        // Mismo flujo que el lanzamiento: la copia queda ordenada antes del siguiente kernel.
        let mut symbol = self
            .constant_module
            .get_global("Q61_PRE", &self.base.stream)?;
        let mut words =
            unsafe { symbol.transmute_mut::<u64>(14) }.ok_or("Q61_PRE no admite 14 palabras")?;
        self.base.stream.memcpy_htod(&cache[..14], &mut words)?;
        Ok(())
    }
    pub fn next_group(&mut self) -> Result<(), Error> {
        if !self.prepared {
            return Err("Receta dispersa sin preparar".into());
        }
        self.group = self
            .group
            .checked_add(1)
            .ok_or("Grupos dispersos agotados")?;
        self.upload_cache()
    }
    pub fn nonce(&self, local: u64) -> Result<[u8; 64], Error> {
        nonce(self.upper, self.group, local)
    }
    /// Tamaño del siguiente lote desde `local`, sin cruzar LOCAL_MAX ni el máximo del motor.
    pub fn batch_at(&self, local: u64) -> Result<u32, Error> {
        count_at_max(local, self.base.max_batch)
    }
    pub fn mine(&mut self, local: u64, count: u32) -> Result<BatchResult, Error> {
        if !self.prepared {
            return Err("Receta dispersa sin preparar".into());
        }
        range(local, count, self.base.max_batch)?;
        self.base.mine(local, count)
    }
    pub fn hashes(&self, local: u64, count: u32) -> Result<Vec<[u8; 64]>, Error> {
        if !self.prepared {
            return Err("Receta dispersa sin preparar".into());
        }
        range(local, count, BATCH)?;
        self.base.hashes(local, count)
    }
    pub fn self_check(&mut self) -> Result<(), Error> {
        for (group, local) in [(0, 0), (u64::MAX, LOCAL_MAX), (1 << 44, 1)] {
            self.prepare([7; 32], [0xa5; 32], group, U512::zero())?;
            if U512::from_big_endian(&self.hashes(local, 1)?[0])
                != pow_core::get_nonce_hash([7; 32], self.nonce(local)?)
            {
                return Err("Autocheck nonce disperso full512".into());
            }
        }
        Ok(())
    }
}
#[cfg(test)]
mod tests {
    use super::*;
    #[test]
    fn sparse_inverse_edges_and_tail() {
        for group in [
            0,
            1,
            (1 << 22) - 1,
            1 << 22,
            (1 << 44) - 1,
            1 << 44,
            u64::MAX,
        ] {
            for local in [0, 1, LOCAL_MAX - 1, LOCAL_MAX] {
                let n = nonce([0xa5; 32], group, local).unwrap();
                assert_eq!(inverse(n).unwrap(), (group, local));
                assert_eq!(&n[..32], &[0xa5; 32]);
            }
        }
        assert!(nonce([0; 32], 0, LOCAL_MAX + 1).is_err());
        assert!(range(LOCAL_MAX, 1, BATCH).is_ok());
        assert!(range(LOCAL_MAX, 2, BATCH).is_err());
        assert_eq!(count_at(LOCAL_MAX).unwrap(), 1);
        let mut bad = nonce([0; 32], 0, 0).unwrap();
        bad[63] ^= 1;
        assert!(inverse(bad).is_err());
    }
    #[test]
    fn el_bloque_llena_el_multiprocesador_en_cualquier_gpu() {
        // 64 registros o menos por hilo: caben 1.024, como en la RTX 50.
        assert_eq!(hilos_por_bloque(1024), 1024);
        assert_eq!(hilos_por_bloque(2048), 1024);
        // 72 registros: caben 910, que son 28 warps enteros. Antes, 512.
        assert_eq!(hilos_por_bloque(910), 896);
        // Más de 128 registros: no caben 512, que antes se lanzaban igual y fallaban.
        assert_eq!(hilos_por_bloque(508), 480);
        assert_eq!(hilos_por_bloque(512), 512);
        assert_eq!(hilos_por_bloque(40), 32);
        assert_eq!(hilos_por_bloque(1), 32);
    }
    // Ningún nonce válido se pierde y todo candidato cumple el filtro de 64 bits, con el bloque de esta GPU y con
    // bloques más pequeños, como los que tocan en una GPU cuyo driver da más registros a cada hilo.
    #[test]
    #[ignore = "Requires an NVIDIA GPU; run serially"]
    fn exacto_con_bloques_que_no_son_potencia_de_dos() {
        let mut gpu = SparseCuda::new(256, "q106").unwrap();
        let propio = gpu.base.threads_per_block;
        for hilos in [896u32, 544, 480, 32] {
            if hilos > propio {
                continue;
            }
            gpu.base.threads_per_block = hilos;
            gpu.self_check().unwrap();
            let (header, upper, target) = ([0x3c; 32], [0x5a; 32], U512::MAX >> 6);
            gpu.prepare(header, upper, 12345, target).unwrap();
            // Un lote que no es múltiplo del bloque: el último queda a medias.
            let count = 65_537u32;
            let found = gpu.mine(7, count).unwrap().indices;
            let mut valid = 0;
            for i in 0..count {
                let hash = pow_core::get_nonce_hash(header, gpu.nonce(7 + i as u64).unwrap());
                let returned = found.binary_search(&i).is_ok();
                if hash < target {
                    assert!(returned, "nonce válido perdido con bloques de {hilos}: local {}", 7 + i as u64);
                    valid += 1;
                }
                if returned {
                    assert!(hash >> 448 <= target >> 448, "candidato fuera del filtro con bloques de {hilos}");
                }
            }
            assert!(valid > 0 && found.len() >= valid);
            eprintln!("bloques de {hilos}: {} candidatos, {valid} válidos full512", found.len());
        }
    }
    // Ningún nonce válido se pierde y todo candidato cumple el filtro de 64 bits.
    // Target ~1/64 por los 64 bits altos: ~1.000 candidatos por 65.536 nonces (fuerza el desbordamiento de cola 256).
    #[test]
    #[ignore = "Requires an NVIDIA GPU; run serially"]
    fn candidates_match_cpu_full512() {
        for kind in ["q106"] {
            let mut gpu = SparseCuda::new(256, kind).unwrap();
            gpu.self_check().unwrap();
            for (header, upper, group, local, shift) in [
                ([0x3c; 32], [0x5a; 32], 12345u64, 0u64, 6u32),
                ([0x00; 32], [0xff; 32], u64::MAX, LOCAL_MAX - 65535, 6),
                ([0x91; 32], [0x07; 32], 1 << 44, 777, 10),
            ] {
                let target = U512::MAX >> shift;
                gpu.prepare(header, upper, group, target).unwrap();
                let count = 65536u32;
                let found = gpu.mine(local, count).unwrap().indices;
                let mut valid = 0;
                for i in 0..count {
                    let hash =
                        pow_core::get_nonce_hash(header, gpu.nonce(local + i as u64).unwrap());
                    let returned = found.binary_search(&i).is_ok();
                    if hash < target {
                        assert!(
                            returned,
                            "nonce válido perdido: grupo {group} local {}",
                            local + i as u64
                        );
                        valid += 1;
                    }
                    if returned {
                        assert!(
                            hash >> 448 <= target >> 448,
                            "candidato fuera del filtro de 64 bits"
                        );
                    }
                }
                assert!(valid > 0 && found.len() >= valid);
                eprintln!(
                    "{kind} grupo {group}: {} candidatos, {valid} válidos full512",
                    found.len()
                );
            }
            gpu.prepare([1; 32], [2; 32], 0, U512::zero()).unwrap();
            assert!(gpu.mine(0, 65536).unwrap().indices.is_empty());
        }
    }
    #[test]
    #[ignore = "Requires an NVIDIA GPU; GPU libre; mide la tasa del motor del helper"]
    fn helper_rate() {
        for kind in ["q106"] {
            let mut gpu = SparseCuda::new(256, kind).unwrap();
            eprintln!("{kind} recursos {}", gpu.resources().unwrap());
            gpu.prepare([0x3c; 32], [0x5a; 32], 1, U512::one() << 300)
                .unwrap();
            let (mut local, mut attempts, mut kernel) = (0u64, 0u64, 0f64);
            let begin = std::time::Instant::now();
            while begin.elapsed().as_secs_f64() < 45.0 {
                if local > LOCAL_MAX {
                    gpu.next_group().unwrap();
                    local = 0;
                }
                let count = gpu.batch_at(local).unwrap();
                let batch = gpu.mine(local, count).unwrap();
                if begin.elapsed().as_secs_f64() > 30.0 {
                    attempts += batch.unique_attempts;
                    kernel += batch.kernel_ms;
                }
                local += count as u64;
            }
            let wall = begin.elapsed().as_secs_f64() - 30.0; // 30 s iniciales: rampa de potencia del portátil
            eprintln!(
                "{kind} helper: API {:.1} MH/s, kernel {:.1} MH/s",
                attempts as f64 / wall / 1e6,
                attempts as f64 / (kernel / 1e3) / 1e6
            );
        }
    }
}
