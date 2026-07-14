# glslSmartDeNoise

Fast GLSL image denoise — a bilateral/gaussian smart-denoise filter by
Michele Morrone (BrutPitt). The `smartDeNoise()` function lives in `frag.glsl`.

- Source: https://github.com/BrutPitt/glslSmartDeNoise
- Updated: Jul 2026
- License: BSD-2-Clause (see [license.txt](license.txt)) — Copyright (c) 2019-2020 Michele Morrone

## Contents
- `frag.glsl` — the fragment shader containing `smartDeNoise()`
  (upstream path: `Shaders/frag.glsl`)
- `vert.glsl` — companion vertex shader (upstream path: `Shaders/vert.glsl`)
- `readme.upstream.md` — the original upstream project README (documents the
  `smartDeNoise()` parameters; note its references to `example/`, the `Shaders/`
  subfolder and screenshots point at the full upstream repo, not this flattened copy)
