/**
  \file data-files/shader/SVO/SVO_base.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef SVO_base_glsl
#define SVO_base_glsl

#include <g3dmath.glsl>

/*#ifdef SVO_USE_NEIGHBOR_POINTERS
#undef SVO_USE_NEIGHBOR_POINTERS
#endif
#define SVO_USE_NEIGHBOR_POINTERS 0*/

//////////////////////CONFIG//////////////////////
#define SVO_USE_STANDARD								1
#define SVO_USE_BLOCK_TRACE								0
#define SVO_USE_TEXTURE_SHADER							0

#define SVO_USE_TEXTURE_FILTERING						SVO_USE_BRICKS
//#define SVO_USE_TEXTURE_FILTERING						0
#define SVO_VOXEL_POOL_USE_ZCURVE						1		//Improve cache coherency at the cost of bit swizzling for each sample


#define SVO_USE_NODE_CACHE								0
#define SVO_NODE_CACHE_SWITCH_STATE						0	//Mode where the thread switch state

#define SVO_SAMPLE_TRILINEAR							0	//SW interpolation
#define SVO_SAMPLE_QUADLINEAR							0
#define SVO_SAMPLE_NEAREST_MIPMAP						0	//MipMap unfiltered values (Use nearest with MipMapping)

#define SVO_SAMPLE_PREMULT_BY_ALPHA						0	//Software alpha premultiplication. Works only with SW interp.

#define SVO_ENABLE_VOXEL_FETCH							1
#define SVO_USE_DEBUG_SHADING							1

#define SVO_EMPTY_SPACE_SKIPPING						1

#define SVO_TRACING_REGOPTIM_SHAREDMEM					0

#define SVO_TRACING_USE_MULTITHREADS_TRAVERSAL			0
#define SVO_TRACING_USE_WARP_COLLAB_TRAVERSAL			0

#define SVO_HACK_COLOR_FROM_LEVEL						0

/////////////
#define SVO_TRAVERSE_SHIFT_OPTIM						1
#define SVO_TRAVERSE_NODEIDX_OPTIM						1
#define SVO_TRAVERSE_FETCH_THROUGH_TEX					1

#define SVO_SAMPLING_OPTIM_MAX_INSTR_PARALLELISM		1	//Maximize instruction parallelism


//Deprecated: was used by SGGX for disabling the fetch of some channels.
bool enableFetchCov;


//////////////////////////////////////////////////

#define VOXEL_TAU_BASE_DISTANCE		(1.0f/2048.0f)
#define SVO_REF_MAX_LEVEL						12

#define SVO_LEVEL_VAR_TYPE						int

#ifdef __CUDACC__
# define SVO_COORD_BASE_TYPE					ushort //ivec3
# define SVO_COORD_VAR_TYPE						usvec3 //ivec3
#else
# define SVO_COORD_BASE_TYPE					int //
# define SVO_COORD_VAR_TYPE						ivec3 //
#endif

#ifndef SVO_TRACING_BLOCK_SIZE_X
# define SVO_TRACING_BLOCK_SIZE_X WORK_GROUP_SIZE_X
#endif
#ifndef SVO_TRACING_BLOCK_SIZE_Y
# define SVO_TRACING_BLOCK_SIZE_Y WORK_GROUP_SIZE_Y
#endif
#ifndef SVO_TRACING_BLOCK_SIZE
#define SVO_TRACING_BLOCK_SIZE (SVO_TRACING_BLOCK_SIZE_X*SVO_TRACING_BLOCK_SIZE_Y)
#endif

#ifndef NULL
# define NULL (0)
#endif

/** Location of the root node in the childIndexBuffer */
//const int               ROOT_LOCATION = 8;
const uint              POPULATED = 0xFFFFFFFF;


#define gl_WorkGroupIndex (gl_WorkGroupID.x+gl_WorkGroupID.y*gl_NumWorkGroups.x)	//2D only

////////////CUDA Compatibility//////////////
#ifndef GLSL_FUNC_DEC
# define GLSL_FUNC_DEC
#endif

