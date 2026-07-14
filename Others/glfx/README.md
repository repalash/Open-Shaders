# glfx.js filters

Image effect / filter shaders from **glfx.js**, a WebGL image processing library.
Each `.js` file wraps a GLSL fragment shader (see the `gl.createShader(...)` string
in every filter) together with the JS glue that drives it.

- Source: https://github.com/evanw/glfx.js/tree/master/src/filters
- Updated: Jul 2026
- License: MIT (see [LICENSE](LICENSE)) — Copyright (C) 2011 Evan Wallace

## Contents (`filters/`)
- `adjust/` — brightness/contrast, hue/saturation, vibrance, sepia, vignette, noise,
  denoise, curves, unsharp mask
- `blur/` — lens blur, triangle blur, tilt shift, zoom blur
- `fun/` — ink, dot screen, colour halftone, hexagonal pixelate, edge work
- `warp/` — bulge/pinch, swirl, perspective, matrix warp
- `common.js` — shared GLSL helper snippets used by the filters above
