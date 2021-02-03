/**
  \file data-files/shader/deferredHelpers.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef deferredHelpers_glsl
#define deferredHelpers_glsl

#ifndef GBuffer_glsl
#   error "Requires GBuffer.glsl to be included first"
#endif

#include <g3dmath.glsl>
#include <reconstructFromDepth.glsl>
#include <UniversalMaterial/UniversalMaterial_sample.glsl>

#if !defined(gbuffer_CS_NORMAL_notNull) && !defined(gbuffer_WS_NORMAL_notNull)
#    error "A GBuffer named 'gbuffer_' with WS_NORMAL or CS_NORMAL normals must be declared before including deferredHelpers"
#endif

// Optional per-pixel buffers for computing the outgoing light ("view") vector.
// Compile away if unused.
uniform_Texture(sampler2D, gbuffer_WS_RAY_DIRECTION_);
uniform_Texture(sampler2D, gbuffer_WS_RAY_ORIGIN_);

/** Returns true if a finite surface, false if background.
    Depends on gbuffer_* being defined as globals
 */
bool readUniversalMaterialSampleFromGBuffer(ivec2 C, const bool discardOnBackground, const bool returnEarlyOnBackground, out Vector3 w_o, out UniversalMaterialSample surfel) {

    surfel.emissive = Radiance3(0);

#   ifdef gbuffer_DEPTH_notNull
    {
       float depth = texelFetch(gbuffer_DEPTH_buffer, C, 0).r;
       if (depth >= 1.0) {
           if (discardOnBackground) {
               // This is a background pixel, not part of an object
#              if G3D_SHADER_STAGE == G3D_FRAGMENT_SHADER
                    discard;
#              else
                    return false;
#              endif
           } else if (returnEarlyOnBackground) {
#              ifdef gbuffer_EMISSIVE_notNull
                   surfel.emissive = texelFetch(gbuffer_EMISSIVE_buffer, C, 0).rgb * gbuffer_EMISSIVE_readMultiplyFirst.rgb + gbuffer_EMISSIVE_readAddSecond.rgb;
#              else
                   surfel.emissive = Radiance3(0);
#              endif
               return false;
           }
        }
    
        float csZ = reconstructCSZ(depth, gbuffer_camera_clipInfo);
        vec2 pixelCoord = C + vec2(0.5);
        Point3 csPosition = reconstructCSPosition(pixelCoord, csZ, gbuffer_camera_projInfo);
        surfel.position = (gbuffer_camera_frame * vec4(csPosition, 1.0)).xyz;
    }
#   else
    {
#       ifndef gbuffer_CS_POSITION_notNull
        {
#           ifndef gbuffer_WS_POSITION_notNull
#              error "GBuffer must have either DEPTH, CS_POSITION, or WS_POSITION"
#           endif
            surfel.position = texelFetch(gbuffer_WS_POSITION_buffer, C, 0).xyz;
        }
#       else
        {
            // Read position from explicit buffer
            Point3 csPosition = texelFetch(gbuffer_CS_POSITION_buffer, C, 0).xyz;

            if (csPosition.z == 0) {
                if (discardOnBackground) {
                    // This is a background pixel, not part of an object
#                   if G3D_SHADER_STAGE == G3D_FRAGMENT_SHADER
                        discard;
#                   else
                        return false;
#                   endif
                } else if (returnEarlyOnBackground) {
#                   ifdef gbuffer_EMISSIVE_notNull
                        surfel.emissive = texelFetch(gbuffer_EMISSIVE_buffer, C, 0).rgb * gbuffer_EMISSIVE_readMultiplyFirst.rgb + gbuffer_EMISSIVE_readAddSecond.rgb;
#                   endif
                    return false;
                }
            }
            surfel.position = (gbuffer_camera_frame * vec4(csPosition, 1.0)).xyz;
        }
#       endif
    }
#   endif

    // Surface normal
#   ifdef gbuffer_CS_NORMAL_notNull
    {
        Vector3 csN = texelFetch(gbuffer_CS_NORMAL_buffer, C, 0).xyz * gbuffer_CS_NORMAL_readMultiplyFirst.xyz + gbuffer_CS_NORMAL_readAddSecond.xyz;
        surfel.tsNormal = surfel.geometricNormal = surfel.shadingNormal = surfel.glossyShadingNormal = normalize(mat3x3(gbuffer_camera_frame) * csN);
    }
#   else
    {
        Vector3 wsN = texelFetch(gbuffer_WS_NORMAL_buffer, C, 0).xyz * gbuffer_WS_NORMAL_readMultiplyFirst.xyz + gbuffer_WS_NORMAL_readAddSecond.xyz;
        if (dot(wsN, wsN) < 0.0001) {
            if (discardOnBackground) {
                // This is a background pixel, not part of an object
#              if G3D_SHADER_STAGE == G3D_FRAGMENT_SHADER
                    discard;
#              else
                    return false;
#              endif
            } else if (returnEarlyOnBackground) {
#               ifdef gbuffer_EMISSIVE_notNull
                surfel.emissive = texelFetch(gbuffer_EMISSIVE_buffer, C, 0).rgb * gbuffer_EMISSIVE_readMultiplyFirst.rgb + gbuffer_EMISSIVE_readAddSecond.rgb;
#               endif
                return false;
            }
        }
        surfel.tsNormal = surfel.geometricNormal = surfel.shadingNormal = surfel.glossyShadingNormal = normalize(wsN);
    }
#   endif

    surfel.offsetTexCoord = Point2(0);
    
    // View vector
#   ifdef gbuffer_WS_RAY_DIRECTION_notNull
        w_o = -normalize(texelFetch(gbuffer_WS_RAY_DIRECTION_buffer, C, 0).xyz * gbuffer_WS_RAY_DIRECTION_readMultiplyFirst.xyz + gbuffer_WS_RAY_DIRECTION_readAddSecond.xyz);
#   elif defined(gbuffer_WS_RAY_ORIGIN_notNull)
        w_o = normalize(texelFetch(gbuffer_WS_RAY_ORIGIN_buffer, C, 0).xyz - surfel.position);
#   else
        w_o = normalize(gbuffer_camera_frame[3] - surfel.position);
#   endif

#   ifdef gbuffer_LAMBERTIAN_notNull    
        surfel.lambertianReflectivity = texelFetch(gbuffer_LAMBERTIAN_buffer, C, 0).rgb;
#   else
        surfel.lambertianReflectivity = Color3(0);
#   endif

    surfel.coverage = 1.0;

    {
        Color4  temp;
#       ifdef gbuffer_GLOSSY_notNull
            temp = texelFetch(gbuffer_GLOSSY_buffer, C, 0);
#       else
            temp = Color4(0);
#       endif
        surfel.fresnelReflectionAtNormalIncidence = temp.rgb;
        surfel.smoothness = temp.a;
    }

    surfel.transmissionCoefficient = Color3(0);
#   ifdef gbuffer_EMISSIVE_notNull
        surfel.emissive = texelFetch(gbuffer_EMISSIVE_buffer, C, 0).rgb * gbuffer_EMISSIVE_readMultiplyFirst.rgb + gbuffer_EMISSIVE_readAddSecond.rgb;
#   endif

    surfel.lightMapRadiance = Radiance3(0);
    return true;
}

#endif