#ifndef GLSL_GLOBAL_LOAD
# define GLSL_GLOBAL_LOAD(address) (*(address))
#endif

#ifndef GLSL_DEC_GLOBAL_VAR
# define GLSL_DEC_GLOBAL_VAR(type) type
#endif

#ifndef GLSL_OUT_PARAM
# define GLSL_OUT_PARAM(type) \
	out type
#endif

#ifndef GLSL_INOUT_PARAM
# define GLSL_INOUT_PARAM(type) \
	inout type
#endif

#ifndef GLSL_SHARED_VAR
# define GLSL_SHARED_VAR shared
#endif

#ifndef GLSL_UNIFORM_VAR
# define GLSL_UNIFORM_VAR uniform
#endif

////////////////////////////////////////
#include <SVO/SVO_util.glsl>
////////////////////////////////////////

#if SVO_USE_NEIGHBOR_POINTERS
GLSL_UNIFORM_VAR uint*					d_neighborsIndexBuffer;
#endif

GLSL_UNIFORM_VAR float	svoMinVoxelSize;
GLSL_UNIFORM_VAR int	svoMaxLevel;


////////////////////////////////////////

int svoGetRootBufferIndex(int svoID, int level){
	svoID = (svoID%SVO_MAX_NUM_VOLUMES);

	//Mode 1 : compatibility
	return svoID + level*SVO_MAX_NUM_VOLUMES;

	//Mode 2
	//return svoID*SVO_TOP_MIPMAP_NUM_LEVELS + level;
	//return level;		//Optim when only 1 svo
}

uint svoGetRootLocation(int svoID, int level = 1){
	//return 8;

	//return d_rootIndexBuffer[ svoGetRootBufferIndex(svoID, level)  ];
	return texelFetch(rootIndexBufferTex, svoGetRootBufferIndex(svoID, level) ).x;
}

void svoSetRootLocation(int svoID, int nodeIdx, int level){
	
	d_rootIndexBuffer[ svoGetRootBufferIndex(svoID, level)  ] = nodeIdx;
}
void svoSetRootLocation(int svoID, uint nodeIdx, int level){
	
	d_rootIndexBuffer[ svoGetRootBufferIndex(svoID, level)  ] = nodeIdx;
}



ivec3 svoGBufferCoordsFromBrickIdx(uint nodeIdx){

	int brickIdx=int(nodeIdx>>3);

	ivec3 outCoord;
	outCoord.x = brickIdx%SVO_VOXELPOOL_RES_BRICK_X;
	outCoord.y = (brickIdx/SVO_VOXELPOOL_RES_BRICK_X)%SVO_VOXELPOOL_RES_BRICK_Y;
	outCoord.z = brickIdx/(SVO_VOXELPOOL_RES_BRICK_X*SVO_VOXELPOOL_RES_BRICK_Y);

	outCoord = outCoord * SVO_BRICK_RES_WITH_BORDER;

	outCoord = outCoord + ivec3(SVO_BRICK_BORDER_OFFSET);

	return outCoord;
}


//Bottom-up coordinates calculation
vec3 svoGetPositionFromLevelIndex(int level, int index){

	// Current node (initially the root)
    int nodeIndex = index;

	// We begin at the center of a unit cube
    vec3  pos = vec3(0.0, 0.0, 0.0);

    float radius = pow(0.5, level);
	float curRadius = radius;
	radius*=0.5;

	 //Bottom-up traversal
	 for (int curLevel = level; (nodeIndex != NULL)  && (curLevel > 0); curLevel--) 
	 {
        // Every three bits describe one level, where the LSB are level 0 in the form (zyx)
        int offset = nodeIndex & 7;
 
        // Move the center following the bits
        vec3 step = vec3(float(offset & 1), float((offset >> 1) & 1), float((offset >> 2) & 1));

		pos += step * curRadius;
		curRadius *= 2.0;
	
        // Advance into the child
        nodeIndex = int(imageLoad(parentIndexBuffer, nodeIndex/8 ).r);
    }

	return pos;
}

