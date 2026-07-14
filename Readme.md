# Open shader repository
Collection of many open source shaders(GLSL, HLSL, CG) in popular open source game development and rendering engines and public repositories. 
Aim is to have a common index of shader snippets and algorithms for educational reference while developing games and applications.

### Engines
* [Unity3D](Engines/Unity)
  - Built-in shaders - version: 2020.2.2f1 - https://unity3d.com/get-unity/download/archive
  - Graphics Pipelines - Updated: Jan 2021 - https://github.com/Unity-Technologies/Graphics
* [Unreal Engine](Engines/Unreal)
    - Updated: Jan 2021
    - https://github.com/EpicGames/UnrealEngine/tree/release/Engine/Shaders
* [Godot](Engines/godot)
    - Updated: Jan 2021
    - https://github.com/godotengine/godot/tree/master/servers/rendering/renderer_rd/shaders
* [G3D](Engines/G3D)
  - g3d, updated: 2015
  - Deep G-buffer, updated: 2014
  - https://sourceforge.net/p/g3d/code/HEAD/tree/
* [three.js](Engines/threejs)
  - Updated: Jan 2021
  - https://github.com/mrdoob/three.js
* [Babylon.js](Engines/babylonjs)
  - Updated: Feb 2021
  - https://github.com/BabylonJS/Babylon.js/tree/master/src/Shaders
* [filament](Engines/babylonjs) by google
  - Updated: Feb 2021
  - https://github.com/google/filament/tree/main/shaders/src
* [playcanvas](Engines/playcanvas)
  - Updated: May 2021
  - https://github.com/playcanvas/engine/tree/v1.41.2/src/graphics/program-lib/chunks
* [Blend4Web](Engines/Blend4Web) 
  - Updated: Feb 2021
  - https://github.com/TriumphLLC/Blend4Web/tree/master/shaders
* [Cycles](Engines/cycles)
  - OSL node shaders (Principled BSDF, textures, math/color nodes) from Blender's Cycles renderer
  - Updated: Jul 2026
  - https://github.com/blender/blender/tree/master/intern/cycles/kernel/osl/shaders
  - Includes `stdosl.h` from the McNeel Cycles (Rhino 7) fork: https://github.com/mcneel/cycles
* [EEVEE](Engines/eevee)
  - Real-time PBR shaders from Blender's EEVEE draw engine
  - Updated: Jul 2026
  - https://github.com/blender/blender/tree/master/source/blender/draw/engines/eevee/shaders

### Others:
* [inviwo](Others/inviwo): 
  - Volume rendering framework
  - Updated: Aug 2020
  - https://github.com/inviwo/inviwo/tree/master/modules
* [ray tracing renderer](Others/ray_tracing_renderer_three): 
  - Full ray tracing over three.js
  - Updated: Jan 2021
  - https://github.com/hoverinc/ray-tracing-renderer/tree/master/src/renderer/glsl
* [StochasticScreenSpaceReflection](Others/StochasticScreenSpaceReflection):
  - for unity
  - https://github.com/Xerxes1138/StochasticScreenSpaceReflection/tree/master/Assets/PostProcessing/Resources/Shaders
* [wisdom shaders](Others/wisdom):
  - Minecraft shaders
  - https://bc3.moe/wisdom-shaders/
  - https://github.com/bobcao3/Wisdom-Shaders/tree/master/shaders
* [ssdo_webgl](Others/ssdo_webgl): https://github.com/quentinplessis/ssdo_webgl
* [GDQuest godot shaders](Others/GDQuest_godot): (Feb 2021) https://github.com/GDQuest/godot-shaders/tree/master/godot/Shaders
* [glfx.js](Others/glfx):
  - WebGL image filters (blur, warp, adjust, fun) with embedded GLSL
  - Updated: Jul 2026
  - https://github.com/evanw/glfx.js/tree/master/src/filters
* [glslSmartDeNoise](Others/glslSmartDeNoise):
  - Fast GLSL bilateral/gaussian image denoise
  - Updated: Jul 2026
  - https://github.com/BrutPitt/glslSmartDeNoise
* [etx-tracer](Others/etx-tracer):
  - Spectral CPU/GPU path tracer — BSDFs, spectrum/material code and OptiX kernels
  - Updated: Jul 2026
  - https://github.com/sergeyreznik/etx-tracer
* [Wagner](Others/Wagner):
  - Post-processing effect shaders for three.js
  - Updated: Jul 2026
  - https://github.com/spite/Wagner/tree/master/fragment-shaders
* [postprocessing](Others/postprocessing):
  - Effect and blend-mode shaders for three.js
  - Updated: Jul 2026
  - https://github.com/vanruesc/postprocessing/tree/master/src/effects/glsl
* [processing-postfx](Others/processing-postfx):
  - PostFX post-effect shaders for Processing (no upstream license declared)
  - Updated: Jul 2026
  - https://github.com/cansik/processing-postfx/tree/master/shader

### Ad hoc scripts
Sources at the top of the files.
* [Noise functions](Adhoc/noise_functions.md): Inigo Quilez gradient/value noise and derivatives
  - https://www.shadertoy.com/view/4tGGWW (latest)
  - https://www.shadertoy.com/view/MtV3W1 (main)

### Awesome blogs and resources
* Inigo Quilez articles: https://iquilezles.org/www/index.htm#
* Demofox blog: https://blog.demofox.org/ for Programming, Graphics, Gamedev, Exotic Computation, Audio Synthesis
  Menu
* Catlike Coding: https://catlikecoding.com/unity/tutorials/ for Unity Rendering tutorials.
* Alan Zucconi tutorials: https://www.alanzucconi.com/
* Manohar Vanga blog: https://sighack.com/ 
* 3D Game Shaders For Beginners: https://lettier.github.io/3d-game-shaders-for-beginners/index.html
* The book of shaders: https://thebookofshaders.com/  

### Other Shader collections and related
* Unity3D-CG-programming: https://github.com/przemyslawzaworski/Unity3D-CG-programming
* Package of pixel shaders intended for old school emulators: https://github.com/libretro/common-shaders
* awesome-creative-coding: https://github.com/terkelg/awesome-creative-coding
* Unity Shaders book: https://github.com/candycat1992/Unity_Shaders_Book/tree/master/Assets/Shaders
* Blender materials: https://github.com/sambler/osl-shaders
* Unity shaders: https://github.com/QianMo/Awesome-Unity-Shader
* Curated list of computer graphics tutorials and resources: https://github.com/ericjang/awesome-graphics
* https://shadertoy.com

### Notes: 
* Open in Jetbrains Rider with Unity support for (some) hlsl syntax highlighting and navigation.
* See the specific license in each directory before copying code.
* All copyright and credits belong to the respective authors. 
