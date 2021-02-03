/**
  \file data-files/shader/PointSurface/PointSurface_vertex.glsl

  Abstracts common code in PointSurface_render.vrt and PointSurface_gbuffer.vrt

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/

/** LOD is exponential in this value (like MIP maps) */
#expect LOD "int"

in Point3       position;

// in sRGB values
in Radiance4    emission;

// in meters
uniform float   pointRadius;

out Radiance3   pointEmission;

#include "PointSurface_vertexHelper.glsl"

void PointSurface_transform(){
    PointSurface_transformHelper(position, emission, pointRadius);
}