GLSL_FUNC_DEC
float getRayNodeLength(vec3 posInNode, float nsize, vec3 rayDir){
#if 1
    vec3 directions = step(0.0f, rayDir);

    //vec3 planes=directions*(nsize-posInNode);
	vec3 planes=directions*(nsize);
    vec3 miniT=(planes-posInNode)/rayDir;

    return min(miniT.x, min(miniT.y, miniT.z));  // *length(rayDir);
#else
	//v0

# if 0
	vec3 aabbMin=vec3(0.0f);
	vec3 aabbMax=vec3(nsize);

	float boxInterMin=0.0f; float boxInterMax=0.0f;
    //bool hit=IntersectBox(r, aabb, boxInterMin, boxInterMax);

	/*vec3 invR = vec3(1.0f, 1.0f, 1.0f) / rayDir;
	vec3 tbot = invR * (aabbMin-posInNode);
	vec3 ttop = invR * (aabbMax-posInNode);
	vec3 tmin = min(ttop, tbot);
	vec3 tmax = max(ttop, tbot);

	float t0; float t1;

	t0 = max(tmin.x, max(tmin.y, tmin.z));
	t1 = min(tmax.x, min(tmax.y, tmax.z));



	//return max(t0, t1)*1.0f;
	if(t0>0.0f)
		return t0;
	else
		return t1;*/
	Ray r; 
	r.origin=posInNode;
	r.dir=rayDir;

	vec3 OMIN = ( aabbMin - r.origin ) / r.dir;
    vec3 OMAX = ( aabbMax - r.origin ) / r.dir;
    
    vec3 MAX = max ( OMAX, OMIN );
    
    return min ( MAX.x, min ( MAX.y, MAX.z ) );


# else

	Ray r; AABB aabb;
	r.origin=posInNode;
	r.dir=rayDir;
	aabb.Min=vec3(0.0f);
	aabb.Max=vec3(nsize);

	float boxInterMin; float boxInterMax;
    bool hit=IntersectBox(r, aabb, boxInterMin, boxInterMax);

	if(hit)
		return max(boxInterMax, boxInterMin);
	else
		return 1.0f/8192.0f;

# endif

#endif

}

//Special for empty space skipping
GLSL_FUNC_DEC
float getEmptySpaceLength(vec3 posInNode, float nsize, vec3 rayDir){
#if 1
    vec3 directions = step(0.0f, rayDir);

    //vec3 planes=directions*(nsize-posInNode);
	vec3 planes=directions*(nsize);
    vec3 miniT=(planes-posInNode)/rayDir;

    return min(miniT.x, min(miniT.y, miniT.z));  // *length(rayDir);
#else
	//v0

# if 1
	vec3 aabbMin=vec3(0.0f);
	vec3 aabbMax=vec3(nsize);

	Ray r; 
	r.origin=posInNode;
	r.direction=rayDir;

# if 1	//Inside node
	vec3 OMIN = ( aabbMin - r.origin ) / r.direction;
    vec3 OMAX = ( aabbMax - r.origin ) / r.direction;
    vec3 MAX = max ( OMAX, OMIN );
    
    return min ( MAX.x, min ( MAX.y, MAX.z ) );
# else
	vec3 OMIN = ( aabbMin - r.origin ) / r.direction;
    vec3 OMAX = ( aabbMax - r.origin ) / r.direction;
    
    vec3 MAX = max ( OMAX, OMIN );
    vec3 MIN = min ( OMAX, OMIN );
    
    float final = min ( MAX.x, min ( MAX.y, MAX.z ) );
    float start = max ( max ( MIN.x, 0.0 ), max ( MIN.y, MIN.z ) );
	return final;
# endif

# else
	Ray r; AABB aabb;
	r.origin=posInNode;
	r.direction=rayDir;
	aabb.Min=vec3(0.0f);
	aabb.Max=vec3(nsize);

	float boxInterMin; float boxInterMax;
    bool hit=IntersectBox(r, aabb, boxInterMin, boxInterMax);

	if(hit)
		return max(boxInterMax, boxInterMin);
	else
		return 1.0f/8192.0f;


# endif

#endif
}


