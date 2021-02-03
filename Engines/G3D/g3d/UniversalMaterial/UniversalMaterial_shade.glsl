/**
  \file data-files/shader/UniversalMaterial/UniversalMaterial_shade.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef UniversalMaterial_shade_glsl
#define UniversalMaterial_shade_glsl

#include <g3dmath.glsl>
#include <UniversalMaterial/UniversalMaterial_sample.glsl>
#include <AmbientOcclusion/AmbientOcclusion_sample.glsl>

/**
If ambientOcclusion_notNull is defined, assumes the following globals are bound:
 ambientOcclusion_buffer
 ambientOcclusion_offset
 ambientOcclusion_size
 depthBuffer
 clipInfo

Also assumes the following globals are bound:
 background
 backgroundMinCoord
 backgroundMaxCoord
 backSizeMeters
 backgroundZ
*/
void UniversalMaterial_shade
   (UniversalMaterialSample     materialSample,
    Point3                      wsEyePos,
    Point3                      csPosition,
    Vector3                     csNormal,
    out Radiance3               L_o,
    out Color3                  transmissionCoefficient,
    const bool                  unblendedPass,
    const bool                  inferAmbientOcclusionAtTransparentPixels, 
    const bool                  hasTransmissive,
    const bool                  hasRefraction) {

    vec3 w_o = normalize(wsEyePos - materialSample.position);
    {        
        float cos_o = dot(materialSample.glossyShadingNormal, w_o);
        Color3 F = schlickFresnel(materialSample.fresnelReflectionAtNormalIncidence, max(0.0001, cos_o), materialSample.smoothness);
        Color3 lambertianCoefficient = square(1.0 - F) * materialSample.lambertianReflectivity * invPi;
        transmissionCoefficient = materialSample.transmissionCoefficient * (Color3(1.0) - F) * (Color3(1.0) - lambertianCoefficient);
    }
    
    L_o = Radiance3(0);

    if (unblendedPass && hasRefraction && (transmissionCoefficient.r + transmissionCoefficient.g + transmissionCoefficient.b > 0.0)) {
        // Refraction is handled as an "opaque" pass in the sense that it writes to the depth buffer
        // and paints the refraction onto the object's surface

        Radiance3 L_refracted = computeRefraction(background, backgroundMinCoord, backgroundMaxCoord, backSizeMeters, backgroundZ, csNormal, csPosition, materialSample.etaRatio);
        L_o += L_refracted * transmissionCoefficient;
        // We're painting the background color directly onto the surface for refraction, so there is no additional
        // transmitted light (N.B. there may be partial coverage, however, which will be factored in by the blending)
        transmissionCoefficient = Color3(0.0);
    }

    float AO = 
#   ifdef ambientOcclusion_notNull
        sampleAO(gl_FragCoord.xy, ambientOcclusion_buffer, ambientOcclusion_offset, ivec2(ambientOcclusion_size.xy), depthBuffer, csPosition, clipInfo, vec2(dFdx(materialSample.coverage), dFdy(materialSample.coverage)), unblendedPass, inferAmbientOcclusionAtTransparentPixels, hasTransmissive);
#   else
        1.0;
#   endif

    // How much ambient occlusion to apply to direct illumination (sort of approximates area lights,
    // more importantly: NPR term that adds local contrast)
    const float aoInfluenceOnDirectIllumination = 0.65;
    float directAO = lerp(1.0, AO, aoInfluenceOnDirectIllumination);
    
    Radiance3 L_scatteredDirect   = computeDirectLighting(materialSample, w_o, 1.0);
    Radiance3 L_scatteredIndirect = computeIndirectLighting(materialSample, w_o, true, NUM_LIGHTMAP_DIRECTIONS);

    // Outgoing light
    L_o += materialSample.emissive + L_scatteredIndirect * AO + L_scatteredDirect * directAO;
}

#endif
