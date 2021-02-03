/**
  \file data-files/shader/UniversalMaterial/UniversalMaterial_sample.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef UniversalMaterial_sample_glsl
#define UniversalMaterial_sample_glsl

#include <g3dmath.glsl>
#include <UniversalMaterial/UniversalMaterial.glsl>
#include <BumpMap/BumpMap.glsl>
#include <lightMap.glsl>
#include <AlphaFilter.glsl>

#ifndef UNBLENDED_PASS
#   define UNBLENDED_PASS 0
#endif

#ifndef TRANSPARENT_AS_OPAQUE_PASS
#   define TRANSPARENT_AS_OPAQUE_PASS 0
#endif
/** 
  Stores interpolated samples of the UniversalMaterial parameters in the particular
  encoding format used for that class and struct (including vertex properties). 
  This is also the format used by the GBuffer.

  \sa UniversalSurfel */
struct UniversalMaterialSample {
    /** Glossy not taken into account. */
    Color3          lambertianReflectivity;

    float           coverage;

    Color3          fresnelReflectionAtNormalIncidence;

    float           smoothness;

    /** Fresnel, glossy, and lambertian not taken into account. */
    Color3          transmissionCoefficient;

    Point2          offsetTexCoord;

    Radiance3       emissive;

    Radiance3       lightMapRadiance;

    /** In world space */
    Vector3         geometricNormal;

    /** In world space */
    Vector3         shadingNormal;

    /** In world space. May be bent away from shadingNormal for anisotropic surfaces. */
    Vector3         glossyShadingNormal;

    /** Tangent space normal */
    Vector3         tsNormal;

    /** In world space */
    Point3          position;

    /** The ratio of the indices of refraction. etaRatio represnts the value (n1 / n2) or (etaReflect / etaTransmit). */
    float           etaRatio;
};


Color3 evaluateUniversalMaterialBSDF(UniversalMaterialSample surfel, Vector3 w_i, Vector3 w_o) {
    Vector3 n = surfel.glossyShadingNormal;
    // Cap infinities
    float glossyExponent = min(1e5, smoothnessToBlinnPhongExponent(surfel.smoothness));
    
    // Incoming reflection vector
    float cos_o = dot(surfel.glossyShadingNormal, w_o);
    Vector3 w_mi = normalize(surfel.glossyShadingNormal * (2.0 * cos_o) - w_o);

    Vector3 w_h = normalize(w_i + w_o);

    // Note that dot(w_h, w_i) == dot(w_h, w_o)
    Color3 F = (maxComponent(surfel.fresnelReflectionAtNormalIncidence) == 0.0) ?
        Color3(0) :
        schlickFresnel(surfel.fresnelReflectionAtNormalIncidence, max(0.001, dot(w_h, w_i)), surfel.smoothness);

    float inPositiveHemisphere = step(0.0, dot(w_i, n)) * step(0.0, dot(w_o, n));

    Color3 f_L = square(1.0 - F) * surfel.lambertianReflectivity * invPi * inPositiveHemisphere;

    // 0^0 = nan, so we max the exponent 
    Color3 f_G = F * pow(max(0.0, dot(w_h, n)), max(glossyExponent, 1e-6)) * (glossyExponent + 8.0) / (8.0 * pi * square(max(0.0, max(dot(w_i, n), dot(w_o, n)))));

    // TODO: Transmission
    Color3 f_T = Color3(0);// ((1.0 - F) * surfel.lambertianReflectivity) * (1.0 - F) * Color3(0);

    return f_L + f_G + f_T;
}

/** 

  \param tsEye Tangent space unit outgoing vector, w_o, used for parallax mapping
  \param wsE   World space unit outgoing vector, w_o

  All of the 'const bool' arguments must be const so that the branches can be evaluated
  at compile time.
 */