GLSL_FUNC_DEC
float svoGetDepthFromDist(float d, float raycastingConeFactor, GLSL_OUT_PARAM(float) voxelSize){

#if 0
	const float pixelAngle=radians( (70.0f/1024.0f)*1.0f );
	float viewConeFactor=tan( pixelAngle*0.25f ) * raycastingConeFactor *1.0f;
#else
	float viewConeFactor= raycastingConeFactor *1.0f;
#endif

	//float viewConeFactor=tan( pixelAngle )* raycastingConeFactor *0.04 * 1.0f/(projectionScale);
	//raycastingConeFactor*1.0f/4096.0f * 1.0f/projectionScale
	//float viewConeFactor=1.0f/4096.0f * raycastingConeFactor;

	//voxelSize= max( d * viewConeFactor , svoMinVoxelSize ); //Clamping
	voxelSize= d * viewConeFactor; //No clamping done

	//voxelSize= max( t*viewConeFactor*100.0f, svoMinVoxelSize ); //
	//voxelSize= 4.0f/1024.0f; //


	float targetDepthF=log2(1.0f/voxelSize);


	return targetDepthF;
}

GLSL_FUNC_DEC
float svoGetDepthFromDist(float d, float raycastingConeFactor){
	float voxelSize;
	return svoGetDepthFromDist(d, raycastingConeFactor, voxelSize);
}

////

#ifdef GBUFFER_svo
struct SampleStruct {

#   foreach(NAME, name) in(WS_NORMAL, normal), (CS_NORMAL, csNormal), (WS_FACE_NORMAL, faceNormal), (CS_FACE_NORMAL, csFaceNormal), (WS_POSITION, wsPosition), (CS_POSITION, csPosition), (LAMBERTIAN, lambertian), (GLOSSY, glossy), (TRANSMISSIVE, transmissive), (EMISSIVE, emissive), (CS_POSITION_CHANGE, csPosChange), (SS_POSITION_CHANGE, ssPosChange), (CS_Z, csZ), (DEPTH_AND_STENCIL, depthStencil), (TS_NORMAL, tsNormal), (SVO_POSITION, svoPos), (SVO_COVARIANCE_MAT1, cov1), (SVO_COVARIANCE_MAT2, cov2)
#       ifdef GBUFFER_CHANNEL_svo_$(NAME)
	vec4 $(name);
#       endif
#   endforeach

};


GLSL_FUNC_DEC 
void svoAccumSampleStruct(GLSL_INOUT_PARAM(SampleStruct) newCol, SampleStruct res, float scale){

#   foreach (NAME, structField) in (WS_NORMAL, normal), (CS_NORMAL, csNormal), (WS_FACE_NORMAL, faceNormal), (CS_FACE_NORMAL, csFaceNormal), (WS_POSITION, wsPosition), (CS_POSITION, csPosition), (LAMBERTIAN, lambertian), (GLOSSY, glossy), (TRANSMISSIVE, transmissive), (EMISSIVE, emissive), (CS_POSITION_CHANGE, csPosChange), (SS_POSITION_CHANGE, ssPosChange), (CS_Z, csZ), (DEPTH_AND_STENCIL, depthStencil), (TS_NORMAL, tsNormal), (SVO_POSITION, svoPos), (SVO_COVARIANCE_MAT1, cov1), (SVO_COVARIANCE_MAT2, cov2)
#   ifdef GBUFFER_CHANNEL_svo_$(NAME)

	newCol.$(structField) = newCol.$(structField) + res.$(structField) * scale;

#   endif
#   endforeach

}

GLSL_FUNC_DEC 
void svoScaleSampleStruct(GLSL_INOUT_PARAM(SampleStruct) newCol, float scale){

#   foreach (NAME, structField) in (WS_NORMAL, normal), (CS_NORMAL, csNormal), (WS_FACE_NORMAL, faceNormal), (CS_FACE_NORMAL, csFaceNormal), (WS_POSITION, wsPosition), (CS_POSITION, csPosition), (LAMBERTIAN, lambertian), (GLOSSY, glossy), (TRANSMISSIVE, transmissive), (EMISSIVE, emissive), (CS_POSITION_CHANGE, csPosChange), (SS_POSITION_CHANGE, ssPosChange), (CS_Z, csZ), (DEPTH_AND_STENCIL, depthStencil), (TS_NORMAL, tsNormal), (SVO_POSITION, svoPos), (SVO_COVARIANCE_MAT1, cov1), (SVO_COVARIANCE_MAT2, cov2)
#   ifdef GBUFFER_CHANNEL_svo_$(NAME)

	newCol.$(structField) = newCol.$(structField) * scale;

#   endif
#   endforeach

}

