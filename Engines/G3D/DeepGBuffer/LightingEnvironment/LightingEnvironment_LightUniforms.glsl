// -*- c++ -*-
/** \file LightingEnvironment/LightingEnvironment_LightUniforms.glsl */

#ifndef LightingEnvironment_LightUniforms_glsl
#define LightingEnvironment_LightUniforms_glsl

#include <g3dmath.glsl>
#include <Light/Light.glsl>
#include <compatibility.glsl>
#include <Texture/Texture.glsl>


#expect NUM_LIGHTS "Integer number of direct light sources (and shadow maps)"

#for (int I = 0; I < NUM_LIGHTS; ++I) 
    /** World space light position */
    uniform vec4        light$(I)_position;

    /** Power of the light */
    uniform vec3        light$(I)_color;

    /** Spot light facing direction (unit length) */
    uniform vec3        light$(I)_direction;

    /** w element is the spotlight cutoff angle.*/
    uniform vec4        light$(I)_attenuation;

    /** Is this spotlight's field of view rectangular (instead of round)? */
    uniform bool        light$(I)_rectangular;

    uniform vec3        light$(I)_up;

    uniform vec3        light$(I)_right;

    /** Radius of the light bulb itself; no relation to the light's effect sphere */
    uniform float       light$(I)_radius;

#   if defined(light$(I)_shadowMap_notNull)
        /** Modelview projection matrix used for the light's shadow map */
        uniform mat4                light$(I)_shadowMap_MVP;
        uniform float               light$(I)_shadowMap_bias;

        uniform_Texture(2DShadow,   light$(I)_shadowMap_);
#   endif
#endfor


/**
 Uses global variables:

  light$(I)_position
  light$(I)_attenuation
  light$(I)_direction
  light$(I)_up
  light$(I)_right
  light$(I)_rectangular
  light$(I)_radius
  light$(I)_color
  light$(I)_shadowMap_notNull
  light$(I)_shadowMap_invSize
  light$(I)_shadowMap_buffer
 */
void computeDirectLighting(Vector3 n, Vector3 w_o, Vector3 n_face, float backside, Point3 wsPosition, float glossyExponent, inout Color3 E_lambertian, inout Color3 E_glossy) {
    vec3 w_i;
#   for (int I = 0; I < NUM_LIGHTS; ++I)
    {
#       if defined(light$(I)_shadowMap_notNull)
            // "Normal offset shadow mapping" http://www.dissidentlogic.com/images/NormalOffsetShadows/GDC_Poster_NormalOffset.png
            // Note that the normal bias must be > shadowMapBias$(I) to prevent self-shadowing; we use 3x here so that most
            // glancing angles are ok.
            vec4 shadowCoord = light$(I)_shadowMap_MVP * vec4(wsPosition + w_o * (1.5 * light$(I)_shadowMap_bias) + n_face * (backside * 0.5 * light$(I)_shadowMap_bias), 1.0);
            addShadowedLightContribution(n, w_o, wsPosition, glossyExponent,
                light$(I)_position, light$(I)_attenuation, light$(I)_direction, light$(I)_up, light$(I)_right, light$(I)_rectangular, light$(I)_radius, light$(I)_color, 
                shadowCoord, light$(I)_shadowMap_buffer, light$(I)_shadowMap_invSize.xy,
                n_face, backside,
                E_lambertian, E_glossy, w_i);
#       else
            addLightContribution(n, w_o, wsPosition, glossyExponent,
                light$(I)_position, light$(I)_attenuation, light$(I)_direction, light$(I)_up, light$(I)_right, light$(I)_rectangular, light$(I)_radius, light$(I)_color, 
                n_face, backside,
                E_lambertian, E_glossy, w_i);
#      endif
    }
#   endfor
}

#endif
