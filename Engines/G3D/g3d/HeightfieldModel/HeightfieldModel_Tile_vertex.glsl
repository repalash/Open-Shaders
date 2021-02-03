/**
  \file data-files/shader/HeightfieldModel/HeightfieldModel_Tile_vertex.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef HeightfieldModel_Tile_vertex_glsl
#define HeightfieldModel_Tile_vertex_glsl
#include <UniversalSurface/UniversalSurface_vertex.glsl>


attribute vec2      position;

// Pixel offset in the elevation texture
uniform ivec2       tilePixelOffset;

// Scale along XZ in meters per mesh cell and scale along Y of meters per value.
uniform vec3        scale;

uniform float       texCoordsPerMeter;

// The heightfield
uniform sampler2D   elevation;

uniform float       pixelsPerQuadSide;

float getOSElevation(in vec2 pixelPosInTile) {
    return texelFetch(elevation, ivec2(pixelPosInTile * pixelsPerQuadSide) + tilePixelOffset, 0).r * scale.y;
}


void TerrainTile_computeOSInput(out vec4 osVertex, out vec3 osNormal, out vec2 texCoord0) {
    // Compute the position from the heightfield surface
    osVertex.x = position.x * scale.x;
    osVertex.y = getOSElevation(position);
    osVertex.z = position.y * scale.z;
    osVertex.w = 1.0;

    // Compute the world-space normal from the gradient of the surface
    osNormal =
        normalize(cross(vec3(0, getOSElevation(position + vec2(0, 1)) - getOSElevation(position - vec2(0, 1)), scale.z * 2),
                        vec3(scale.x * 2, getOSElevation(position + vec2(1, 0)) - getOSElevation(position - vec2(1, 0)), 0)));

    texCoord0 = osVertex.xz * texCoordsPerMeter;
}


#endif