GLSL_FUNC_DEC 
void svoCopySampleStruct(GLSL_INOUT_PARAM(SampleStruct) newCol, SampleStruct res, float scale){

#   foreach (NAME, structField) in (WS_NORMAL, normal), (CS_NORMAL, csNormal), (WS_FACE_NORMAL, faceNormal), (CS_FACE_NORMAL, csFaceNormal), (WS_POSITION, wsPosition), (CS_POSITION, csPosition), (LAMBERTIAN, lambertian), (GLOSSY, glossy), (TRANSMISSIVE, transmissive), (EMISSIVE, emissive), (CS_POSITION_CHANGE, csPosChange), (SS_POSITION_CHANGE, ssPosChange), (CS_Z, csZ), (DEPTH_AND_STENCIL, depthStencil), (TS_NORMAL, tsNormal), (SVO_POSITION, svoPos), (SVO_COVARIANCE_MAT1, cov1), (SVO_COVARIANCE_MAT2, cov2)
#   ifdef GBUFFER_CHANNEL_svo_$(NAME)

	newCol.$(structField) = res.$(structField) * scale;

#   endif
#   endforeach

}


GLSL_FUNC_DEC 
void svoClearSampleStruct(GLSL_INOUT_PARAM(SampleStruct) newCol){

#   foreach (NAME, structField) in (WS_NORMAL, normal), (CS_NORMAL, csNormal), (WS_FACE_NORMAL, faceNormal), (CS_FACE_NORMAL, csFaceNormal), (WS_POSITION, wsPosition), (CS_POSITION, csPosition), (LAMBERTIAN, lambertian), (GLOSSY, glossy), (TRANSMISSIVE, transmissive), (EMISSIVE, emissive), (CS_POSITION_CHANGE, csPosChange), (SS_POSITION_CHANGE, ssPosChange), (CS_Z, csZ), (DEPTH_AND_STENCIL, depthStencil), (TS_NORMAL, tsNormal), (SVO_POSITION, svoPos), (SVO_COVARIANCE_MAT1, cov1), (SVO_COVARIANCE_MAT2, cov2)
#   ifdef GBUFFER_CHANNEL_svo_$(NAME)

	newCol.$(structField) = vec4(0.0f);

#   endif
#   endforeach

}




