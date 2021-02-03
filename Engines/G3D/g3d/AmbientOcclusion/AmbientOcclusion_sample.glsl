/**
  \file data-files/shader/AmbientOcclusion/AmbientOcclusion_sample.glsl

  \cite Implements the inferred AO sampling algorithm from McGuire and Mara,
  \cite Phenomenological Transparency, IEEE Transactions on Visualiation and Computer Graphics, 14 pages, 2017

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef AmbientOcclusion_sample_glsl
#define AmbientOcclusion_sample_glsl

#include <g3dmath.glsl>
#include <reconstructFromDepth.glsl>

/** Used for inferred AO. Returns weighted AO, weight based on depth locality */
float2 sampleNeighborAO(ivec2 coord, sampler2D ambientOcclusion_buffer, ivec2 ambientOcclusion_offset, ivec2 ambientOcclusion_size, sampler2D depthBuffer, float myZ, float3 clipInfo) {
    // Read the depth at the offset coordinate
    float neighborDepth = texelFetch(depthBuffer, coord, 0).r;
    float neighborZ = reconstructCSZ(neighborDepth, clipInfo);

    // Read the AO at the offset coordinate
    float AO = texelFetch(ambientOcclusion_buffer, clamp(coord + ambientOcclusion_offset, ivec2(0), ivec2(ambientOcclusion_size.xy - vec2(1, 1))), 0).r;

    float weight = 0.01 / (0.01 + abs(neighborZ - myZ));

    return float2(AO * weight, weight);
}

float sampleAO(
    vec2                coord,
    sampler2D           ambientOcclusion_buffer,
    ivec2               ambientOcclusion_offset, 
    ivec2               ambientOcclusion_size, 
    sampler2D           depthBuffer,
    Point3              csPosition,
    float3              clipInfo,
    vec2                coverageGradient,
    const bool          unblendedPass,
    const bool          inferAmbientOcclusionAtTransparentPixels,
    const bool          hasTransmissive) {
    
    float AO = 1.0;
    if (unblendedPass) {
        // There is no blending...normal situation
        AO = texelFetch(ambientOcclusion_buffer, min(ivec2(coord) + ambientOcclusion_offset, ivec2(ambientOcclusion_size.xy - vec2(1, 1))), 0).r;
    } else if (inferAmbientOcclusionAtTransparentPixels && ! hasTransmissive) {
        // Steal local AO for partial coverage. This is wrong in many cases, but should be fairly
        // temporally coherent and keeps the edges of alpha cutouts from appearing too bright.
                
        // Compute the gradient of alpha; that is the direction to march to blend AO. 
        float L = length(coverageGradient);

        float2 sum = float2(0);
        if (L < 1e-4) {
            // Sample densely in a small neighborhood, since the gradient was negligible.
            // This is primarily used right near the alpha = 1 portion of the surface.
            const int R = 3;
            const float stride = 2;

            for (int dy = -R; dy <= R; ++dy) {
                // Offset alternating rows (in the 3x3 case, the 1st and last)
                // To reduce sampling artifacts from a regular grid
                float dxShift = ((abs(dy) & 1) - 0.5);
                for (int dx = -R; dx <= R; ++dx) {
                    sum += sampleNeighborAO(ivec2(coord + vec2(dx + dxShift, dy) * stride), ambientOcclusion_buffer, ambientOcclusion_offset, ambientOcclusion_size, depthBuffer, csPosition.z, clipInfo);
                }
            }
        } else {
            // Step in the gradient direction
            vec2 dir = coverageGradient * (1.0 / L);
            const int R = 12;
            const int stride = 3;
            for (float t = 0; t < R; ++t) {
                sum += sampleNeighborAO(ivec2(coord + dir * (t * float(stride))), ambientOcclusion_buffer, ambientOcclusion_offset, ambientOcclusion_size, depthBuffer, csPosition.z, clipInfo);
            }
        }
        AO = clamp(sum.x / max(0.01, sum.y), 0.0, 1.0);
    }

    // AO scale and bias
    AO = 0.95 * AO + 0.05;
    return AO;
}

#endif
