/**
  \file data-files/shader/UniversalSurface/UniversalSurface_vertexHelpers.glsl

  Provides helper transformation functions for universal surface.

  This is packaged separately from UniversalSurface_render.vrt and UniversalSurface_vertex.glsl to make it easy to compute 
  the object-space positions procedurally in related shaders but still use the material and
  lighting model from UniversalSurface.

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef UniversalSurface_vertexHelpers_h
#define UniversalSurface_vertexHelpers_h

#include <compatibility.glsl>

#expect NUM_LIGHTMAP_DIRECTIONS "0, 1, or 3"

/** Provided to make it easy to perform custom vertex manipulation and procedural vertex generation. Operates in object space. */

void UniversalSurface_customOSVertexTransformation(inout vec4 vertex, inout vec3 normal, inout vec4 packedTangent, inout vec2 tex0, inout vec2 tex1) {
    // Intentionally empty
}


mat4 getBoneMatrix(in sampler2D boneMatrixTexture, in int index) {
    // Stored in boneMatrixTexture as 3x4 matrix
    vec4 row0 = texelFetch(boneMatrixTexture, ivec2(index, 0), 0);
    vec4 row1 = texelFetch(boneMatrixTexture, ivec2(index, 1), 0);
    vec4 row2 = texelFetch(boneMatrixTexture, ivec2(index, 2), 0);
    
    // Constructs from columns 
    return mat4(
        vec4(row0.x, row1.x, row2.x, 0.0),
        vec4(row0.y, row1.y, row2.y, 0.0),
        vec4(row0.z, row1.z, row2.z, 0.0),
        vec4(row0.w, row1.w, row2.w, 1.0)
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