ivec3 svoGBufferCoordsFromNodeIdx(uint nodeIdx, ivec3 brickOffset){
	
#if SVO_USE_BRICKS==0

# if GBUFFER_DIMENSION(svo) == 2

#  if SVO_VOXEL_POOL_USE_ZCURVE==0	//Simple
	//Linear
	ivec3 outCoord = ivec3(		int(nodeIdx & uint( GBUFFER_WIDTH_MASK(svo) )), 
								int( nodeIdx >> uint( GBUFFER_WIDTH_SHIFT(svo) ) ),
								0   //int(nodeIdx >> uint( GBUFFER_WIDTH_HEIGHT_SHIFT(svo) )) 
							);
#  else

	//Cache coherent

	/*int nodeIdxI=int(nodeIdx);
	int nodeIdx2=(nodeIdxI>>2);

	int xx= (nodeIdxI&1)		| (((nodeIdx2) & (GBUFFER_WIDTH_MASK(svo)>>1))<<1)  ;
	int yy= ((nodeIdxI&2)>>1)	| ((nodeIdx2 >> (GBUFFER_WIDTH_SHIFT(svo)-1))<<1)  ;


	ivec3 outCoord = ivec3(xx, yy, 0);*/

	ivec3 outCoord;
	outCoord.x=int(extractEvenBits(nodeIdx));
	outCoord.y=int(extractEvenBits(nodeIdx>>1));
	outCoord.z=0;

#  endif

# else

	ivec3 outCoord = ivec3(		int(nodeIdx & uint( GBUFFER_WIDTH_MASK(svo) )), 
								int( (nodeIdx >> uint( GBUFFER_WIDTH_SHIFT(svo) )) & uint( GBUFFER_HEIGHT_MASK(svo) ) ), 
								int(nodeIdx >> uint( GBUFFER_WIDTH_HEIGHT_SHIFT(svo) )) 
							);

# endif

	//SVO_USE_TOP_MIPMAP
	/*ivec3 outCoord;

	if( nodeIdx<(SVO_TOP_MIPMAP_RES*SVO_TOP_MIPMAP_RES*SVO_TOP_MIPMAP_RES) ){

		outCoord = ivec3(	int( nodeIdx & uint( SVO_TOP_MIPMAP_RES ) ), 
							int( (nodeIdx >> uint( SVO_TOP_MIPMAP_NUM_LEVELS )) & uint( SVO_TOP_MIPMAP_RES-1 ) ), 
							int( nodeIdx >> uint( SVO_TOP_MIPMAP_NUM_LEVELS*2 ) ) 
						);

	}else{

		outCoord = ivec3(		int(nodeIdx & uint( GBUFFER_WIDTH_MASK(svo) )), 
								int( (nodeIdx >> uint( GBUFFER_WIDTH_SHIFT(svo) )) 
#  if GBUFFER_DIMENSION(svo) == 3
								& uint( GBUFFER_HEIGHT_MASK(svo) ) ), 
								int(nodeIdx >> uint( GBUFFER_WIDTH_HEIGHT_SHIFT(svo) )) 
#  else
								),
								0
#  endif
						);
	}*/



#else
	/*int brickIdx = nodeIdx>>(SVO_BRICK_NUM_LEVELS*3);

	ivec3 outCoord;
	outCoord.x = brickIdx%SVO_VOXELPOOL_RES_BRICK_X;
	outCoord.y = (brickIdx/SVO_VOXELPOOL_RES_BRICK_X)%SVO_VOXELPOOL_RES_BRICK_Y;
	outCoord.z = brickIdx/(SVO_VOXELPOOL_RES_BRICK_X*SVO_VOXELPOOL_RES_BRICK_Y);

	outCoord=outCoord * SVO_BRICK_RES_WITH_BORDER;

	outCoord.x = outCoord.x + (nodeIdx								& (SVO_BRICK_RES-1));
	outCoord.y = outCoord.y + ((nodeIdx>>SVO_BRICK_NUM_LEVELS)		& (SVO_BRICK_RES-1));
	outCoord.z = outCoord.z + ((nodeIdx>>(SVO_BRICK_NUM_LEVELS*2))	& (SVO_BRICK_RES-1));

	outCoord = outCoord + ivec3(SVO_BRICK_BORDER_OFFSET);*/

	int nodeIdxI = int(nodeIdx);

	int brickIdx = nodeIdxI>>(3);

	ivec3 outCoord;
	outCoord.x = brickIdx%SVO_VOXELPOOL_RES_BRICK_X;
	outCoord.y = (brickIdx/SVO_VOXELPOOL_RES_BRICK_X)%SVO_VOXELPOOL_RES_BRICK_Y;
	outCoord.z = brickIdx/(SVO_VOXELPOOL_RES_BRICK_X*SVO_VOXELPOOL_RES_BRICK_Y);

	outCoord=outCoord * SVO_BRICK_RES_WITH_BORDER;

# if 1
	outCoord.x = outCoord.x + ((nodeIdxI			& (1))<<SVO_OCTREE_BIAS)	+brickOffset.x;
	outCoord.y = outCoord.y + (((nodeIdxI>>1)	& (1))<<SVO_OCTREE_BIAS)	+brickOffset.y;
	outCoord.z = outCoord.z + (((nodeIdxI>>2)	& (1))<<SVO_OCTREE_BIAS)	+brickOffset.z;

	outCoord = outCoord + ivec3(SVO_BRICK_BORDER_OFFSET);
# else

	outCoord.x = outCoord.x + ((nodeIdxI			& (1)));
	outCoord.y = outCoord.y + (((nodeIdxI>>1)	& (1)));
	outCoord.z = outCoord.z + (((nodeIdxI>>2)	& (1)));

# endif

#endif

	//ivec3 outCoord = ivec3(	int(nodeIdx & uint( GBUFFER_WIDTH_MASK(svo) )), 0, 0 );

	return outCoord;
}

