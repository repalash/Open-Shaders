# Cycles OSL shaders

Open Shading Language (OSL) node shaders from the **Cycles** production renderer,
as shipped inside Blender. These implement the shading nodes (Principled BSDF,
noise/voronoi/wave textures, math/color nodes, etc.).

- OSL shaders source: https://github.com/blender/blender/tree/master/intern/cycles/kernel/osl/shaders
- Updated: Jul 2026
- License: Apache-2.0 (see [LICENSE](LICENSE)) — Copyright Blender Foundation / Blender Authors

### Licensing note
Most files are Apache-2.0, but a few carry a `BSD-3-Clause` SPDX header inline
(Sony Pictures Imageworks / Blender): `stdosl.h`, `osl_shaders/stdcycles.h`, and
`osl_shaders/node_fresnel.h`. The authoritative per-file SPDX identifiers are
preserved in each file's header; only the Apache-2.0 text is bundled as
[LICENSE](LICENSE) — for the BSD-3-Clause terms see those files' headers.

### `stdosl.h`
The OSL standard library header, mirrored from the McNeel Cycles fork referenced
alongside Cycles (Rhino 7):
- https://github.com/mcneel/cycles/blob/master_rhino-7.0_20200203_tmp/src/kernel/shaders/stdosl.h
- License: BSD-3-Clause — Copyright (c) 2009-2010 Sony Pictures Imageworks Inc., et al.

Related reference (Principled BSDF in the McNeel fork):
https://github.com/mcneel/cycles/blob/ad3f1826cdeebc9a44c530ed450ed94f9148b5e6/src/kernel/shaders/node_principled_bsdf.osl

## Contents
- `osl_shaders/*.osl` — the shading node implementations (Apache-2.0)
- `osl_shaders/*.h` — shared OSL helpers (`node_noise.h`, `node_math.h`,
  `node_hash.h`, …; Apache-2.0), plus `stdcycles.h` and `node_fresnel.h`
  (BSD-3-Clause, per their headers)
- `stdosl.h` — OSL standard library definitions (BSD-3-Clause)
