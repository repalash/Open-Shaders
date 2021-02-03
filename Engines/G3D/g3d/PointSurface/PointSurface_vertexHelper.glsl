/**
  \file data-files/shader/PointSurface/PointSurface_vertexHelper.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/

void PointSurface_transformHelper(in Point3 position, in Radiance4 emission, in float pointRadius) {
    pointEmission = emission.rgb;

    // Visualize LOD:
    // pointEmission = pointEmission * 0.0001 + vec3((LOD + 0.01) * 0.1);

    // Visualize pointSize
    // pointEmission = pointEmission * 0.0001 + vec3(pointRadius);

    gl_Position = vec4(position, 1.0) * g3d_ObjectToScreenMatrixTranspose;  

    // Magic constant in here should be based on resolution
    //TODO: Abstract these constants.
    gl_PointSize = sqrt(1 << LOD) * pointRadius * 1100.0 / max((-(g3d_ObjectToCameraMatrix * vec4(position, 1.0)).z), 0.01);
}