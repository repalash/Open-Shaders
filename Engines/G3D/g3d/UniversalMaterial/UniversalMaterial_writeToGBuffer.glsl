/**
  \file data-files/shader/UniversalMaterial/UniversalMaterial_writeToGBuffer.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef UniversalMaterial_writeToGBuffer_glsl
#define UniversalMaterial_writeToGBuffer_glsl

#include <UniversalMaterial/UniversalMaterial_sample.glsl>

void writeToGBuffer
   (UniversalMaterialSample     materialSample,
    mat4                        ProjectToScreenMatrix,
    Point3                      csPrevPosition,
    mat4                        PreviousProjectToScreenMatrix) {

#  if UNBLENDED_PASS && HAS_TRANSMISSIVE
        if (materialSample.transmissionCoefficient.r + materialSample.transmissionCoefficient.g + materialSample.transmissionCoefficient.b != 0) {
            // This pixel needs blending
            discard;
        }
#   endif

#   ifdef GBUFFER_HAS_LAMBERTIAN
        LAMBERTIAN.rgb = materialSample.lambertianReflectivity;// * LAMBERTIAN_writeMultiplyFirst.xyz + LAMBERTIAN_writeAddSecond.xyz;
#   endif

#   ifdef GBUFFER_HAS_EMISSIVE
        EMISSIVE.rgb = materialSample.emissive * EMISSIVE_writeMultiplyFirst.xyz;// + EMISSIVE_writeAddSecond.xyz;
#   endif

#   ifdef GBUFFER_HAS_TRANSMISSIVE
        TRANSMISSIVE = vec4(materialSample.transmissionCoefficient, 0.0);
#   endif

#   ifdef GBUFFER_HAS_GLOSSY
        GLOSSY = vec4(materialSample.fresnelReflectionAtNormalIncidence, materialSample.smoothness);
#   endif

    ///////////////////////// NORMALS //////////////////////////////
#   ifdef GBUFFER_HAS_CS_NORMAL
        vec3 csN = mat3(g3d_WorldToCameraMatrix) * materialSample.shadingNormal;
#   endif

#   if defined(GBUFFER_HAS_WS_FACE_NORMAL) || defined(GBUFFER_HAS_CS_FACE_NORMAL)
        vec3 wsFaceNormal = normalize(cross(dFdx(materialSample.position), dFdy(materialSample.position)));
#   endif

#   ifdef GBUFFER_HAS_CS_FACE_NORMAL
        vec3 csFaceNormal = (g3d_WorldToCameraMatrix * vec4(wsFaceNormal, 0.0));
#   endif

#   foreach (NAME, name) in (WS_NORMAL, materialSample.shadingNormal), (CS_NORMAL, csN), (TS_NORMAL, materialSample.tsNormal), (WS_FACE_NORMAL, wsFaceNormal), (CS_FACE_NORMAL, csFaceNormal), (SVO_POSITION, svoPosition)
#       ifdef GBUFFER_HAS_$(NAME)
            $(NAME).xyz = $(name) * $(NAME)_writeMultiplyFirst.xyz + $(NAME)_writeAddSecond.xyz;
#       endif
#   endforeach


#   ifdef GBUFFER_HAS_TEXCOORD0
        TEXCOORD0 = vec4(materialSample.offsetTexCoord, 0.0, 0.0) * TEXCOORD0_writeMultiplyFirst + TEXCOORD0_writeAddSecond;
#   endif

    //////////////////////// POSITIONS /////////////////////////////
    // Old NVIDIA drivers miscompile this unless we write WS_POSITION after the normals

#   if defined(GBUFFER_HAS_CS_POSITION) || defined(GBUFFER_HAS_CS_POSITION_CHANGE) || defined(GBUFFER_HAS_SS_POSITION_CHANGE) || defined(GBUFFER_HAS_CS_Z)
        vec3 csPosition = g3d_WorldToCameraMatrix * vec4(materialSample.position, 1.0);
#   endif

#   ifdef GBUFFER_HAS_CS_POSITION_CHANGE
        vec3 csPositionChange = csPosition - csPrevPosition;
#   endif

#   if defined(GBUFFER_HAS_SS_POSITION_CHANGE)
        // gl_FragCoord.xy has already been rounded to a pixel center, so regenerate the true projected position.
        // This is needed to generate correct velocity vectors in the presence of Projection::pixelOffset
        vec4 accurateHomogeneousFragCoord = ProjectToScreenMatrix * vec4(csPosition, 1.0);
#   endif

#   ifdef GBUFFER_HAS_SS_POSITION_CHANGE

        vec2 ssPositionChange;
        {
            if (csPrevPosition.z >= 0.0) {
                // Projects behind the camera; write zero velocity
                ssPositionChange = vec2(0.0);
            } else {
                vec4 temp = PreviousProjectToScreenMatrix * vec4(csPrevPosition, 1.0);
                // We want the precision of division here and intentionally do not convert to multiplying by an inverse.
                // Expressing the two divisions as a single vector division operation seems to prevent the compiler from
                // computing them at different precisions, which gives non-zero velocity for static objects in some cases.
                // Note that this forces us to compute accurateHomogeneousFragCoord's projection twice, but we hope that
                // the optimizer will share that result without reducing precision.
                vec4 ssPositions = vec4(temp.xy, accurateHomogeneousFragCoord.xy) / vec4(temp.ww, accurateHomogeneousFragCoord.ww);

                ssPositionChange = ssPositions.zw - ssPositions.xy;
            }
        }
#   endif
        

#   foreach (NAME, name, components) in (WS_POSITION, materialSample.position, xyz), (CS_POSITION, csPosition, xyz), (CS_POSITION_CHANGE, csPositionChange, xyz), (SS_POSITION_CHANGE, ssPositionChange, xy)
#       ifdef GBUFFER_HAS_$(NAME)
            $(NAME).$(components) = $(name) * $(NAME)_writeMultiplyFirst.$(components) + $(NAME)_writeAddSecond.$(components);
#       endif
#   endforeach


#   ifdef GBUFFER_HAS_CS_Z
        CS_Z.r = csPosition.z * CS_Z_writeMultiplyFirst.x + CS_Z_writeAddSecond.x;
#   endif
}

#endif
