// -*- c++ -*-
/**
 \file UniversalSurface_vertex.glsl
 \author Morgan McGuire, Michael Mara

  Provides helper transformation functions for universal surface.

 This is packaged separately from UniversalSurface_render.vrt and UniversalSurface_vertex.glsl to make it easy to compute 
 the object-space positions procedurally in related shaders but still use the material and
 lighting model from UniversalSurface.

 \beta

 \created 2013-08-13
 \edited  2013-08-13
 */
#ifndef UniversalSurface_vertexHelpers_h
#define UniversalSurface_vertexHelpers_h
#include <compatibility.glsl>
#expect NUM_LIGHTMAP_DIRECTIONS "0, 1, or 3"

void UniversalSurface_transform(in vec4 osVertex, in vec3 osNormal, in vec4 osPackedTangent, in vec2 texCoord0, in vec2 texCoord1, in vec4 vColor) {
    vec3 wsEyePos = g3d_CameraToWorldMatrix[3].xyz;

    wsPosition = (g3d_ObjectToWorldMatrix * osVertex).xyz;
    
    tan_Z = g3d_ObjectToWorldNormalMatrix * osNormal.xyz;

#   ifdef NORMALBUMPMAP      
        tan_X = mat3(g3d_ObjectToWorldMatrix) * osPackedTangent.xyz;

        // T and N are guaranteed perpendicular, so B is normalized.  Its facing 
        // direction is stored in the texcoord w component.
        tan_Y = cross(tan_Z, tan_X) * osPackedTangent.w;
#       if PARALLAXSTEPS > 0
            // Compute the tangent space eye vector (ATI does not support the transpose operator)
            mat3 worldToTangent = mat3(tan_X.x, tan_Y.x, tan_Z.x,
                                       tan_X.y, tan_Y.y, tan_Z.y,
                                       tan_X.z, tan_Y.z, tan_Z.z);
            _tsE             = worldToTangent * (wsEyePos - wsPosition);
#       endif  
#   endif

    texCoord = texCoord0;
#   if (NUM_LIGHTMAP_DIRECTIONS > 0)
        lightMapCoord = texCoord1;
#   endif    

#   if HAS_VERTEX_COLORS
        vertexColor = vColor;
#endif

    // Multiply the matrix on the RIGHT because that gives higher precision (at least on NVIDIA cards)
    // See http://graphics.cs.williams.edu/papers/SAOHPG12/ for discussion
    gl_Position   = osVertex * gl_ModelViewProjectionMatrixTranspose;
    gl_ClipVertex = osVertex * gl_ModelViewMatrixTranspose;
}


mat4 getBoneMatrix(in sampler2D   boneMatrixTexture, in int index) {
    int baseIndex = index * 2;
    return mat4( 
        texelFetch2D(boneMatrixTexture, ivec2(baseIndex    , 0), 0),
        texelFetch2D(boneMatrixTexture, ivec2(baseIndex    , 1), 0),
        texelFetch2D(boneMatrixTexture, ivec2(baseIndex + 1, 0), 0),
        texelFetch2D(boneMatrixTexture, ivec2(baseIndex + 1, 1), 0)
        );
}


mat4 UniversalSurface_getFullBoneTransform(in vec4 boneWeights, in ivec4 boneIndices, in sampler2D   boneMatrixTexture) {
    mat4 boneTransform = getBoneMatrix(boneMatrixTexture, boneIndices[0]) * boneWeights[0];
    for (int i = 1; i < 4; ++i) {
        boneTransform += getBoneMatrix(boneMatrixTexture, boneIndices[i]) * boneWeights[i];
    }
    return boneTransform;
}


// Transforms the vertex normal and packed tangent according to the skeletal animation matrices
void UniversalSurface_boneTransform(in vec4 boneWeights, in ivec4 boneIndices, in sampler2D   boneTexture, inout vec4 osVertex, inout vec3 osNormal, inout vec4 osPackedTangent) {
    vec3 wsEyePos = g3d_CameraToWorldMatrix[3].xyz;

    //mat4 boneTransform = mat4(1.0);
    mat4 boneTransform = UniversalSurface_getFullBoneTransform(boneWeights, boneIndices, boneTexture);

    osVertex            = boneTransform * osVertex;
    osNormal            = mat3(boneTransform) * osNormal;
    osPackedTangent.xyz = mat3(boneTransform) * osPackedTangent.xyz;

}

#endif