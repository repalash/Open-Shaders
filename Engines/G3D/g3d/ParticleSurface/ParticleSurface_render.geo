#version 410 or 460
/**
  \file data-files/shader/ParticleSurface/ParticleSurface_render.geo

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#include <compatibility.glsl>
#include <g3dmath.glsl>


// needed to make the bump map code compile on AMD GPUs,
// which don't eliminate the dead code before compiling it for
// this GS profile
#define dFdx(g) ((g) * 0.0)   
#define dFdy(g) ((g) * 0.0)   
#define discard

layout(points) in;

#define CONSTRUCT_CENTER_VERTEX 1
#if CONSTRUCT_CENTER_VERTEX
    layout(triangle_strip, max_vertices = 8) out;
#else
    layout(triangle_strip, max_vertices = 4) out;
#endif

#define HAS_LAMBERTIAN_TERM 1
#define HAS_GLOSSY_TERM 1

#include <LightingEnvironment/LightingEnvironment_uniforms.glsl>
#include <Light/Light.glsl>


#include <UniversalMaterial/UniversalMaterial.glsl>
uniform UniversalMaterial2DArray material;

const float WRAP_SHADING_AMOUNT = 8.0;
const float ENVIRONMENT_SCALE   = max(0.0, 1.0 - WRAP_SHADING_AMOUNT / 20.0);

const int  RECEIVES_SHADOWS_MASK = 2;

uniform float2  textureGridSize;
uniform float2  textureGridInvSize;

uniform float   nearPlaneZ;

// These arrays have a single element because they are GL_POINTS
layout(location = 0) in Point3       wsCenterVertexOutput[];
layout(location = 1) in float3       shapeVertexOutput[];
layout(location = 2) in int4         materialPropertiesVertexOutput[];
layout(location = 3) in float        angleVertexOutput[];
layout(location = 4) in Vector3      normalVertexOutput[];
layout(location = 5) in float        normalWeightVertexOutput[];

#include "ParticleSurface_helpers.glsl"
out RenderGeometryOutputs geoOutputs;

// Shadow map bias...must be relatively high for particles because
// adjacent particles (and this one!) will be oriented differently in the
// shadow map and can easily self-shadow
const float bias = 0.5; // meters

Point3 project(Vector4 v) {
    return v.xyz * (1.0 / v.w);
}


float3 boostSaturation(float3 color, float boost) {
    if (boost != 1.0) {
        color = RGBtoHSV(color);
        color.y *= boost;
        color = HSVtoRGB(color);
    }
    return color;
}

// Compute average lighting around each vertex
Radiance3 computeLight(Point3 wsPosition, Vector3 normal, float normalConfidence, Vector3 wsLookVector, bool receivesShadows) {
    float3 L_in = float3(0);

    float environmentSaturationBoost = 1.25;

    // TODO: Could compute only from center vertex to reduce computation if desired
    Vector3 w_o    = normalize(g3d_CameraToWorldMatrix[3].xyz - wsPosition);

    // Environment
#   for (int i = 0; i < NUM_ENVIRONMENT_MAPS; ++i)
    {
        // Uniform evt component
        // Sample the highest MIP-level to approximate Lambertian integration over the hemisphere
        float3 ambientEvt = (textureLod(environmentMap$(i)_buffer, float3(1, 1, 1), 20).rgb + 
                             textureLod(environmentMap$(i)_buffer, float3(-1,-1,-1), 20).rgb) * 0.5;

        // Directional evt component from front
        float3 directionalEvt = textureLod(environmentMap$(i)_buffer, normal, 9).rgb;

        // Don't quite put full environment contribution in...particles don't receive AO even though they
        // occlude one another, so they tend to get too bright under environment light (which then washes
        // out direct light shadows)
        L_in += boostSaturation(mix(ambientEvt, directionalEvt, 0.5 + normalConfidence * 0.4), environmentSaturationBoost + normalConfidence * 0.25) * 0.90 * environmentMap$(i)_readMultiplyFirst.rgb;
    }
#   endfor

#   for (int I = 0; I < NUM_LIGHTS; ++I)
    do {
        Vector3 w_i;

        // For attenuation purposes, use normal = vector to light
        float attenuation = computeAttenuation(lerp(normalize(light$(I)_position.xyz - wsPosition), normal, normalConfidence),
            light$(I)_position,
            light$(I)_attenuation, light$(I)_softnessConstant, wsPosition, light$(I)_direction, light$(I)_up,
            light$(I)_right, light$(I)_rectangular, light$(I)_radius, w_i);

        // Abort attenuated lights
        if (attenuation <= attenuationThreshold) continue;
#       ifdef light$(I)_shadowMap_notNull
        {
            vec3 adjustedWSPos = wsPosition + w_o * (1.5 * light$(I)_shadowMap_bias) + normal * (0.5 * light$(I)_shadowMap_bias);
            vec4 shadowCoord = light$(I)_shadowMap_MVP * vec4(adjustedWSPos, 1.0);

            // Williams Shadow Map case

            // "Normal offset shadow mapping" http://www.dissidentlogic.com/images/NormalOffsetShadows/GDC_Poster_NormalOffset.png
            // Note that the normal bias must be > shadowMapBias$(I) to prevent self-shadowing; we use 3x here so that most
            // glancing angles are OK.
            float visibility = shadowMapVisibility(light$(I)_direction, light$(I)_position, light$(I)_attenuation, shadowCoord, light$(I)_shadowMap_buffer, light$(I)_shadowMap_invSize.xy, false);

            // This line appears to miscompile on Radeon, causing everything to always be in shadow
            //            if (visibility * attenuation <= attenuationThreshold) continue;

#           ifdef light$(I)_shadowMap_variance_notNull
            {
                vec4 cFrameZRow = vec4(light$(I)_direction.xyz, -light$(I)_position.z);
                float lightSpaceZ = dot(cFrameZRow, vec4(adjustedWSPos, 1.0));
                lightSpaceZ = -dot(light$(I)_direction.xyz, adjustedWSPos - light$(I)_position.xyz);

                // Variance Shadow Map case
                visibility = min(visibility, varianceShadowMapVisibility(shadowCoord, lightSpaceZ, light$(I)_shadowMap_variance_buffer, light$(I)_shadowMap_variance_lightBleedReduction));
            }
#           endif

            // Increase contrast by over-darkening shadows. This mostly only matters for
            // the stochastic variance shadow mapping of self-shadows.
            attenuation *= visibility * visibility * visibility;
            if (attenuation <= attenuationThreshold) continue;
        }
#       endif

        // If there are per-billboard normals, then the lighting code above which assumes no cosine is too dark
        attenuation *= (1.0 + normalConfidence * 0.7);

        // Phase function
        const float k = 0.5;
        float brdf = mix(1.0, pow(max(-dot(w_i, w_o), 0.0), k * 50.0) * (k * 20.0 + 1.0) * 0.125, k);

        L_in += attenuation * brdf * light$(I)_color;
    } while (false); // The do-while loop enables "continue" statements
#   endfor

    return L_in;
}

float alpha = 0.0;


/** Produce a vertex.  Note that x and y are compile-time constants, so most of this arithmetic compiles out. */
void emit(float x, float y, Vector3 normal, float normalConfidence, Vector3 wsLook, bool receivesShadows, Vector2 csRight, Vector2 csUp, Vector3 wsRight, Vector3 wsUp) {
    Point3 wsPosition = wsCenterVertexOutput[0] + wsRight * x + wsUp * y;

    geoOutputs.color.rgb = computeLight(wsPosition, normal, normalConfidence, wsLook, receivesShadows);
    geoOutputs.color.a   = min(1.0, alpha);
    
    int texelWidth = materialPropertiesVertexOutput[0].y;
    geoOutputs.texCoord.xy = ((Point2(x, y) * 0.5) + Vector2(0.5, 0.5)) * float(texelWidth) * material.lambertian.invSize.xy;
    geoOutputs.texCoord.z  = materialPropertiesVertexOutput[0].x;
    geoOutputs.csPosition = Vector3(gl_in[0].gl_Position.xy + csRight * x + csUp * y, gl_in[0].gl_Position.z);
    gl_Position           = g3d_ProjectionMatrix * Vector4(geoOutputs.csPosition, 1.0);
    EmitVertex();
}