#foreach (dim, n) in (2D, 2)
UniversalMaterialSample sampleUniversalMaterial$(dim)
   (UniversalMaterial$(dim)     material,
    Point3                      position,
    Point$(n)                   texCoord,
    Point$(n)                   lightmapCoord,
    Vector3                     tan_X, 
    Vector3                     tan_Y, 
    Vector3                     tan_Z,
    Vector3                     tsEye,
    float                       backside,
    const bool                  discardIfZeroCoverage,
    const bool                  discardIfFullCoverage,
    Color4                      vertexColor,
    const AlphaFilter           alphaFilter,
    const int                   parallaxSteps,
    const bool                  hasNormalBumpMap,
    const bool                  hasVertexColor,
    const bool                  hasMaterialAlpha,
    const bool                  hasTransmissive,
    const bool                  hasEmissive,
    const int                   numLightMapDirections,
    const bool                  reprojectInfoOnly) {

    UniversalMaterialSample smpl;
    smpl.position = position;

    const vec3 BLACK = vec3(0.0, 0.0, 0.0);
    Point$(n) offsetTexCoord;
    smpl.tsNormal = Vector3(0.0,0.0,1.0);
    float rawNormalLength = 1.0;
    if (hasNormalBumpMap) {
        if (parallaxSteps > 0) {
            bumpMap(material.normalBumpMap, material.bumpMapScale, material.bumpMapBias, texCoord, tan_X, tan_Y, tan_Z, backside, normalize(tsEye), smpl.shadingNormal, offsetTexCoord, smpl.tsNormal, rawNormalLength, parallaxSteps);
        } else {
            // Vanilla normal mapping
            bumpMap(material.normalBumpMap, 0.0, 0.0, texCoord, tan_X, tan_Y, tan_Z, backside, vec3(0.0), smpl.shadingNormal, offsetTexCoord, smpl.tsNormal, rawNormalLength, parallaxSteps);
        }
    } else {
        // World space normal
        smpl.shadingNormal = normalize(tan_Z.xyz * backside);
        offsetTexCoord = texCoord;
    }
    
    smpl.offsetTexCoord = offsetTexCoord.xy;
    smpl.coverage = 1.0;

    if (reprojectInfoOnly) { return smpl; }

    smpl.etaRatio = material.etaRatio;

    {
        vec4 temp = sampleTexture(material.lambertian, offsetTexCoord);
        if (hasVertexColor) {
            temp *= vertexColor;
        }
        smpl.lambertianReflectivity = temp.rgb;
        if (hasMaterialAlpha) {
            smpl.coverage = computeCoverage(alphaFilter, temp.a);

            if (discardIfZeroCoverage) {
#               if UNBLENDED_PASS && ! TRANSPARENT_AS_OPAQUE_PASS
                    if (smpl.coverage < 1.0) { discard; }
#               else
                    // In the transparent pass, eliminate fully opaque pixels as well
                    if ((smpl.coverage <= 0.0) || (discardIfFullCoverage && ! hasTransmissive && (smpl.coverage >= 1.0))) {
#               if G3D_SHADER_STAGE == G3D_FRAGMENT_SHADER
                        discard;
#               else
                        return smpl;
#               endif
                    }
#               endif
            } else if (discardIfFullCoverage && ! hasTransmissive && (smpl.coverage >= 1.0)) {
#              if G3D_SHADER_STAGE == G3D_FRAGMENT_SHADER
                discard;
#              else
                return smpl;
#              endif
            }
        }
    }

#   ifndef G3D_OSX
    switch (numLightMapDirections) {
    case 1:
        smpl.lightMapRadiance = sampleTexture(material.lightMap0, lightmapCoord).rgb;
        break;

    case 3:
        if (hasNormalBumpMap) {
            smpl.lightMapRadiance = radiosityNormalMap(material.lightMap0.sampler, material.lightMap1.sampler, material.lightMap2.sampler, lightmapCoord, smpl.tsNormal) * material.lightMap0.readMultiplyFirst.rgb;
        } else {
            // If there's no normal map, then the lightMap axes will all be at the same angle to this surfel,
            // so there's no need to compute dot products: just average
            smpl.lightMapRadiance = 
                (sampleTexture(material.lightMap0, lightmapCoord).rgb +
                 sampleTexture(material.lightMap1, lightmapCoord).rgb +
                 sampleTexture(material.lightMap2, lightmapCoord).rgb) * (1.0 / 3.0);
        }
        break;

    default:
        smpl.lightMapRadiance = Radiance3(0,0,0);
        break;
    } // switch
#   else
        smpl.lightMapRadiance = Radiance3(0,0,0);
#   endif

    if (hasEmissive) {
        smpl.emissive = sampleTexture(material.emissive, offsetTexCoord).rgb;
        if (hasMaterialAlpha) {
            smpl.emissive *= sqrt(1.0 / max(smpl.coverage, 0.0001));
        }
    } else {
        smpl.emissive = Radiance3(0,0,0);
    }

    // We separate out the normal used for glossy reflection from the one used for shading in general
    // to allow subclasses to easily compute anisotropic highlights
    smpl.glossyShadingNormal = smpl.shadingNormal;

    {
        vec4 temp = sampleTexture(material.glossy, offsetTexCoord);
        smpl.fresnelReflectionAtNormalIncidence = temp.rgb;
        smpl.smoothness = temp.a;
    }
    
    const float almostUnit = 0.98;
    if (hasNormalBumpMap && (rawNormalLength < almostUnit)) {
        // Convert normal variance to roughness
        smpl.smoothness *= pow64(min(1.0, rawNormalLength / almostUnit));
    }

    if (hasTransmissive) {
        smpl.transmissionCoefficient = sampleTexture(material.transmissive, offsetTexCoord).rgb;
    } else {
        smpl.transmissionCoefficient = Color3(0, 0, 0);
    }

    return smpl;
}
#endforeach


#foreach (dim, n) in (2D, 2)
UniversalMaterialSample sampleUniversalMaterial$(dim)
   (UniversalMaterial$(dim)     material,
    Point3                      position,
    Point$(n)                   texCoord,
    Point$(n)                   lightmapCoord,
    Vector3                     tan_X, 
    Vector3                     tan_Y, 
    Vector3                     tan_Z,
    Vector3                     tsEye,
    float                       backside,
    const bool                  discardIfZeroCoverage,
    const bool                  discardIfFullCoverage,
    Color4                      vertexColor,
    const AlphaFilter           alphaFilter,
    const int                   parallaxSteps,
    const bool                  hasNormalBumpMap,
    const bool                  hasVertexColor,
    const bool                  hasMaterialAlpha,
    const bool                  hasTransmissive,
    const bool                  hasEmissive,
    const int                   numLightMapDirections) {

    return sampleUniversalMaterial$(dim)
    (material,
     position,
     texCoord,
     lightmapCoord,
     tan_X, 
     tan_Y, 
     tan_Z,
     tsEye,
     backside,
     discardIfZeroCoverage,
     discardIfFullCoverage,
     vertexColor,
     alphaFilter,
     parallaxSteps,
     hasNormalBumpMap,
     hasVertexColor,
     hasMaterialAlpha,
     hasTransmissive,
     hasEmissive,
     numLightMapDirections,
     false);
}
#endforeach

#endif
