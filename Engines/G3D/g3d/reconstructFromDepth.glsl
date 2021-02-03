/**
  \file data-files/shader/reconstructFromDepth.glsl

  Routines for reconstructing linear Z, camera-space position, and camera-space face normals from a standard
  or infinite OpenGL projection matrix from G3D.

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef reconstructFromDepth_glsl
#define reconstructFromDepth_glsl
#include <g3dmath.glsl>
#include <compatibility.glsl>

#define ProjInfo vec4
//mat3x2

#ifndef g3dmath_glsl 
    // This is a temporary workaround for a complex compiler error with large shaders
    #define Point2 vec2
    #define Point3 vec3
    #define Vector3 vec3
    #define Vector4 vec4
    struct Ray {Point3 origin; Vector3 direction; };
    void swap(inout float a, inout float b) {
        float temp = a;
        a = b;
        b = temp;
    }

/** 32-bit floating-point infinity */
const float inf         = 
#if __VERSION__ >= 420
    // Avoid the 1/0 underflow warning (requires GLSL 400 or later):
    intBitsToFloat(0x7f800000);
#else
    1.0 / 0.0;
#endif
#endif

// Note that positions (which may affect z) are snapped during rasterization, but 
// attributes are not.

/* 
 Converts a depth buffer value to a camera-space Z value.

 \param clipInfo = (z_f == -inf()) ? Vector3(z_n, -1.0f, 1.0f) : Vector3(z_n * z_f,  z_n - z_f,  z_f);
 \sa G3D::Projection::reconstructFromDepthClipInfo
*/
float reconstructCSZ(float d, vec3 clipInfo) {
    return clipInfo[0] / (clipInfo[1] * d + clipInfo[2]);
}

/** 
 Converts a camera-space Z value to a depth buffer value.
*/
float depthBufferValue(float csZ, vec3 clipInfo) {
    return (csZ == -inf) ? 1.0 : 
        (csZ >= 0.0) ? 0.0 : 
        (clipInfo[0] - csZ * clipInfo[2]) / (csZ * clipInfo[1]);
}

/** Reconstruct camera-space C.xyz from screen-space S = (x, y) in
    pixels and camera-space z < 0.  Assumes that the upper-left pixel center
    is at (0.5, 0.5) [but that need not be the location at which the sample tap 
    was placed!]

    Costs 3 MADD.  Error is on the order of 10^-3 at the far plane, partly due to z precision.

    In C++ (not GLSL, which transposes the matrices!), compute projInfo as

    projInfo = Vector4(-2.0f / (width*P[0][0]), 
          -2.0f / (height*P[1][1]),
          ( 1.0f - P[0][2]) / P[0][0], 
          ( 1.0f - P[1][2]) / P[1][1])
    
    where P is the projection matrix that maps camera space points 
    to [-1, 1] x [-1, 1].  That is, Camera::getProjectUnit().

    \sa G3D::Projection::reconstructFromDepthProjInfo
*/
Point3 reconstructCSPosition(Point2 S, float z, ProjInfo projInfo) {
    return Point3((S.xy * projInfo.xy + projInfo.zw) * z, z);
}


Ray cameraRay(Point2 pixelPosition, ProjInfo projInfo) {
    Vector3 direction = normalize(reconstructCSPosition(pixelPosition, -1.0, projInfo));
    return Ray(Point3(0,0,0), direction);
}


/** 
  \param csRayZ is the z component of the camera-space ray direction.
    It is useful for computing a standard OpenGL depth buffer encoding of the ray hit position:

    \code
    float csZ = distToHit / csEyeRayDirectionZ;
    gl_FragDepth = (distToHit == inf) ? 1.0 : ((projectionMatrix22 * csZ + projectionMatrix23) / -csZ);
    \endcode
 */
Ray worldRay(Point2 pixelPosition, mat4x3 cameraToWorld, ProjInfo projInfo, out float csRayZ) {
    Ray ray = cameraRay(pixelPosition, projInfo);
    csRayZ = ray.direction.z;
    return Ray(cameraToWorld[3], mat3x3(cameraToWorld) * ray.direction);
}

/** Given pixel coordinates and camera data (e.g., g3d_CameraToWorldMatrix and g3d_ProjInfo or
    Camera.frame and Camera.projInfo),  returns the world space ray through the pixel position. 
    Pixel centers are at 0.5. */
