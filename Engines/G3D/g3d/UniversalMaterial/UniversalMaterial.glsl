/**
  \file data-files/shader/UniversalMaterial/UniversalMaterial.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef UniversalMaterial_glsl
#define UniversalMaterial_glsl

#include <compatibility.glsl>
#include <g3dmath.glsl>
#include <Texture/Texture.glsl>

/**
 \def uniform_UniversalMaterial

 Declares all material properties. Additional macros will also be bound 
 by UniversalMaterial::setShaderArgs:

 - name##NUM_LIGHTMAP_DIRECTIONS
 - name##HAS_NORMAL_BUMP_MAP
 - name##PARALLAXSTEPS
 
 \param name Include the underscore suffix, if a name is desired

 \sa G3D::UniversalMaterial, G3D::UniversalMaterial::setShaderArgs, G3D::Args, uniform_Texture

 \deprecated
 */
#ifndef G3D_OSX
#define uniform_UniversalMaterial(name)\
    uniform_Texture(sampler2D, name##LAMBERTIAN_);              \
    uniform_Texture(sampler2D, name##GLOSSY_);                  \
    uniform_Texture(sampler2D, name##TRANSMISSIVE_);            \
    uniform float              name##etaTransmit;               \
    uniform float              name##etaRatio;                  \
    uniform_Texture(sampler2D, name##EMISSIVE_);                \
    uniform_Texture(sampler2D, name##lightMap0_);               \
    uniform_Texture(sampler2D, name##lightMap1_);               \
    uniform_Texture(sampler2D, name##lightMap2_);               \
    uniform uint               name##flags;                     \
    uniform sampler2D          name##normalBumpMap;             \
    uniform float              name##bumpMapScale;              \
    uniform float              name##bumpMapBias;
#else
#define uniform_UniversalMaterial(name)\
    uniform_Texture(sampler2D, name##LAMBERTIAN_);              \
    uniform_Texture(sampler2D, name##GLOSSY_);                  \
    uniform_Texture(sampler2D, name##TRANSMISSIVE_);            \
    uniform float              name##etaTransmit;               \
    uniform float              name##etaRatio;                  \
    uniform_Texture(sampler2D, name##EMISSIVE_);                \
    uniform uint               name##flags;                     \
    uniform sampler2D          name##normalBumpMap;             \
    uniform float              name##bumpMapScale;              \
    uniform float              name##bumpMapBias;
#endif

/** 
   \def UniversalMaterial
 \sa G3D::UniversalMaterial, G3D::UniversalMaterial::setShaderArgs, G3D::Args, uniform_Texture

*/
#foreach (dim) in (2D), (3D), (2DArray)
    struct UniversalMaterial$(dim) {
        Texture$(dim)    lambertian;
        Texture$(dim)    glossy;
        Texture$(dim)    transmissive;
        Texture$(dim)    emissive;
        float            etaTransmit;
        //The ratio of the indices of refraction. etaRatio represnts the value (n1 / n2) or (etaReflect / etaTransmit).
        float            etaRatio;
#       ifndef G3D_OSX
            Texture$(dim) lightMap0;
            Texture$(dim) lightMap1;
            Texture$(dim) lightMap2;
#       endif
        sampler$(dim)    normalBumpMap;
        uint             flags;
        float            bumpMapScale;
        float            bumpMapBias;
        int              alphaFilter;
    };
#endforeach

    
Radiance3 computeRefraction
   (sampler2D       background,
    Point2          backgroundMinCoord, 
    Point2          backgroundMaxCoord,
    vec2            backSizeMeters,
    float           backZ, 
    Vector3         csN,
    Point3          csPos, 
    float           etaRatio) {

    // Incoming ray direction from eye, pointing away from csPos
    Vector3 csw_i = normalize(-csPos);

    // Refracted ray direction, pointing away from wsPos
    Vector3 csw_o = refract(-csw_i, csN, etaRatio); 

    bool totalInternalRefraction = (dot(csw_o, csw_o) < 0.01);
    if (totalInternalRefraction) {
        // No transmitted light
        return Radiance3(0.0);
    } else {
        // Take to the reference frame of the background (i.e., offset) 
        Vector3 d = csw_o;

        // Take to the reference frame of the background, where it is the plane z = 0
        Point3 P = csPos;
        P.z -= backZ;

        // Find the xy intersection with the plane z = 0
        Point2 hit = (P.xy - d.xy * P.z / d.z);

        // Hit is now scaled in meters from the center of the screen; adjust scale and offset based 
        // on the actual size of the background
        Point2 backCoord = (hit / backSizeMeters) + Vector2(0.5);

        if (! g3d_InvertY) {
            backCoord.y = 1.0 - backCoord.y;
        }
        
        // Issue0002: lerp to environment map as we approach the boundaries of the guard band
        return texture(background, clamp(backCoord, backgroundMinCoord, backgroundMaxCoord)).rgb;
    }
}

#endif
