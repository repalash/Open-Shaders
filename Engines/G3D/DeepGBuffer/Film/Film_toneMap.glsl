/** \file Film_toneMap.glsl -*- c++ -*-
*/
#include <compatibility.glsl>
#include <g3dmath.glsl>

/** Maps radiance to radiance */
float3 toneMap(float3 sourceRadiance, float sensitivity, sampler2D toneCurve) {
    sourceRadiance *= sensitivity;

    // Coarse approximation of sRGB transformation; we want the tone curve parameterized
    // in a nonlinear space for better control
    float3 sRGB = sqrt(sourceRadiance);
    float luma = maxComponent(sRGB);//dot(sRGB, float3(1.0 / 3.0));// float3(0.2126, 0.7152, 0.0722));

    // Slide down the tone curve so that it has better range
    luma *= 0.5;

    // Range compress luma
    return sourceRadiance * square(texture2DLod(toneCurve, float2(luma, 0.5), 0.0).r / max(luma, 0.001));
}