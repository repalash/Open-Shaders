/**
  \file data-files/shader/compatibility.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef compatability_glsl
#define compatability_glsl
/**
 Support for some GL 4.0 shader calls on older versions of OpenGL, and 
 support for some HLSL types and functions.
 */      
#if __VERSION__ < 400
#    define textureQueryLod textureQueryLOD
#endif

#if __VERSION__ < 410
#    extension GL_ARB_separate_shader_objects : enable
#endif

/*
#if __VERSION__ < 330
#error "GLSL versions older than 330 are no longer supported by G3D"
#endif
*/

#if __VERSION__ == 120
#   define texture      texture2D
#   define textureLod   texture2DLod
#   if G3D_SHADER_STAGE == G3D_FRAGMENT_SHADER
vec4 texture2DLod(sampler2D s , vec2 c, int L) { return texture2D(s, c); }
#   endif
#   define texelFetch   texelFetch2D
#   define textureSize  textureSize2D
#endif


#if __VERSION__ > 120
#   if G3D_SHADER_STAGE == G3D_VERTEX_SHADER
#       define varying out
#       define attribute in
#   elif G3D_SHADER_STAGE == G3D_FRAGMENT_SHADER
#       define varying in
#   endif
#endif

/////////////////////////////////////////////////////////////////////////////
// HLSL compatability

#define uint1 uint
#define uint2 uvec2
#define uint3 uvec3
#define uint4 uvec4

#define int1 int
#define int2 ivec2
#define int3 ivec3
#define int4 ivec4

#define float1 float
#define float2 vec2
#define float3 vec3
#define float4 vec4

#define bool1 bool
#define bool2 bvec2
#define bool3 bvec3
#define bool4 bvec4

#define half float
#define half1 float
#define half2 vec2
#define half3 vec3
#define half4 vec4

#define rsqrt inversesqrt

#define tex2D texture2D

#define lerp mix

#define ddx dFdx
#define ddy dFdy

float frac(float x) {
    return fract(x);
}

float2 frac(float2 x) {
    return fract(x);
}

float3 frac(float3 x) {
    return fract(x);
}

float4 frac(float4 x) {
    return fract(x);
}

float atan2(float y, float x) {
    return atan(y, x);
}

float saturate(float x) {
	return clamp(x, 0.0, 1.0);
}

float2 saturate(float2 x) {
	return clamp(x, float2(0.0), float2(1.0));
}

float3 saturate(float3 x) {
	return clamp(x, float3(0.0), float3(1.0));
}

float4 saturate(float4 x) {
	return clamp(x, float4(0.0), float4(1.0));
}

#endif
