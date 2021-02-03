/**
  \file data-files/shader/reverseReprojection.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef temporalFilter_glsl
#define temporalFilter_glsl

#include <reconstructFromDepth.glsl>

/** Requires previousBuffer and previousDepthBuffer to be the same size as the output buffer

    Returns the reverse-reprojected value, and sets distance 
    to the WS distance from the expected WS reverse-reprojected position and the actual value.
*/
vec4 reverseReprojection(vec2 currentScreenCoord,  vec3 currentWSPosition, vec2 ssVelocity, sampler2D previousBuffer, 
                         sampler2D previousDepthBuffer, vec2 inverseBufferSize, vec3 clipInfo, ProjInfo projInfo, mat4x3 previousCameraToWorld, out float distance) {
    vec2 previousCoord  = currentScreenCoord - ssVelocity;
    vec2 normalizedPreviousCoord = previousCoord * inverseBufferSize;
    vec4 previousVal = texture(previousBuffer, normalizedPreviousCoord);

    float previousDepth = texture(previousDepthBuffer, normalizedPreviousCoord).r;
    vec3 wsPositionPrev = reconstructWSPositionFromDepth(previousCoord, previousDepth, projInfo, clipInfo, previousCameraToWorld);
    distance = length(currentWSPosition - wsPositionPrev);

    return previousVal;
}

/** Requires all input buffers to be the same size as the output buffer

    Returns the reverse-reprojected value from the closest layer, and sets distance 
    to the WS distance from the expected WS reverse-reprojected position and the actual value .
*/
vec4 twoLayerReverseReprojection(vec2 currentScreenCoord,  vec3 currentWSPosition, vec2 ssVelocity, sampler2D previousBuffer, 
                         sampler2D previousDepthBuffer, sampler2D peeledPreviousBuffer, sampler2D peeledPreviousDepthBuffer, vec2 inverseBufferSize,
                         vec3 clipInfo, ProjInfo projInfo, mat4x3 previousCameraToWorld, out float distance) {

    vec2 previousCoord  = currentScreenCoord - ssVelocity;
    vec2 normalizedPreviousCoord = previousCoord * inverseBufferSize;
    vec4 previousVal = texture(previousBuffer, normalizedPreviousCoord);
    
    float previousDepth = texture(previousDepthBuffer, normalizedPreviousCoord).r;
    vec3 wsPositionPrev = previousCameraToWorld * vec4(reconstructCSPosition(previousCoord, reconstructCSZ(previousDepth, clipInfo), projInfo), 1.0);
    distance = length(currentWSPosition - wsPositionPrev);

    float previousPeeledDepth = texture(peeledPreviousDepthBuffer, normalizedPreviousCoord).r;
    vec3 wsPositionPeeledPrev = reconstructWSPositionFromDepth(previousCoord, previousPeeledDepth, projInfo, clipInfo, previousCameraToWorld);
    float distPeeled = length(currentWSPosition - wsPositionPeeledPrev);

    if (distPeeled < distance) {
        distance = distPeeled;
        previousVal = texture(peeledPreviousBuffer, normalizedPreviousCoord);
    }

    return previousVal;

}


/** Requires all input buffers to be the same size as the output buffer

    Returns the reverse-reprojected value from the closest layer, and sets distance 
    to the WS distance from the expected WS reverse-reprojected position and the actual value.
*/
vec4 reverseReprojection(vec2 currentScreenCoord,  sampler2D depthBuffer, 
                         sampler2D ssVelocityBuffer, vec2 ssVReadMultiplyFirst, vec2 ssVReadAddSecond, 
                         sampler2D previousBuffer, sampler2D previousDepthBuffer, vec2 inverseBufferSize,
                         vec3 clipInfo, ProjInfo projInfo, 
                         mat4x3 cameraToWorld, mat4x3 previousCameraToWorld, out float distance) {
    ivec2 C = ivec2(currentScreenCoord);
    vec2 ssV = texelFetch(ssVelocityBuffer, C, 0).rg * ssVReadMultiplyFirst + ssVReadAddSecond;
    float depth = texelFetch(depthBuffer, C, 0).r;
    vec3 currentWSPosition = reconstructWSPositionFromDepth(currentScreenCoord, depth, projInfo, clipInfo, cameraToWorld);
    return reverseReprojection(currentScreenCoord, currentWSPosition, ssV, previousBuffer, 
                         previousDepthBuffer, inverseBufferSize, clipInfo, projInfo, previousCameraToWorld, distance);
    
}

/** Requires all input buffers to be the same size as the output buffer

    Returns the reverse-reprojected value, and sets distance 
    to the WS distance from the expected WS reverse-reprojected position and the actual value.
*/
vec4 twoLayerReverseReprojection(vec2 currentScreenCoord,  sampler2D depthBuffer, 
                         sampler2D ssVelocityBuffer, vec2 ssVReadMultiplyFirst, vec2 ssVReadAddSecond, 
                         sampler2D previousBuffer, vec2 previousBufferInverseSize, sampler2D previousDepthBuffer, 
                         sampler2D peeledPreviousBuffer, sampler2D peeledPreviousDepthBuffer, vec2 inverseBufferSize,
                         vec3 clipInfo, ProjInfo projInfo, 
                         mat4x3 cameraToWorld, mat4x3 previousCameraToWorld, out float distance) {
    ivec2 C = ivec2(currentScreenCoord);
    vec2 ssV = texelFetch(ssVelocityBuffer, C, 0).rg * ssVReadMultiplyFirst + ssVReadAddSecond;
    float depth = texelFetch(depthBuffer, C, 0).r;
    vec3 currentWSPosition = reconstructWSPositionFromDepth(currentScreenCoord, depth, projInfo, clipInfo, cameraToWorld);
    return twoLayerReverseReprojection(currentScreenCoord, currentWSPosition, ssV, previousBuffer, 
                         previousDepthBuffer, peeledPreviousBuffer, peeledPreviousDepthBuffer, inverseBufferSize,
                         clipInfo, projInfo, previousCameraToWorld, distance);

}

#endif