SampleStruct svoFetchGBuffer(int nodeIndex, ivec3 brickOffset=ivec3(0)){

	SampleStruct res;
	if ((nodeIndex != 0) && (SVO_ENABLE_VOXEL_FETCH != 0) && 
#		ifdef GBUFFER_READ_ENABLED_svo
			true
#		else 
			false
#		endif
		)
	{

		ivec3 gbufferCoords=svoGBufferCoordsFromNodeIdx(nodeIndex, brickOffset);


#  if SVO_USE_TEXTURE_FILTERING==0
				
#   foreach(NAME, name) in (WS_NORMAL, normal), (CS_NORMAL, csNormal), (WS_FACE_NORMAL, faceNormal), (CS_FACE_NORMAL, csFaceNormal), (WS_POSITION, wsPosition), (CS_POSITION, csPosition), (LAMBERTIAN, lambertian), (GLOSSY, glossy), (TRANSMISSIVE, transmissive), (EMISSIVE, emissive), (CS_POSITION_CHANGE, csPosChange), (SS_POSITION_CHANGE, ssPosChange), (CS_Z, csZ), (DEPTH_AND_STENCIL, depthStencil), (TS_NORMAL, tsNormal), (SVO_POSITION, svoPos), (SVO_COVARIANCE_MAT1, cov1), (SVO_COVARIANCE_MAT2, cov2)
#       ifdef GBUFFER_CHANNEL_svo_$(NAME)
		res.$(name) = texelFetch( GBUFFER_TEX(svo, $(NAME)), GBUFFER_COORDS(svo, gbufferCoords), 0).rgba;
#       endif
#   endforeach


#  else

		vec3 gbufferCoordsF= GBUFFER_COORDS(svo, gbufferCoords);

#   foreach(NAME, name) in (WS_NORMAL, normal), (CS_NORMAL, csNormal), (WS_FACE_NORMAL, faceNormal), (CS_FACE_NORMAL, csFaceNormal), (WS_POSITION, wsPosition), (CS_POSITION, csPosition), (LAMBERTIAN, lambertian), (GLOSSY, glossy), (TRANSMISSIVE, transmissive), (EMISSIVE, emissive), (CS_POSITION_CHANGE, csPosChange), (SS_POSITION_CHANGE, ssPosChange), (CS_Z, csZ), (DEPTH_AND_STENCIL, depthStencil), (TS_NORMAL, tsNormal), (SVO_POSITION, svoPos), (SVO_COVARIANCE_MAT1, cov1), (SVO_COVARIANCE_MAT2, cov2)
#       ifdef GBUFFER_CHANNEL_svo_$(NAME)
		res.$(name) = textureLod( GBUFFER_TEX(svo, $(NAME)),
					(gbufferCoordsF + 0.5f) / vec3(SVO_VOXELPOOL_RES_X, SVO_VOXELPOOL_RES_Y, SVO_VOXELPOOL_RES_Z),
					0.0f).rgba;

#       endif
#   endforeach


#  endif


	}else{

#   foreach(NAME, name) in(WS_NORMAL, normal), (CS_NORMAL, csNormal), (WS_FACE_NORMAL, faceNormal), (CS_FACE_NORMAL, csFaceNormal), (WS_POSITION, wsPosition), (CS_POSITION, csPosition), (LAMBERTIAN, lambertian), (GLOSSY, glossy), (TRANSMISSIVE, transmissive), (EMISSIVE, emissive), (CS_POSITION_CHANGE, csPosChange), (SS_POSITION_CHANGE, ssPosChange), (CS_Z, csZ), (DEPTH_AND_STENCIL, depthStencil), (TS_NORMAL, tsNormal), (SVO_POSITION, svoPos), (SVO_COVARIANCE_MAT1, cov1), (SVO_COVARIANCE_MAT2, cov2)
#       ifdef GBUFFER_CHANNEL_svo_$(NAME)
		res.$(name) = vec4(0.0f);
#       endif
#   endforeach

	}

	return res;
}



