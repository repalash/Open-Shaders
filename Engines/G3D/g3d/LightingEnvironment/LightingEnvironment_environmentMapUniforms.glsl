/**
  \file data-files/shader/LightingEnvironment/LightingEnvironment_environmentMapUniforms.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef LightingEnvironment_environmentMapUniforms_glsl
#define LightingEnvironment_environmentMapUniforms_glsl

#include <g3dmath.glsl>
#include <UniversalMaterial/UniversalMaterial_sample.glsl>

#expect NUM_ENVIRONMENT_MAPS "integer for number of environment maps to be blended"

#for (int i = 0; i < NUM_ENVIRONMENT_MAPS; ++i)
    /** The cube map with default OpenGL MIP levels */
    uniform samplerCube environmentMap$(i)_buffer;

    /** Includes the weight for interpolation factors, the environment map's native scaling,
        and a factor of PI */
    uniform vec4        environmentMap$(i)_readMultiplyFirst;

    /** log2(environmentMap.width * sqrt(3)) */
    uniform float       environmentMap$(i)_glossyMIPConstant;
#endfor

/** Uses the globals:
  NUM_ENVIRONMENT_MAPS
  environmentMap$(i)_buffer
  environmentMap$(i)_scale
*/
Color3 computeLambertianEnvironmentMapLighting(Vector3 wsN) {
    Color3 E_lambertianAmbient = Color3(0.0);

#   for (int e = 0; e < NUM_ENVIRONMENT_MAPS; ++e)
    {
        // Sample the highest MIP-level to approximate Lambertian integration over the hemisphere
        const float MAXMIP = 20;
        E_lambertianAmbient += 
#           if defined(environmentMap$(e)_notNull)
                textureLod(environmentMap$(e)_buffer, wsN, MAXMIP).rgb * 
#           endif
            environmentMap$(e)_readMultiplyFirst.rgb;
    }
#   endfor

    return E_lambertianAmbient;
}


Radiance3 sampleEnvironmentMap(Vector3 wsDirection, bool forceMIP0, float MIPShift, const bool allowMIPMap) {    
    Radiance3 L = Color3(0.0);
#   for (int e = 0; e < NUM_ENVIRONMENT_MAPS; ++e)
    {
        float MIPlevel = forceMIP0 ? 0.0 : (environmentMap$(e)_glossyMIPConstant + MIPShift);
#       if (G3D_SHADER_STAGE == G3D_FRAGMENT_SHADER)
            if (allowMIPMap) {
                MIPlevel = max(MIPlevel, textureQueryLod(environmentMap$(e)_buffer, wsDirection).y);
            }
#       endif
        L += 
#           if defined(environmentMap$(e)_notNull)
                textureLod(environmentMap$(e)_buffer, wsDirection, MIPlevel).rgb * 
#           endif
            environmentMap$(e)_readMultiplyFirst.rgb;
    }
#   endfor

    return L;
}


/** Uses the globals:
  NUM_ENVIRONMENT_MAPS
  environmentMap$(i)_buffer
  environmentMap$(i)_scale
*/
Color3 computeGlossyEnvironmentMapLighting(Vector3 wsR, bool isMirror, float glossyExponent, const bool allowMIPMap) {
     // We compute MIP levels based on the glossy exponent for non-mirror surfaces
    float MIPShift = isMirror ? 0.0 : -0.5 * log2(glossyExponent + 1.0);
    return sampleEnvironmentMap(wsR, isMirror, MIPShift, allowMIPMap) * invPi;
}



Radiance3 computeIndirectLighting(UniversalMaterialSample surfel, Vector3 w_o, const bool allowAutoMIP, const int numLightMapDirections) {
    float glossyExponent = smoothnessToBlinnPhongExponent(surfel.smoothness);
    
    // Incoming reflection vector
    float cos_o = dot(surfel.glossyShadingNormal, w_o);
    Vector3 w_mi = normalize(surfel.glossyShadingNormal * (2.0 * cos_o) - w_o);

    // For mirror reflection (which is the only thing we can use for the evt light), the
    // half vector is the normal, so w_h . w_o == n . w_o 
    Color3 F = schlickFresnel(surfel.fresnelReflectionAtNormalIncidence, max(0.001, cos_o), surfel.smoothness);

    Radiance3 glossyAmbient = computeGlossyEnvironmentMapLighting(w_mi, (surfel.smoothness == 1.0), glossyExponent, allowAutoMIP);

    Radiance3 lambertianAmbient;
    if (numLightMapDirections == 0) {
        lambertianAmbient = computeLambertianEnvironmentMapLighting(surfel.shadingNormal);
    } else {
        lambertianAmbient += surfel.lightMapRadiance;
    }

    Color3 lambertianColor = (1.0 - F) * surfel.lambertianReflectivity * invPi;

    return lambertianAmbient * lambertianColor * (1 - F) + F * glossyAmbient;
}

#endif
