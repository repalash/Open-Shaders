#version 460
/**
  \file data-files/shader/default.vrt

  Default shader... mostly used for full-screen passes.

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
// Intentionally no #version... added by G3D

#include "DDGIVolume.glsl"

in vec4 g3d_Vertex;

uniform float		radius;
uniform DDGIVolume	ddgiVolume;
uniform vec3		cameraWSPosition;

out vec3			sampleDirection;
out float			edgeProximityScaleFactor;
out flat int3		probeGridCoord;

void main() {
    vec3 probeLoc = probeLocation(ddgiVolume, gl_InstanceID);
    gl_Position = vec4((normalize(g3d_Vertex.xyz) * radius) + probeLoc, 1.0)* g3d_ObjectToScreenMatrixTranspose;
    sampleDirection = normalize(g3d_Vertex.xyz);
	edgeProximityScaleFactor = abs(dot(sampleDirection, normalize(probeLoc - cameraWSPosition)));
    probeGridCoord = probeIndexToGridCoord(ddgiVolume, gl_InstanceID);
}
