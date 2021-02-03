/**
  \file data-files/shader/VoxelSurface/VoxelSurface_pixel.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/

#include <compatibility.glsl>
#include <UniversalMaterial/UniversalMaterial_writeToGBuffer.glsl>
#include <AlphaFilter.glsl>
#include "our.glsl"
#include <reconstructFromDepth.glsl>

flat in Point3          boxCenter;

// in meters
uniform float   voxelRadius;
uniform float   invVoxelRadius;



//#define ANIMATION 0
#if ANIMATION
flat in float       orientation;
#endif

bool computeHitAndDepth(in vec4 fragCoord, out Point3 worldPosition, out vec3 normal, out float depth) {

    float csEyeRayDirectionZ;

    Ray worldEyeRay = worldRay(fragCoord.xy, g3d_CameraToWorldMatrix, g3d_ProjInfo, csEyeRayDirectionZ);

    //transpose so the voxels rotate in the same direction as the model
    Box box = Box(boxCenter, vec3(voxelRadius), vec3(invVoxelRadius), Matrix3(g3d_WorldToObjectMatrix)
#if ANIMATION
        * mat3(yaw4x4(orientation) * pitch4x4(orientation * 0.5))
#endif
    );
    
    float distance;

    if (! ourOutsideIntersectBox(box, worldEyeRay, distance, normal, true, vec3(0))) {
        return false;
    }

    float csZ = distance * csEyeRayDirectionZ;

    //Take from (-1,1) to (0,1), as we are using the projection matrix commonly used in the vertex shader, which does this automatically
    depth = (distance == inf) ? 1.0 : ((g3d_ProjectionMatrix[2][2] * csZ + g3d_ProjectionMatrix[3][2]) / -csZ) * 0.5 + 0.5; 

    worldPosition = worldEyeRay.direction * distance + worldEyeRay.origin;

    return true;
}