void main() {
    float csZ = gl_in[0].gl_Position.z;
    if (csZ >= nearPlaneZ) {
        // Near-plane culled
        return;
    }

    // Read the particle properties
    bool  receivesShadows = bool(materialPropertiesVertexOutput[0].z & RECEIVES_SHADOWS_MASK);
    float radius          = shapeVertexOutput[0].x;
    float angle           = angleVertexOutput[0];
    float coverage        = shapeVertexOutput[0].y;

    // Used for shadow map bias
    Vector3 wsLook = g3d_CameraToWorldMatrix[2].xyz;

    // TODO: Bend normal for each vertex
    Vector3 billboardNormal = normalize(g3d_CameraToWorldMatrix[3].xyz - wsCenterVertexOutput[0]);
    Vector3 particleNormal  = normalVertexOutput[0];

    // How much do we trust the particle normal?
    float normalConfidence = normalWeightVertexOutput[0];
    Vector3 normal  = lerp(billboardNormal, particleNormal, normalConfidence);

    // Fade out alpha as the billboard approaches the near plane
    float softParticleFadeRadius = radius * 3.0;
    alpha = min(1.0, coverage * saturate((nearPlaneZ - csZ) / softParticleFadeRadius));

    // Rotate the particle
    Vector2 csRight = Vector2(cos(angle), sin(angle)) * radius;
    Vector2 csUp    = Vector2(-csRight.y, csRight.x);

    Vector3 wsRight = g3d_CameraToWorldMatrix[0].xyz * csRight.x + g3d_CameraToWorldMatrix[1].xyz * csRight.y;
    Vector3 wsUp    = g3d_CameraToWorldMatrix[0].xyz * csUp.x    + g3d_CameraToWorldMatrix[1].xyz * csUp.y;

    // 
    //   C-------D    C-------D
    //   | \     |    | \   / |
    //   |   \   |    |   E   |
    //   |     \ |    | /   \ |
    //   A-------B    A-------B
    //
    //     ABCD       ABEDC AEC
#   if CONSTRUCT_CENTER_VERTEX
        emit(-1, -1, normal, normalConfidence, wsLook, receivesShadows, csRight, csUp, wsRight, wsUp); // A
        emit(+1, -1, normal, normalConfidence, wsLook, receivesShadows, csRight, csUp, wsRight, wsUp); // B
        emit( 0,  0, normal, normalConfidence, wsLook, receivesShadows, csRight, csUp, wsRight, wsUp); // E
        emit(+1, +1, normal, normalConfidence, wsLook, receivesShadows, csRight, csUp, wsRight, wsUp); // D
        emit(-1, +1, normal, normalConfidence, wsLook, receivesShadows, csRight, csUp, wsRight, wsUp); // C
        EndPrimitive();

        emit(-1, -1, normal, normalConfidence, wsLook, receivesShadows, csRight, csUp, wsRight, wsUp); // A
        emit( 0, 0,  normal, normalConfidence, wsLook, receivesShadows, csRight, csUp, wsRight, wsUp); // E
        emit(-1, +1, normal, normalConfidence, wsLook, receivesShadows, csRight, csUp, wsRight, wsUp); // C
        EndPrimitive();
#   else
        emit(-1, -1, normal, normalConfidence, wsLook, receivesShadows, csRight, csUp, wsRight, wsUp); // A
        emit(+1, -1, normal, normalConfidence, wsLook, receivesShadows, csRight, csUp, wsRight, wsUp); // B
        emit(-1, +1, normal, normalConfidence, wsLook, receivesShadows, csRight, csUp, wsRight, wsUp); // C
        emit(+1, +1, normal, normalConfidence, wsLook, receivesShadows, csRight, csUp, wsRight, wsUp); // D
        EndPrimitive();
#   endif
}
