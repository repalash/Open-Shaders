/**
  \file data-files/shader/AmbientOcclusion/AmbientOcclusion_packBilateralKey.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef AmbientOcclusion_packBilateralKey_glsl
#define AmbientOcclusion_packBilateralKey_glsl

#include <octahedral.glsl>

vec4 packBilateralKey(in float csZ, in vec3 normal, in float nearZ, in float farZ) {
    vec4 result;

    float normalizedZ = clamp(-(csZ - nearZ) / (nearZ - farZ), 0.0, 1.0);
    float temp = floor(normalizedZ * 255.0);
    result.x = temp / 255.0;
    result.y = (normalizedZ * 255.0) - temp;

    vec2 octNormal = octEncode(normal);
    // Pack to 0-1
    result.zw = octNormal * 0.5 + 0.5;


    return result;
}

void unpackBilateralKey(vec4 key, in float nearZ, in float farZ, out float zKey, out vec3 normal) {
    zKey = key.x + key.y * (1.0 / 256.0);
    normal = octDecode(key.zw * 2.0 - 1.0);
}

#endif