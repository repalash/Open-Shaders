/**
  \file data-files/shader/lightMap.glsl

  Include into your shader to access the radiosityNormalMap(lightMap0, lightMap1, lightMap2, lightCoord, tsN) function, 
  which returns a radiance sample from the Radiosity Normal Map specified by the first three parameters.

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef G3D_lightMap_glsl
#define G3D_lightMap_glsl

/** 
 "radiosity normal map" (actually more like an irradiance map) used by Unreal Engine 3 and Source Engine.  Uses the Half-Life 2 basis.
  For more on radiosity normal maps, see http://www2.ati.com/developer/gdc/D3DTutorial10_Half-Life2_Shading.pdf.
 */
vec3 radiosityNormalMap(in sampler2D lightMap0, in sampler2D lightMap1, in sampler2D lightMap2, in vec2 lightCoord, in vec3 tsN) {
    const float invRootSix = 1.0 / sqrt(6.0);
    const float invRootTwo = 1.0 / sqrt(2.0);
    const float invRootThree = 1.0 / sqrt(3.0);
    const float rootTwoThirds = sqrt(2.0 / 3.0);

    const vec3 m0 = vec3(-invRootSix, invRootTwo, invRootThree);
    const vec3 m1 = vec3(-invRootSix, -invRootTwo, invRootThree);
    const vec3 m2 = vec3(rootTwoThirds, 0, invRootThree);
    
    // Clamped dot products against the normal vector; treat the light maps similarly to
    float c0 = max(dot(m0, tsN), 0.0);
    float c1 = max(dot(m1, tsN), 0.0);
    float c2 = max(dot(m2, tsN), 0.0);

    // Square all values
    c0 *= c0;
    c1 *= c1;
    c2 *= c2;
    
    return (c0 * texture(lightMap0, lightCoord).rgb + c1 * texture(lightMap1, lightCoord).rgb 
						    + c2 * texture(lightMap2, lightCoord).rgb) / (c0 + c1 + c2);
}

#endif
