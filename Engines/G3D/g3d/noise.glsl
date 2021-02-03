/**
  \file data-files/shader/noise.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef G3D_noise_glsl
#define G3D_noise_glsl

#include <compatibility.glsl>

// All noise functions are designed for values on integer scale.
// They are tuned to avoid visible periodicity for both positive and
// negative coordinates within a few orders of magnitude.

float hash(float n) { return frac(sin(n) * 1e4); }
float hash(Point2 p) { return frac(1e4 * sin(17.0 * p.x + p.y * 0.1) * (0.1 + abs(sin(p.y * 13.0 + p.x)))); }

float noise1(float x) {
    float i = floor(x);
    float f = frac(x);
    float u = f * f * (3.0 - 2.0 * f);
    return lerp(hash(i), hash(i + 1.0), u);
}


#ifdef G3D_OSX
// macOS OpenGL drivers do not properly distinguish the
// overloads, so we give this a separate name on macOS
float noise1_Point2(Point2 x) {
#else
#define noise1_Point2 noise1
float noise1(Point2 x) {
#endif
    float2 i = floor(x);
    float2 f = frac(x);

    // Four corners in 2D of a tile
    float a = hash(i);
    float b = hash(i + vec2(1.0, 0.0));
    float c = hash(i + vec2(0.0, 1.0));
    float d = hash(i + vec2(1.0, 1.0));

    // Simple 2D lerp using smoothstep envelope between the values.
    // return vec3(lerp(lerp(a, b, smoothstep(0.0, 1.0, f.x)),
    //			lerp(c, d, smoothstep(0.0, 1.0, f.x)),
    //			smoothstep(0.0, 1.0, f.y)));
    
    // Same code, with the clamps in smoothstep and common subexpressions
    // optimized away.
    float2 u = f * f * (3.0 - 2.0 * f);
    return lerp(a, b, u.x) + (c - a) * u.y * (1.0 - u.x) + (d - b) * u.x * u.y;
}


// This one has non-ideal tiling properties that I'm still tuning
#ifdef G3D_OSX
// macOS OpenGL drivers do not properly distinguish the
// overloads, so we give this a separate name on macOS
float noise1_Point3(Point3 x) {
#else
#define noise1_Point3 noise1
float noise1(Point3 x) {
#endif
    const float3 step = float3(110, 241, 171);

    float3 i = floor(x);
    float3 f = frac(x);
 
    // For performance, compute the base input to a 1D hash from the integer part of the argument and the 
    // incremental change to the 1D based on the 3D -> 1D wrapping
    float n = dot(i, step);

    float3 u = f * f * (3.0 - 2.0 * f);
    return lerp(lerp(lerp( hash(n + dot(step, vec3(0, 0, 0))), hash(n + dot(step, vec3(1, 0, 0))), u.x),
                   lerp( hash(n + dot(step, vec3(0, 1, 0))), hash(n + dot(step, vec3(1, 1, 0))), u.x), u.y),
               lerp(lerp( hash(n + dot(step, vec3(0, 0, 1))), hash(n + dot(step, vec3(1, 0, 1))), u.x),
                   lerp( hash(n + dot(step, vec3(0, 1, 1))), hash(n + dot(step, vec3(1, 1, 1))), u.x), u.y), u.z);
}


float noise(float x, const int numOctaves) {
    float v = 0.0;
    float a = 0.5;
    float shift = 100;
    for (int i = 0; i < numOctaves; ++i) {
        v += a * noise1(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}


float noise(Point2 x, const int numOctaves) {
    float v = 0.0;
    float a = 0.5;
    float2 shift = float2(100, 50);
    // Rotate to reduce axial bias
    mat2 rot = mat2(cos(0.5), sin(0.5), -sin(0.5), cos(0.50));
    for (int i = 0; i < numOctaves; ++i) {
        v += a * noise1(x);
        x = rot * x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}


float noise(Point3 x, const int numOctaves) {
    float v = 0.0;
    float a = 0.5;
    float3 shift = float3(100, 75, 50);
    for (int i = 0; i < numOctaves; ++i) {
        v += a * noise1(x);
        x = x * 2.0 + shift;
        a *= 0.5;
    }
    return v;
}

#endif
