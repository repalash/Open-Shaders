// -*- c++ -*-
/** \file LightingEnvironment/LightingEnvironment_environmentMapUniforms.glsl */

#ifndef LightingEnvironment_environmentMapUniforms_glsl
#define LightingEnvironment_environmentMapUniforms_glsl

#extension GL_ARB_texture_query_lod : enable


#include <g3dmath.glsl>

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
                textureCubeLod(environmentMap$(e)_buffer, wsN, MAXMIP).rgb * 
#           endif
            environmentMap$(e)_readMultiplyFirst.rgb;
    }
#   endfor

    return E_lambertianAmbient;
}


/** Uses the globals:
  NUM_ENVIRONMENT_MAPS
  environmentMap$(i)_buffer
  environmentMap$(i)_scale
*/
Color3 computeGlossyEnvironmentMapLighting(Vector3 wsR, bool isMirror, float glossyExponent) {
    
    Color3 E_glossyAmbient = Color3(0.0);

    // We compute MIP levels based on the glossy exponent for non-mirror surfaces
    float MIPshift = isMirror ? 0.0 : -0.5 * log2(glossyExponent + 1.0);
#   for (int e = 0; e < NUM_ENVIRONMENT_MAPS; ++e)
    {
        float MIPlevel = isMirror ? 0.0 : (environmentMap$(e)_glossyMIPConstant + MIPshift);
#       if (__VERSION__ >= 400) || defined(GL_ARB_texture_query_lod)
            MIPlevel = max(MIPlevel, textureQueryLod(environmentMap$(e)_buffer, wsR).y);
#       endif
        E_glossyAmbient += 
#           if defined(environmentMap$(e)_notNull)
                textureCubeLod(environmentMap$(e)_buffer, wsR, MIPlevel).rgb * 
#           endif
            environmentMap$(e)_readMultiplyFirst.rgb;
    }
#   endfor

    return E_glossyAmbient;
}

#endif