SampleStruct svoSampleBrick(int nodeIndex, vec3 nodePos, vec3 targetPosF){

	SampleStruct res;

	if( (nodeIndex != 0) && (nodeIndex!=0xFFFFFFFF) ) //Could be moved earlier
	{
		vec3 posInNode= (targetPosF-nodePos);

		ivec3 brickIdx = svoGBufferCoordsFromBrickIdx(nodeIndex);
		vec3 brickPos=vec3(brickIdx);

		vec3 voxelPos= (brickPos+posInNode); 
		vec3 voxelPosInPool=voxelPos*vec3(1.0f/(SVO_VOXELPOOL_RES_X), 1.0f/(SVO_VOXELPOOL_RES_Y), 1.0f/(SVO_VOXELPOOL_RES_Z));
		
#   foreach(NAME, name) in (WS_NORMAL, normal), (CS_NORMAL, csNormal), (WS_FACE_NORMAL, faceNormal), (CS_FACE_NORMAL, csFaceNormal), (WS_POSITION, wsPosition), (CS_POSITION, csPosition), (LAMBERTIAN, lambertian), (GLOSSY, glossy), (TRANSMISSIVE, transmissive), (EMISSIVE, emissive), (CS_POSITION_CHANGE, csPosChange), (SS_POSITION_CHANGE, ssPosChange), (CS_Z, csZ), (DEPTH_AND_STENCIL, depthStencil), (TS_NORMAL, tsNormal), (SVO_POSITION, svoPos), (SVO_COVARIANCE_MAT1, cov1), (SVO_COVARIANCE_MAT2, cov2)
#       ifdef GBUFFER_CHANNEL_svo_$(NAME)

			//res.$(name) = textureLod( GBUFFER_TEX(svo, $(NAME)), GBUFFER_COORDS(svo, voxelPosInPool), 0.0f).rgba;
			res.$(name) = textureLod( GBUFFER_TEX(svo, $(NAME)), voxelPosInPool, 0.0f).rgba;
			

			//res.$(name) = textureLod( GBUFFER_TEX(svo, $(NAME)), GBUFFER_COORDS(svo, targetPosF*vec3(1.0f/1024.0f)), 0.0f).rgba;
			

			//res.$(name).a = 1.0f;
			//res.$(name) = vec4( clamp(voxelPosInPool/1.0f, vec3(0.0f), vec3(1.0f)), 1.0f);
			//res.$(name) = vec4( clamp(posInNode, vec3(0.0f), vec3(2.0f)), 1.0f);
			
#       endif
#   endforeach

	}else{ 
		//Could be moved earlier
#   foreach(NAME, name) in (WS_NORMAL, normal), (CS_NORMAL, csNormal), (WS_FACE_NORMAL, faceNormal), (CS_FACE_NORMAL, csFaceNormal), (WS_POSITION, wsPosition), (CS_POSITION, csPosition), (LAMBERTIAN, lambertian), (GLOSSY, glossy), (TRANSMISSIVE, transmissive), (EMISSIVE, emissive), (CS_POSITION_CHANGE, csPosChange), (SS_POSITION_CHANGE, ssPosChange), (CS_Z, csZ), (DEPTH_AND_STENCIL, depthStencil), (TS_NORMAL, tsNormal), (SVO_POSITION, svoPos), (SVO_COVARIANCE_MAT1, cov1), (SVO_COVARIANCE_MAT2, cov2)
#       ifdef GBUFFER_CHANNEL_svo_$(NAME)
		res.$(name) = vec4(0.0f);
#       endif
#   endforeach

	}

	return res;
}


#endif

#endif
