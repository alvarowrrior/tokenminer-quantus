//! Motor de Quantus de TokenMiner: CUDA (denso exacto y disperso) y WGSL por wgpu.
#[cfg(windows)]
pub mod cuda;
pub mod web;

pub use engine_cpu;
pub use engine_gpu;
pub use pow_core;
