/**
  \file data-files/shader/SVO/SVO_util.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef SVO_util_glsl
#define SVO_util_glsl

#include <g3dmath.glsl>

#ifndef GLSL_FUNC_DEC
# define GLSL_FUNC_DEC
#endif
#ifndef GLSL_OUT_PARAM
# define GLSL_OUT_PARAM(type) \
	out type
#endif
#ifndef GLSL_INOUT_PARAM
# define GLSL_INOUT_PARAM(type) \
	inout type
#endif

struct AABB {
	vec3 Min;
	vec3 Max;
};



GLSL_FUNC_DEC
bool IntersectBox(Ray r, const AABB aabb, GLSL_OUT_PARAM(float) t0, GLSL_OUT_PARAM(float) t1)
{
#if 1
	vec3 invR = vec3(1.0f, 1.0f, 1.0f) / r.direction;

	vec3 tbot = invR * (aabb.Min-r.origin);
	vec3 ttop = invR * (aabb.Max-r.origin);
	vec3 tmin = min(ttop, tbot);
	vec3 tmax = max(ttop, tbot);
	vec2 t = max(vec2(tmin.x, tmin.x), vec2(tmin.y, tmin.z));
	t0 = max(t.x, t.y);
	t = min(vec2(tmax.x, tmax.x), vec2(tmax.y, tmax.z));
	t1 = min(t.x, t.y);

	return t0 <= t1;
#else
	vec3 minimum = aabb.Min;
	vec3 maximum = aabb.Max;

	vec3 OMIN = ( minimum - r.origin ) / r.dir;

	vec3 OMAX = ( maximum - r.origin ) / r.dir;

	vec3 MAX = max ( OMAX, OMIN );

	vec3 MIN = min ( OMAX, OMIN );

	t1 = min ( MAX.x, min ( MAX.y, MAX.z ) );

	t0 = max ( max ( MIN.x, 0.0 ), max ( MIN.y, MIN.z ) );

	return t1 > t0;
#endif

}

#if SVO_USE_TOP_DENSE
int svoTopDenseTreeGetLevelNumNodes(int level){
	return 1<<(level*3);
}

int svoTopDenseTreeGetLevelNumBlocks(int level){
	
	level = (level<1) ? 0 : level-1;

	return 1<<(level*3);
}
#endif


vec3 getVolSpacePosOnScreen(vec2 pixelCoordF, vec2 renderRes, float focalLength, float screenRatio, mat4 modelViewMat){

	vec2 sampleScreenPos = (pixelCoordF) / renderRes;
	//sampleScreenPos += rayDirOffset;

	sampleScreenPos = (2.0 * sampleScreenPos - 1.0);		//Normalized clip space
	sampleScreenPos.y=-sampleScreenPos.y*screenRatio;


	vec3 rayDir;
	rayDir.xy = sampleScreenPos;
	rayDir.z = -focalLength;

	//vec4 rayDir4 =  ( vec4(rayDir, 1) * transpose(modelViewMat) ) ;
	vec4 rayDir4 =  ( modelViewMat * vec4(rayDir, 1) ) ;
	rayDir4 /= rayDir4.w;

	return rayDir4.xyz;
}

//Vectors
vec3 getVolSpaceDirFromPix(vec2 pixelCoordF, vec2 renderRes, float focalLength, float screenRatio, mat4 rotationScale){

	vec2 sampleScreenPos = (pixelCoordF) / renderRes;

	sampleScreenPos = (2.0 * sampleScreenPos - 1.0);		//Normalized clip coords
	sampleScreenPos.y=-sampleScreenPos.y*screenRatio;

	vec3 rayDir;
	rayDir.xy = sampleScreenPos;
	rayDir.z = -focalLength;

	return (inverse(transpose(rotationScale)) * vec4(rayDir, 0.0)).xyz;
}

vec3 getVolSpaceDirFromPix2(vec2 pixelCoordF, vec2 renderRes, float focalLength, float screenRatio, mat3x3 rotationScale){

	vec2 sampleScreenPos = (pixelCoordF) / renderRes;

	sampleScreenPos = (2.0 * sampleScreenPos - 1.0);		//Normalized clip coords
	sampleScreenPos.y = -sampleScreenPos.y*screenRatio;

	vec3 rayDir;
	rayDir.xy = sampleScreenPos;
	rayDir.z = -focalLength;

	return rotationScale * rayDir;
}


GLSL_FUNC_DEC
int svoTopMipMapLevelOffset(ivec3 coord, int level){    //New version !
     uint res;

#if 0
	 int numBits = max(0, level-1);

	 res = bitfieldExtract(coord.x, 1, numBits) | bitfieldExtract(coord.y, 1, numBits)<<numBits | bitfieldExtract(coord.z, 1, numBits)<<(numBits*2);
	 res = res<<3 | bitfieldExtract(coord.x, 0, 1) | bitfieldExtract(coord.y, 0, 1)<<1 | bitfieldExtract(coord.z, 0, 1)<<2;

	 //res = (coord.x & 0xFFFFFFFE) | ((coord.y & 0xFFFFFFFE)<<(level-1)) | ((coord.z & 0xFFFFFFFE)<<(level*2-2));
	 //res = (res<<2) | (coord.x&1) | ((coord.y&1)<<1) | ((coord.z&1)<<2);

	 /*uint mask = ((1<<level)-1) & 0xFFFFFFFE;

	 res = ((coord.x & mask)) | ((coord.y & mask)<<(level-1)) | ((coord.z & mask)<<(level*2-2));
	 res = (res<<2) | (coord.x&1) | ((coord.y&1)<<1) | ((coord.z&1)<<2);*/
#else
	 res = (interleaveBits( uvec3(coord) ) );
#endif

     return int(res);
}

#endif