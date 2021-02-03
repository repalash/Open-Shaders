/**
  \file data-files/shader/textureFilter.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef textureFilter_glsl
#define textureFilter_glsl

#include <compatibility.glsl>
#include <g3dmath.glsl>

// w0, w1, w2, and w3 are the four cubic B-spline basis functions
float bicubic_w0(float a) { return (1.0/6.0)*(a*(a*(-a + 3.0) - 3.0) + 1.0); }

float bicubic_w1(float a) { return (1.0/6.0)*(a*a*(3.0*a - 6.0) + 4.0); }

float bicubic_w2(float a) { return (1.0/6.0)*(a*(a*(-3.0*a + 3.0) + 3.0) + 1.0); }

float bicubic_w3(float a) { return (1.0/6.0)*(a*a*a); }

// g0 and g1 are the two amplitude functions
float bicubic_g0(float a) { return bicubic_w0(a) + bicubic_w1(a); }

float bicubic_g1(float a) { return bicubic_w2(a) + bicubic_w3(a); }

// h0 and h1 are the two offset functions
float bicubic_h0(float a) { return -1.0 + bicubic_w1(a) / (bicubic_w0(a) + bicubic_w1(a)); }

float bicubic_h1(float a) { return 1.0 + bicubic_w3(a) / (bicubic_w2(a) + bicubic_w3(a)); }

/** 4x4 bicubic filter using 4 bilinear texture lookups 
    See GPU Gems 2: "Fast Third-Order Texture Filtering", Sigg & Hadwiger:
    http://http.developer.nvidia.com/GPUGems2/gpugems2_chapter20.html
    as implemented by http://vec3.ca/bicubic-filtering-in-fewer-taps/
    and https://www.shadertoy.com/view/4df3Dn

    \param P in texels */
vec4 textureRectLod_bicubic(sampler2D tex, vec2 P, float lod, vec2 invSize) {
	vec2 iP = floor(P);
	vec2 fP = fract(P);

    float g0x = bicubic_g0(fP.x);
    float g1x = bicubic_g1(fP.x);
    float h0x = bicubic_h0(fP.x);
    float h1x = bicubic_h1(fP.x);
    float h0y = bicubic_h0(fP.y);
    float h1y = bicubic_h1(fP.y);

	vec2 p0 = (vec2(iP.x + h0x, iP.y + h0y) - 0.5) * invSize;
	vec2 p1 = (vec2(iP.x + h1x, iP.y + h0y) - 0.5) * invSize;
	vec2 p2 = (vec2(iP.x + h0x, iP.y + h1y) - 0.5) * invSize;
	vec2 p3 = (vec2(iP.x + h1x, iP.y + h1y) - 0.5) * invSize;
	
    return bicubic_g0(fP.y) * (g0x * textureLod(tex, p0, lod)  +
                               g1x * textureLod(tex, p1, lod)) +
           bicubic_g1(fP.y) * (g0x * textureLod(tex, p2, lod)  +
                               g1x * textureLod(tex, p3, lod));
}


/** \param P in texture coordinates */
vec4 texture2DLod_bicubic(sampler2D tex, vec2 P, float lod, vec2 size, vec2 invSize) {
    return textureRectLod_bicubic(tex, P * size + 0.5, lod, invSize);
}


/** 
 Inigo Quilez's smooth bilinear with a smoother blend but worse derivative properties at the ends
 http://www.iquilezles.org/www/articles/texture/texture.htm
*/
vec4 textureRectLod_smoothstep(sampler2D tex, vec2 P, float lod, vec2 invSize) {
    P = floor(P) + unitSmoothstep(fract(P));
	P = (P - 0.5) * invSize;
	return textureLod(tex, P, lod);
}


/** 
 Inigo Quilez's smooth bilinear with a smoother blend but worse derivative properties at the ends
 http://www.iquilezles.org/www/articles/texture/texture.htm
*/
vec4 texture2DLod_smoothstep(sampler2D tex, vec2 P, float lod, vec2 size, vec2 invSize) {
    return textureRectLod_smoothstep(tex, P * size + 0.5, lod, invSize);
}


/** 
 Inigo Quilez's smooth bilinear
 http://www.iquilezles.org/www/articles/texture/texture.htm
*/
vec4 textureRectLod_smootherstep(sampler2D tex, vec2 P, float lod, vec2 invSize) {
    P = floor(P) + unitSmootherstep(fract(P));
	P = (P - 0.5) * invSize;
	return textureLod(tex, P, lod);
}


/** 
 Inigo Quilez's smooth bilinear
 http://www.iquilezles.org/www/articles/texture/texture.htm
*/
vec4 texture2DLod_smootherstep(sampler2D tex, vec2 P, float lod, vec2 size, vec2 invSize) {
	return textureRectLod_smootherstep(tex,  P * size + 0.5, lod, invSize);
}

#endif
