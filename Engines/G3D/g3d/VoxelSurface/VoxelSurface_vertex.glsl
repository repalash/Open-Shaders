/**
  \file data-files/shader/VoxelSurface/VoxelSurface_vertex.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#include <g3dmath.glsl>

// in meters
uniform float   voxelRadius;
uniform float   invVoxelRadius;
uniform vec2    halfScreenSize;

/** Position of the camera in object space (not voxel space) */
uniform Point3  osCameraPos;

in ivec3        position;

// in sRGB values
in Radiance4    color;

// Box to world
flat out Point3      boxCenter;

flat out float       voxelCoverage;
flat out Color3      voxelLambertian;

#define ANIMATION 0
#if ANIMATION
flat out float       orientation;
#endif


void computeVertexShaderOutputs(in Radiance4 color, in Point3 vsPosition, in float voxelRadius, out vec4 position, out float pointSize, out Color3 voxelLambertian) {
    
#if ANIMATION
    float hash = fract(sin(float(gl_VertexID) + vsPosition.x + vsPosition.y * 10 + vsPosition.z * 5) * 100);
    float animationMagnitude = max(0.0, sin(g3d_SceneTime)*10 - 5.0) * abs(cos(hash));
    vsPosition.y += cos(g3d_SceneTime * 0.5 + hash * pi * 2) * animationMagnitude;
    vsPosition.x += (hash - 0.5) * animationMagnitude * 2;
    vsPosition.z += cos(hash * 100) * animationMagnitude;
    orientation = hash * animationMagnitude * 3.0;
#endif


    // Gamma correct
    voxelLambertian = square(color.rgb);

    // To visualize vertex ID
    //    voxelLambertian = voxelLambertian * 0.001 + vec3(gl_VertexID / 1000000.0);

    voxelCoverage = color.a;
    float corner = voxelRadius * sqrt(3.0);

    // Because the position should be translated by the box diameter rather than radius.
    Point3 osPosition = vsPosition * voxelRadius * 2.0;

    
    // The closest vertex is at the center of the box...plus the distance to a corner
    float csZ = (g3d_ObjectToCameraMatrix * vec4(osPosition, 1.0)).z + corner;
    float pixelsPerMeter = 1.0 / (csZ * g3d_ProjInfo[0]);
    
    // In world space
    boxCenter   = g3d_ObjectToWorldMatrix[3] + Matrix3(g3d_ObjectToWorldMatrix) * osPosition;

    // Offset vector to move towards the camera so that z strictly moves backwards
    Vector3 osOffsetToFront = normalize(osCameraPos - osPosition) * corner;

    position = vec4(osPosition + osOffsetToFront, 1.0) * g3d_ObjectToScreenMatrixTranspose;

    // Diameter of voxel in worst case, from corner to diagonally opposite corner.
    // This is only a good estimate when the box is near the center of the screen,
    // since the box becomes uncentered on the projected point as we move towards the edge.
    pointSize = 4 * corner * pixelsPerMeter;

    if (pointSize > 30) {
        // For large voxels, compute optimal bounds
        Matrix4 M = g3d_ObjectToScreenMatrix;
        // Compute the projection of all voxel vertices:
        vec4 p = M * vec4(osPosition + osOffsetToFront, 1.0);
        vec2 lo = vec2(2);
        vec2 hi = vec2(-2);
        vec2 mean = vec2(0);
#       define PROJ(offset) {\
                vec4 temp = M * vec4(offset * voxelRadius + osPosition, 1.0); \
                temp.xy /= max(temp.w, 0.001); \
                mean += temp.xy; \
                lo = min(temp.xy, lo); hi = max(temp.xy, hi); \
            }
            PROJ(vec3(-1, -1, -1));
            PROJ(vec3(-1, -1, +1)); 
            PROJ(vec3(-1, +1, -1));
            PROJ(vec3(-1, +1, +1));
            PROJ(vec3(+1, -1, -1)); 
            PROJ(vec3(+1, -1, +1)); 
            PROJ(vec3(+1, +1, -1)); 
            PROJ(vec3(+1, +1, +1));
#       undef PROJ

        mean /= 8;
        vec2 m = max(abs(mean - lo), abs(mean - hi));
        m = m * halfScreenSize;

        float newPointSize = 1.5 * 2.0 * max(m.x, m.y);

        // Don't blow up near z = 0
        if (newPointSize < 2 * max(halfScreenSize.x, halfScreenSize.y)) {
            // Center on the box
            position = vec4(mean * position.w, position.zw);
            pointSize = newPointSize;
        }            
    }

    // Square area
    float stochasticCoverage = pointSize * pointSize;
    if ((stochasticCoverage < 0.8) &&
        ((gl_VertexID & 0xffff) > stochasticCoverage * (0xffff / 0.8))) {
        // "Cull" small voxels in a stable, stochastic way by moving past the z = 0 plane.
        // Assumes voxels are in randomized order.
        position = vec4(-1,-1,-1,-1);
    }
}