Ray worldRay(Point2 pixelPosition, mat4x3 cameraToWorld, ProjInfo projInfo) {
    float ignore;
    return worldRay(pixelPosition, cameraToWorld, projInfo, ignore);
    //Ray ray = cameraRay(pixelPosition, projInfo);
    //return Ray(cameraToWorld[3], mat3x3(cameraToWorld) * ray.direction);
}


/** Helper for reconstructing camera-space P.xyz from screen-space S = (x, y) in
    pixels and hyperbolic depth. 
    
    \sa G3D::Projection::reconstructFromDepthClipInfo
    \sa G3D::Projection::reconstructFromDepthProjInfo
*/
vec3 reconstructCSPositionFromDepth(vec2 S, float depth, ProjInfo projInfo, vec3 clipInfo) {
    return reconstructCSPosition(S, reconstructCSZ(depth, clipInfo), projInfo);
}

/** Helper for the common idiom of getting world-space position P.xyz from screen-space S = (x, y) in
    pixels and hyperbolic depth. 
    */
vec3 reconstructWSPositionFromDepth(vec2 S, float depth, ProjInfo projInfo, vec3 clipInfo, mat4x3 cameraToWorld) {
    return cameraToWorld * vec4(reconstructCSPositionFromDepth(S, depth, projInfo, clipInfo), 1.0);
}

#if G3D_SHADER_STAGE == G3D_FRAGMENT_SHADER
/** Reconstructs screen-space unit normal from screen-space position */
vec3 reconstructCSFaceNormal(vec3 C) {
    return normalize(cross(dFdy(C), dFdx(C)));
}

vec3 reconstructNonUnitCSFaceNormal(vec3 C) {
    return cross(dFdy(C), dFdx(C));
}
#endif


