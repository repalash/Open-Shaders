# etx-tracer

Shading kernels from **etx-tracer**, a physically based, spectral CPU/GPU
path tracer by Sergey (Serhii) Reznik.

- Source: https://github.com/sergeyreznik/etx-tracer
- Updated: Jul 2026
- License: MIT (see [LICENSE](LICENSE)) — Copyright (c) 2022 Serhii Rieznik

## Contents
- `render-shared/` — spectral BSDFs (conductor, dielectric, plastic, principled,
  velvet, …), materials, mediums, cameras, emitters, spectrum & vector math
  (`sources/etx/render/shared`)
- `rt-shared/` — path tracing / VCM shared kernel headers (`sources/etx/rt/shared`)
- `optix/` — OptiX/CUDA GPU kernels for path tracing (`pt`) and vertex connection
  and merging (`vcm`) (`bin/optix`)
