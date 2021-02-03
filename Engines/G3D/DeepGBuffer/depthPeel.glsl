// -*- c++ -*-
#ifndef depthPeel_glsl
#define depthPeel_glsl
#include <reconstructFromDepth.glsl>

/** Returns true if the current Z value is less than minZGap in back of the old Z value */
bool isDepthPeeled(in sampler2D prevDepthBuffer, in vec2 currentToPrevScale, in float minZGap, in vec3 fragCoord, in vec3 clipInfo) {
    float oldDepth = texelFetch(prevDepthBuffer, ivec2(fragCoord.xy * currentToPrevScale), 0).r;
    float oldZ = reconstructCSZ(oldDepth, clipInfo);
    float currentZ = reconstructCSZ(fragCoord.z, clipInfo);
    return oldZ <= currentZ + minZGap;
}
#endif