/**
  \brief Ray march against thickened depth buffer surface.

  This is a set of four functions: castScreenSpaceRay1,
  castScreenSpaceRay2, castScreenSpaceRay3, castScreenSpaceRay4.  The
  number indicates the number of depth layers in the channels of the
  csZBuffer.

  \param jitterFraction Can be used to replace banding with noise when
  numSteps is small. A good value is the hash function
  fract(sin(gl_FragCoord.x * 12237.12 + gl_FragCoord.y * 21312.12))

  \param projectionMatrix The g3d_ProjectionMatrix for the camera that
  rendered the scene (not necessarily the current projection matrix,
  which may be orthographic for a deferred shading pass)

  \param clipInfo The camera->projection().getProjectUnitMatrix() for
  the camera that rendered the scene (only needed if
  csZBufferIsHyperbolic is true)

  \param csZBufferIsHyperbolic If true, reconstructZ is invoked for
  every value read back from csZBuffer

  \param distance Input: maximum distance to trace. Output: distance
  to intersection.

  \param layerThickness Assumed thickness of the depth surface, in
  meters. Must be positive.  Very large values avoid missed
  intersections behind objects. Very small values avoid making objects
  appear too thick.

  \param numLayers Number of layers in csZBuffer, expressed in the
  color channels.

  \param s Actual steps taken by the ray trace, useful for fading out
  results as the step count limit is approached.

  \param If numLayers > 1, the index of the layer that was hit.

  \deprecated
  \see traceScreenSpaceRay1
*/
#for (int numLayers = 1; numLayers < 5; ++numLayers)
bool castScreenSpaceRay$(numLayers)
   (Point3          csOrigin, 
    Vector3         csDirection,
    mat4            projectionMatrix,
    sampler2D       csZBuffer,
    float2          csZBufferSize,
    float3          clipInfo,
    float           jitterFraction,
    const int       numSteps,
    out int         s,
    float           layerThickness,
    in float        maxRayTraceDistance,
    out float       actualRayTraceDistance,
    out Point2      hitTexCoord,
    out int         which,
    const in bool   csZBufferIsHyperbolic,
    float           GUARD_BAND_FRACTION_X,
    float           GUARD_BAND_FRACTION_Y) {

    // Current point on the reflection ray in camera space
    Point3 P = csOrigin;

    // Pixel space origin
    int2 psOrigin;

    {
        float4 temp = projectionMatrix * vec4(csOrigin, 1.0);

        // Texture space origin: Homogeneous division and remap to [0,1]
        Point2 tsOrigin = (temp.xy * (1.0 / temp.w)) * 0.5 + 0.5;
        psOrigin = int2(csZBufferSize * tsOrigin);
    }

    // Camera space distance for each ray-march step
    float stepDistance = maxRayTraceDistance / numSteps;
    
    // Off screen
    hitTexCoord = vec2(-1, -1);

    // Amount that P increments by for every step
    vec3  PInc  = csDirection * stepDistance;

    P += PInc * (jitterFraction + 0.5);
    which = -1;

    // Take to projective space and perform ray march there
    Vector4 projPInc = projectionMatrix * Vector4(PInc, 0.0);
    Vector4 projP    = projectionMatrix * Vector4(P,    1.0);

    s = 0;
    for (s = 0; s < numSteps; ++s) {
        // float4 temp = projectionMatrix * vec4(P + PInc * s, 1.0);
        float4 temp = projP + projPInc * s;

        // texture space P: Homogeneous division and remap to [0,1]
        float2 tsP = (temp.xy * (1.0 / temp.w)) * 0.5 + 0.5;
        
        // Break early if off screen
        if (tsP.x < 0 || tsP.y < 0 || tsP.x > 1 || tsP.y > 1) {  break; }

        // Pixel space P
        int2 psP = int2(csZBufferSize * tsP);
        
        // Don't test against the start pixel
        if (psP == psOrigin) { continue; }

        // The depth range that the ray covers within this loop iteration
        float rayZMin = csOrigin.z + PInc.z * (s - 0.5);
        float rayZMax = csOrigin.z + PInc.z * (s + 0.5);
        if (rayZMin > rayZMax) { swap(rayZMin, rayZMax); }

        // Camera space z of the background at each layer
        float4 sceneZMax = texelFetch(csZBuffer, psP, 0);

        if (csZBufferIsHyperbolic) {
#           for (int layer = 0; layer < $(numLayers); ++layer)
                sceneZMax[$(layer)] = reconstructCSZ(sceneZMax[$(layer)], clipInfo);
#           endfor
        }
        float4 sceneZMin = sceneZMax - layerThickness;

        // Proper ray-plane will fix bands of holes.
        // Interpolating the ray hit will fix banded texture.

        // Use a macro instead of a real for loop because we need to use a BREAK statement below
#       for (int layer = 0; layer < $(numLayers); ++layer)
            // (As an optimization, break out of the loop here but don't handle the result until outside the loop)
            // Do the intervals overlap?
            if ((rayZMax >= sceneZMin[$(layer)]) &&
                (rayZMin <= sceneZMax[$(layer)])) {

                // Hit...or off screen
                hitTexCoord = tsP;
                which = $(layer);
                break;
            }
#       endfor
    }

    actualRayTraceDistance = (s + jitterFraction) * stepDistance;
    // The hit texcoord was initialized to -1, so only if it is valid was there a hit
    return 
        (hitTexCoord.y >= GUARD_BAND_FRACTION_Y) && (hitTexCoord.x >= GUARD_BAND_FRACTION_X) && 
        (hitTexCoord.x <= 1.0 - GUARD_BAND_FRACTION_X) && (hitTexCoord.y <= 1.0 - GUARD_BAND_FRACTION_Y);
}
#endfor



#if 0
void iterateAlongLine(Point2 P0, Point2 P1) {
	Vector2 delta = P1 - P0;

	// Assume horizontal
	mat2x2 permute = mat2x2(1, 0, 0, 1);

	if (abs(delta.x) < abs(delta.y)) {
		// More-vertical line
		permute = mat2x2(0,1,1,0);
		delta = permute * delta;
		P1 = permute * P1;
		P0 = permute * P0;
	}

	// From now on, "x" is the primary iteration direction and "y" is the secondary one
	if (delta.x == 0.0) {
		// This is a single point
		PROCESS_PIXEL(P0);
		return;
	}

	// Guaranteed that delta.x is non-zero
	float slope = delta.y / delta.x;

	// Flip endpoints if needed to make the primary iteration direction positive.
	// We don't need (delta =- delta) because delta is never used again, and we don't
	// need to invert slope because negating both numerator and denominator cancels.
	if (delta.x < 0.0) { Point2 temp = P1; P1 = P0; P0 = temp; }

	// Slide P from P0 to P1
	for (Point2 P = P0; P.x <= P1.x; P += Vector2(1.0, slope)) {
		PROCESS_PIXEL(permute * P);
	}
}
#endif

#endif
