/**
  \file data-files/shader/SVO/SVO_sampling.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef SVO_sampling_glsl
#define SVO_sampling_glsl
//Requires SVO.glsl to be included before

#ifndef assert 
#	define assert(x, y)
#endif

#include <SVO/SVO_base.glsl>
#include <SVO/SVO_traversal.glsl>

//#define SVO_USE_VARIABLE_SVO_ID		1
#ifdef SVO_USE_VARIABLE_SVO_ID
int svoCurrentSvoID;
#endif

SampleStruct svoTraverseSampleBrick(vec3 rayDir, SVO_LEVEL_VAR_TYPE targetLevel, vec3 samplePos, GLSL_OUT_PARAM(SVO_LEVEL_VAR_TYPE) outLevel);

//////////////////////////////////
void hackColorFromLevel(int targetLevel, inout vec4 val){

#if SVO_HACK_COLOR_FROM_LEVEL
	if(targetLevel == 10){
		val.rgb = vec3(1.0f, 0.0f, 0.0f);
	}else if(targetLevel == 9){
		val.rgb = vec3(0.0f, 1.0f, 0.0f);
	}else if(targetLevel == 8){
		val.rgb = vec3(0.0f, 0.0f, 1.0f);
	}else if(targetLevel == 7){
		val.rgb = vec3(1.0f, 1.0f, 0.0f);
	}else if(targetLevel == 6){
		val.rgb = vec3(1.0f, 0.0f, 1.0f);
	}/*else if(targetLevel == 5){
		val.rgb = vec3(1.0f,1.0f, 1.0f);
	}*/else{
		val.rgb = vec3(0.0f,0.0f, 0.0f);
	}


	val.rgb *=val.w;
#endif

}

/////////////////////////////////




#if SVO_USE_NEIGHBOR_POINTERS

GLSL_FUNC_DEC
int svoGetNodeNeighbor(int nodeIndex, const int dirMask, const int dirOffset){

	if( (nodeIndex & dirMask)==0 ){
		return nodeIndex + dirMask;
	}else{

		int nsTileIndex = (nodeIndex>>3) * SVO_NUM_NEIGHBOR_POINTERS;
		//int nsTileIndex = (nodeIndex>>3) << 2;

		//int ptrOffset= findMSB(dirMask);
		int ptrOffset= dirOffset; 
		int neighborTileIdx=int( GLSL_GLOBAL_LOAD(d_neighborsIndexBuffer+nsTileIndex+ptrOffset) );

		int neighborNodeIndex;

		if(neighborTileIdx!=0){
			int neighborNodeOffset = (nodeIndex&7) ^ dirMask;
			neighborNodeIndex = neighborTileIdx + neighborNodeOffset;
		}else{
			neighborNodeIndex=0;
		}

		return neighborNodeIndex;
	}
}

#endif




//requires svoFetchGBuffer
GLSL_FUNC_DEC SampleStruct svoFetchNode(SVO_LEVEL_VAR_TYPE targetLevel, SVO_COORD_VAR_TYPE targetPos, GLSL_OUT_PARAM(SVO_LEVEL_VAR_TYPE) outLevel){

	targetLevel -= SVO_OCTREE_BIAS;

#if SVO_USE_NODE_CACHE==0 || !defined(SVO_RAYCASTING_ENABLED)
	int nodeIndex=svoGetNodeIndex(targetLevel, targetPos>>SVO_COORD_BASE_TYPE(SVO_OCTREE_BIAS), outLevel);
#else

# if SVO_NODE_CACHE_SWITCH_STATE==0
	int nodeIndex=svoGetNodeIndexCached(targetLevel, targetPos>>SVO_OCTREE_BIAS, outLevel);
# else
	int nodeIndex=svoBlockCacheGetNodeIndex(targetLevel, targetPos>>SVO_OCTREE_BIAS, outLevel);	//NEW
# endif

#endif
	//int nodeIndex=svoGetNodeIndexBlock(targetLevel, targetPos);

	ivec3 brickOffset;
#if SVO_USE_BRICKS
	brickOffset = targetPos&(SVO_BRICK_RES/2-1);
#else
	brickOffset=ivec3(0);
#endif

	return svoFetchGBuffer(nodeIndex, brickOffset );
}

//Return nodeidx
GLSL_FUNC_DEC SampleStruct svoFetchNode(SVO_LEVEL_VAR_TYPE targetLevel, SVO_COORD_VAR_TYPE targetPos, GLSL_OUT_PARAM(SVO_LEVEL_VAR_TYPE) outLevel, GLSL_OUT_PARAM(int) outNodeIdx){

	targetLevel -= SVO_OCTREE_BIAS;

#if SVO_USE_NODE_CACHE==0 || !defined(SVO_RAYCASTING_ENABLED)
	int nodeIndex=svoGetNodeIndex(targetLevel, targetPos>>SVO_COORD_BASE_TYPE(SVO_OCTREE_BIAS), outLevel);
#else

# if SVO_NODE_CACHE_SWITCH_STATE==0
	int nodeIndex=svoGetNodeIndexCached(targetLevel, targetPos>>SVO_OCTREE_BIAS, outLevel);
# else
	int nodeIndex=svoBlockCacheGetNodeIndex(targetLevel, targetPos>>SVO_OCTREE_BIAS, outLevel);	//NEW
# endif

#endif
	//int nodeIndex=svoGetNodeIndexBlock(targetLevel, targetPos);

	ivec3 brickOffset;
#if SVO_USE_BRICKS
	brickOffset = targetPos&(SVO_BRICK_RES/2-1);
#else
	brickOffset=ivec3(0);
#endif

	outNodeIdx = nodeIndex;
	return svoFetchGBuffer(nodeIndex, brickOffset );
}

///////////////////////////////////////////////////////////

GLSL_FUNC_DEC 
SampleStruct svoSampleTrilinear_Standard(const vec3 rayDir, const SVO_LEVEL_VAR_TYPE level, const vec3 samplePos, GLSL_OUT_PARAM(SVO_LEVEL_VAR_TYPE) outLevel){
	int levelRes=1<<level;

	SVO_LEVEL_VAR_TYPE outLevelLoc;
	outLevel = 1;

	//Trilinear interpolation
	vec3 targetPosF=samplePos*float(levelRes)-0.5f;
	ivec3	targetPos = ivec3(targetPosF);
	/////////////////////////////////////////

	vec3 interp=targetPosF-vec3(targetPos);
	SampleStruct res000; SampleStruct res001; SampleStruct res010; SampleStruct res011; 
	SampleStruct res100; SampleStruct res101; SampleStruct res110; SampleStruct res111;

#if SVO_USE_NEIGHBOR_POINTERS==0
	res000 = svoFetchNode(level, targetPos, outLevelLoc); outLevel = max(outLevelLoc, outLevel);
	res001 = svoFetchNode(level, targetPos+ivec3(1, 0, 0), outLevelLoc); outLevel = max(outLevelLoc, outLevel);
	res010 = svoFetchNode(level, targetPos+ivec3(0, 1, 0), outLevelLoc); outLevel = max(outLevelLoc, outLevel);
	res011 = svoFetchNode(level, targetPos+ivec3(1, 1, 0), outLevelLoc); outLevel = max(outLevelLoc, outLevel);

	res100 = svoFetchNode(level, targetPos+ivec3(0, 0, 1), outLevelLoc); outLevel = max(outLevelLoc, outLevel);
	res101 = svoFetchNode(level, targetPos+ivec3(1, 0, 1), outLevelLoc); outLevel = max(outLevelLoc, outLevel);
	res110 = svoFetchNode(level, targetPos+ivec3(0, 1, 1), outLevelLoc); outLevel = max(outLevelLoc, outLevel);
	res111 = svoFetchNode(level, targetPos+ivec3(1, 1, 1), outLevelLoc); outLevel = max(outLevelLoc, outLevel);
#else
	SVO_LEVEL_VAR_TYPE targetLevel = level-SVO_OCTREE_BIAS;

	int nodeIndex=svoGetNodeIndex(targetLevel, targetPos>>SVO_OCTREE_BIAS, outLevelLoc);
	outLevel = max(outLevelLoc, outLevel);

	//Octree//
	res000 = svoFetchGBuffer(nodeIndex, ivec3(0));


	int nodeIndex2 = svoGetNodeNeighbor(nodeIndex, 0x1, 0);
	res001 = svoFetchGBuffer(nodeIndex2, ivec3(0) );

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex2, 0x2, 1);
	res011 = svoFetchGBuffer(nodeIndex2, ivec3(0) );

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex, 0x2, 1);
	res010 = svoFetchGBuffer(nodeIndex2, ivec3(0) );

	//Z
	nodeIndex = svoGetNodeNeighbor(nodeIndex, 0x4, 2);
	res100 = svoFetchGBuffer(nodeIndex, ivec3(0) );

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex, 0x1, 0);
	res101 = svoFetchGBuffer(nodeIndex2, ivec3(0) );

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex2, 0x2, 1);
	res111 = svoFetchGBuffer(nodeIndex2, ivec3(0) );

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex, 0x2, 1);
	res110 = svoFetchGBuffer(nodeIndex2, ivec3(0) );

#endif


#if SVO_SAMPLE_PREMULT_BY_ALPHA

#   foreach (NAME, structField) in (WS_NORMAL, normal)
#   ifdef GBUFFER_CHANNEL_svo_$(NAME)

	res000.$(structField).rgb *= res000.$(structField).a;
	res001.$(structField).rgb *= res001.$(structField).a;
	res010.$(structField).rgb *= res010.$(structField).a;
	res011.$(structField).rgb *= res011.$(structField).a;

	res100.$(structField).rgb *= res100.$(structField).a;
	res101.$(structField).rgb *= res101.$(structField).a;
	res110.$(structField).rgb *= res110.$(structField).a;
	res111.$(structField).rgb *= res111.$(structField).a;

#   endif
#   endforeach

#endif

	////////////////////////////////////////
	SampleStruct newCol00; SampleStruct newCol01; SampleStruct newCol0;
	SampleStruct newCol10; SampleStruct newCol11; SampleStruct newCol1;
	SampleStruct newCol;

#if SVO_USE_CUDA==0

#   foreach(NAME, structField) in(WS_NORMAL, normal), (CS_NORMAL, csNormal), (WS_FACE_NORMAL, faceNormal), (CS_FACE_NORMAL, csFaceNormal), (WS_POSITION, wsPosition), (CS_POSITION, csPosition), (LAMBERTIAN, lambertian), (GLOSSY, glossy), (TRANSMISSIVE, transmissive), (EMISSIVE, emissive), (CS_POSITION_CHANGE, csPosChange), (SS_POSITION_CHANGE, ssPosChange), (CS_Z, csZ), (DEPTH_AND_STENCIL, depthStencil), (TS_NORMAL, tsNormal), (SVO_POSITION, svoPos), (SVO_COVARIANCE_MAT1, cov1), (SVO_COVARIANCE_MAT2, cov2)
#   ifdef GBUFFER_CHANNEL_svo_$(NAME)

	newCol00.$(structField) = res000.$(structField) * (1.0f-interp.x)	+ res001.$(structField) * interp.x;
	newCol01.$(structField) = res010.$(structField) * (1.0f-interp.x)	+ res011.$(structField) * interp.x;
	newCol0.$(structField) = newCol00.$(structField) * (1.0f-interp.y) + newCol01.$(structField) * interp.y;

	newCol10.$(structField) = res100.$(structField) * (1.0f-interp.x)	+ res101.$(structField) * interp.x;
	newCol11.$(structField) = res110.$(structField) * (1.0f-interp.x)	+ res111.$(structField) * interp.x;
	newCol1.$(structField) = newCol10.$(structField) * (1.0f-interp.y) + newCol11.$(structField) * interp.y;

	newCol.$(structField)  = newCol0.$(structField) * (1.0f-interp.z) + newCol1.$(structField) * interp.z;

#   endif
#   endforeach

#else

	////////////////////////////////////////
	newCol00.normal = res000.normal * (1.0f-interp.x)	+ res001.normal * interp.x;
	newCol01.normal = res010.normal * (1.0f-interp.x)	+ res011.normal * interp.x;
	newCol0.normal = newCol00.normal * (1.0f-interp.y) + newCol01.normal * interp.y;

	newCol10.normal = res100.normal * (1.0f-interp.x)	+ res101.normal * interp.x;
	newCol11.normal = res110.normal * (1.0f-interp.x)	+ res111.normal * interp.x;
	newCol1.normal = newCol10.normal * (1.0f-interp.y) + newCol11.normal * interp.y;

	newCol.normal  = newCol0.normal * (1.0f-interp.z) + newCol1.normal * interp.z;
	//////////////////////////////////////

#endif

	return newCol;
}

//////////////////////////////////////
#if SVO_USE_NEIGHBOR_POINTERS

GLSL_FUNC_DEC 
void svoSampleNeighborsTrilinear(GLSL_INOUT_PARAM(SampleStruct) newCol, int nodeIndex, vec3 interp, float interpD){
	
#if SVO_SAMPLING_OPTIM_MAX_INSTR_PARALLELISM==0	//Optim registers
	SampleStruct res;

	//Neighbors//
	int nodeIndex2 = svoGetNodeNeighbor(nodeIndex, 0x1, 0);
	res = svoFetchGBuffer(nodeIndex2, ivec3(0) );
	svoAccumSampleStruct(newCol, res, interp.x*(1.0f-interp.y)*(1.0f-interp.z) *interpD);

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex2, 0x2, 1);
	res = svoFetchGBuffer(nodeIndex2, ivec3(0) );
	svoAccumSampleStruct(newCol, res, interp.x*interp.y*(1.0f-interp.z) *interpD);

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex, 0x2, 1);
	res = svoFetchGBuffer(nodeIndex2, ivec3(0) );
	svoAccumSampleStruct(newCol, res, (1.0f-interp.x)*interp.y*(1.0f-interp.z) *interpD);

	//Z
	nodeIndex = svoGetNodeNeighbor(nodeIndex, 0x4, 2);
	res = svoFetchGBuffer(nodeIndex, ivec3(0) );
	svoAccumSampleStruct(newCol, res, (1.0f-interp.x)*(1.0f-interp.y)*interp.z *interpD);

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex, 0x1, 0);
	res = svoFetchGBuffer(nodeIndex2, ivec3(0) );
	svoAccumSampleStruct(newCol, res, interp.x*(1.0f-interp.y)*interp.z *interpD);

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex2, 0x2, 1);
	res = svoFetchGBuffer(nodeIndex2, ivec3(0) );
	svoAccumSampleStruct(newCol, res, interp.x*interp.y*interp.z *interpD);

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex, 0x2, 1);
	res = svoFetchGBuffer(nodeIndex2, ivec3(0) );
	svoAccumSampleStruct(newCol, res, (1.0f-interp.x)*interp.y*interp.z *interpD);
#else
	//Neighbors//
	int nodeIndex10 = svoGetNodeNeighbor(nodeIndex, 0x4, 2); //Z
	int nodeIndex1 = svoGetNodeNeighbor(nodeIndex, 0x1, 0);
	int nodeIndex2 = svoGetNodeNeighbor(nodeIndex, 0x2, 1);
	

	SampleStruct res10 = svoFetchGBuffer(nodeIndex10, ivec3(0) );
	SampleStruct res1 = svoFetchGBuffer(nodeIndex1, ivec3(0) );
	SampleStruct res2 = svoFetchGBuffer(nodeIndex2, ivec3(0) );
	

#if 1
	svoAccumSampleStruct(newCol, res1, interp.x*(1.0f-interp.y)*(1.0f-interp.z) *interpD);
	svoAccumSampleStruct(newCol, res2, (1.0f-interp.x)*interp.y*(1.0f-interp.z) *interpD);
	svoAccumSampleStruct(newCol, res10, (1.0f-interp.x)*(1.0f-interp.y)*interp.z *interpD);
#else
	SampleStruct res0;
	svoCopySampleStruct(res0, res1, interp.x*(1.0f-interp.y)*(1.0f-interp.z) *interpD);
	svoAccumSampleStruct(res0, res2, (1.0f-interp.x)*interp.y*(1.0f-interp.z) *interpD);
	svoAccumSampleStruct(res0, res10, (1.0f-interp.x)*(1.0f-interp.y)*interp.z *interpD);
#endif

	int nodeIndex11 = svoGetNodeNeighbor(nodeIndex10, 0x1, 0);
	int nodeIndex13 = svoGetNodeNeighbor(nodeIndex10, 0x2, 1);
	int nodeIndex3 = svoGetNodeNeighbor(nodeIndex1, 0x2, 1);

	SampleStruct res11 = svoFetchGBuffer(nodeIndex11, ivec3(0) );
	SampleStruct res13 = svoFetchGBuffer(nodeIndex13, ivec3(0) );
	SampleStruct res3 = svoFetchGBuffer(nodeIndex3, ivec3(0) );

#if 1
	svoAccumSampleStruct(newCol, res11, interp.x*(1.0f-interp.y)*interp.z *interpD);
	svoAccumSampleStruct(newCol, res13, (1.0f-interp.x)*interp.y*interp.z *interpD);
	svoAccumSampleStruct(newCol, res3, interp.x*interp.y*(1.0f-interp.z) *interpD);
#else
	SampleStruct res00;
	svoCopySampleStruct(res00, res11, interp.x*(1.0f-interp.y)*interp.z *interpD);
	svoAccumSampleStruct(res00, res13, (1.0f-interp.x)*interp.y*interp.z *interpD);
	svoAccumSampleStruct(res00, res3, interp.x*interp.y*(1.0f-interp.z) *interpD);

	svoAccumSampleStruct(newCol, res0, 1.0f);
	svoAccumSampleStruct(newCol, res00, 1.0f);
#endif


	int nodeIndex12 = svoGetNodeNeighbor(nodeIndex11, 0x2, 1);
	SampleStruct res12 = svoFetchGBuffer(nodeIndex12, ivec3(0) );
	svoAccumSampleStruct(newCol, res12, interp.x*interp.y*interp.z *interpD);
	
#endif

}
#endif

GLSL_FUNC_DEC 
SampleStruct svoSampleTrilinear_StandardAccum(const vec3 rayDir, const SVO_LEVEL_VAR_TYPE level, const vec3 samplePos, GLSL_OUT_PARAM(SVO_LEVEL_VAR_TYPE) outLevel){
	int levelRes=1<<level;

	SVO_LEVEL_VAR_TYPE outLevelLoc;
	outLevel = 1;

	//Trilinear interpolation
	vec3	targetPosF=samplePos*float(levelRes)-0.5f;
	ivec3	targetPos = ivec3(targetPosF);
	/////////////////////////////////////////

	vec3 interp=targetPosF-vec3(targetPos);
	SampleStruct newCol;
	SampleStruct res;

#if 1 //SVO_USE_NEIGHBOR_POINTERS==0

	res = svoFetchNode(level, targetPos, outLevelLoc); outLevel = max(outLevelLoc, outLevel);
	//newCol.normal = res.normal * (1.0f-interp.x)*(1.0f-interp.y)*(1.0f-interp.z);
	svoCopySampleStruct(newCol, res, (1.0f-interp.x)*(1.0f-interp.y)*(1.0f-interp.z) );

	res = svoFetchNode(level, targetPos+ivec3(1, 0, 0), outLevelLoc); outLevel = max(outLevelLoc, outLevel);
	//newCol.normal += res.normal * interp.x*(1.0f-interp.y)*(1.0f-interp.z);
	svoAccumSampleStruct(newCol, res, interp.x*(1.0f-interp.y)*(1.0f-interp.z) );

	res = svoFetchNode(level, targetPos+ivec3(0, 1, 0), outLevelLoc); outLevel = max(outLevelLoc, outLevel);
	//newCol.normal += res.normal * (1.0f-interp.x)*interp.y*(1.0f-interp.z);
	svoAccumSampleStruct(newCol, res, (1.0f-interp.x)*interp.y*(1.0f-interp.z) );

	res = svoFetchNode(level, targetPos+ivec3(1, 1, 0), outLevelLoc); outLevel = max(outLevelLoc, outLevel);
	//newCol.normal += res.normal * interp.x*interp.y*(1.0f-interp.z);
	svoAccumSampleStruct(newCol, res, interp.x*interp.y*(1.0f-interp.z) );

	///

	res = svoFetchNode(level, targetPos+ivec3(0, 0, 1), outLevelLoc); outLevel = max(outLevelLoc, outLevel);
	//newCol.normal += res.normal * (1.0f-interp.x)*(1.0f-interp.y)*interp.z;
	svoAccumSampleStruct(newCol, res, (1.0f-interp.x)*(1.0f-interp.y)*interp.z );

	res = svoFetchNode(level, targetPos+ivec3(1, 0, 1), outLevelLoc); outLevel = max(outLevelLoc, outLevel);
	//newCol.normal += res.normal * interp.x*(1.0f-interp.y)*interp.z;
	svoAccumSampleStruct(newCol, res, interp.x*(1.0f-interp.y)*interp.z );

	res = svoFetchNode(level, targetPos+ivec3(0, 1, 1), outLevelLoc); outLevel = max(outLevelLoc, outLevel);
	//newCol.normal += res.normal * interp.x*interp.y*interp.z;
	svoAccumSampleStruct(newCol, res, (1.0f-interp.x)*interp.y*interp.z  );

	res = svoFetchNode(level, targetPos+ivec3(1, 1, 1), outLevelLoc); outLevel = max(outLevelLoc, outLevel);
	//newCol.normal += res.normal * (1.0f-interp.x)*interp.y*interp.z;
	svoAccumSampleStruct(newCol, res, interp.x*interp.y*interp.z );


	//newCol.lambertian = clamp(newCol.lambertian, vec4(0.0f), vec4(1.0f)); //Needed because of accumulation errors
	newCol.lambertian.a = clamp(newCol.lambertian.a, (0.0f), (1.0f)); //Needed because of accumulation errors

#else  //Not working
	SVO_LEVEL_VAR_TYPE targetLevel = level-SVO_OCTREE_BIAS;


	//Octree//
	int nodeIndex=svoGetNodeIndex(targetLevel, targetPos>>SVO_OCTREE_BIAS, outLevelLoc);
	outLevel = max(outLevelLoc, outLevel);
	res = svoFetchGBuffer(nodeIndex, ivec3(0));
	svoCopySampleStruct(newCol, res, (1.0f-interp.x)*(1.0f-interp.y)*(1.0f-interp.z) );
	
	if( (targetLevel-outLevel)<1 )
	{
		svoSampleNeighborsTrilinear(newCol, nodeIndex, interp, 1.0f);
	}
#endif


	return newCol;
}


//Sample with trilinear interpolation
GLSL_FUNC_DEC 
SampleStruct svoSampleTrilinear(vec3 rayDir, int level, vec3 samplePos, GLSL_OUT_PARAM(SVO_LEVEL_VAR_TYPE) outLevel){

#if 0 //SVO_USE_CUDA==0	//Deactivated
# ifdef SVO_OCTREETEX_MODE
	if(level > SVO_MAX_LEVEL)
	{
		SampleStruct res;
		res.normal.xyz = normalize(svo_triangle_normal);
		res.normal.a = 1.0f;

# if defined(GBUFFER_CHANNEL_svo_SVO_COVARIANCE_MAT1) && defined(GBUFFER_CHANNEL_svo_SVO_COVARIANCE_MAT2)
		initCovarianceFromNormal(res.normal.xyz,
									res.cov1.x, res.cov1.y, res.cov1.z,
									res.cov2.x, res.cov2.y, res.cov2.z);
		
		res.cov1.a = 1.0f;
		res.cov2.a = 1.0f;
# endif
		return res;
	}
#else
	if(level > SVO_MAX_LEVEL)
	{
		SampleStruct res;
		res.normal = vec4(0.0f);
# if defined(GBUFFER_CHANNEL_svo_SVO_COVARIANCE_MAT1) && defined(GBUFFER_CHANNEL_svo_SVO_COVARIANCE_MAT2)
		res.cov1 = vec4(0.0f);
		res.cov2 = vec4(0.0f);
# endif
		return res;
	}
# endif
#endif


	SampleStruct newCol;

#if SVO_TRACING_USE_MULTITHREADS_TRAVERSAL==0 && SVO_TRACING_USE_WARP_COLLAB_TRAVERSAL==0
# if SVO_NODE_CACHE_SWITCH_STATE==0
	//newCol = svoSampleTrilinear_Standard(rayDir, level, samplePos, outLevel);
	newCol = svoSampleTrilinear_StandardAccum(rayDir, level, samplePos, outLevel);
# else
	newCol = svoSampleTrilinear_SwitchState(rayDir, level, samplePos, outLevel);
# endif
#elif SVO_TRACING_USE_WARP_COLLAB_TRAVERSAL
	newCol = svoSampleTrilinear_CollabTraversal(rayDir, level, samplePos, outLevel);
#elif SVO_TRACING_USE_MULTITHREADS_TRAVERSAL
	newCol = svoSampleTrilinear_MultithreadTraversal(rayDir, level, samplePos, outLevel);
#endif


	return newCol;
}

GLSL_FUNC_DEC
SampleStruct svoSampleQuadlinear(vec3 rayDir, float targetDepthF, vec3 samplePos, GLSL_OUT_PARAM(SVO_LEVEL_VAR_TYPE) outLevel){

	SVO_LEVEL_VAR_TYPE level=(int)(targetDepthF);

	SVO_LEVEL_VAR_TYPE outLevelLoc; outLevel=1;

	//float interpD = 0.5f;
	float interpD = targetDepthF-float(level);
	SampleStruct newCol;

#if 1 //SVO_USE_NEIGHBOR_POINTERS==0	//Basic
	SampleStruct res = svoSampleTrilinear(rayDir, level, samplePos, outLevelLoc);
	svoCopySampleStruct(newCol, res, (1.0f-interpD) );

	if(outLevelLoc==level)
	{
		res = svoSampleTrilinear(rayDir, level+1, samplePos, outLevelLoc); outLevel = outLevelLoc;
		svoAccumSampleStruct(newCol, res, interpD );
	}else{
		outLevel = outLevelLoc;
	}
#else

	SVO_LEVEL_VAR_TYPE targetLevel = level-SVO_OCTREE_BIAS;
	int levelRes=1<<targetLevel;

	////Trilinear interpolation////
	vec3 targetPosF=samplePos*float(levelRes)-0.5f;
	SVO_COORD_VAR_TYPE	targetPos = SVO_COORD_VAR_TYPE(targetPosF);

	vec3 interp=targetPosF-vec3(targetPos);
	SampleStruct res;
	/////////////////////////////////////////

	
	////LEVEL 0////
	int nodeIndexToChildren=0;

	//Octree//
	int nodeIndex=svoGetNodeIndex(targetLevel, targetPos>>SVO_OCTREE_BIAS, outLevelLoc);
	outLevel = max(outLevelLoc, outLevel);
#if SVO_SAMPLING_OPTIM_MAX_INSTR_PARALLELISM==0
	res = svoFetchGBuffer(nodeIndex, ivec3(0));
	svoCopySampleStruct(newCol, res, (1.0f-interp.x)*(1.0f-interp.y)*(1.0f-interp.z) *(1.0f-interpD) );
#endif

	if( (targetLevel-outLevel)<1 )
	{


	////////////////////////////
	int targetLevel2 = targetLevel+1;
	int levelRes2=1<<targetLevel2;
	vec3 targetPosF2=samplePos*float(levelRes2)-0.5f;
	SVO_COORD_VAR_TYPE targetPos2 = SVO_COORD_VAR_TYPE (targetPosF2);


	SVO_COORD_VAR_TYPE targetPosDiff = (targetPos2>>1)-targetPos;
	char targetPosDiffI = (targetPosDiff.x&1) | (targetPosDiff.y&1)<<1 | (targetPosDiff.z&1)<<2;
	char offsetInTile2=(targetPos2.x&1) | ((targetPos2.y&1)<<1) | ((targetPos2.z&1)<<2);
	///////////////////////////

#if SVO_SAMPLING_OPTIM_MAX_INSTR_PARALLELISM==0
	if(targetPosDiffI==0)
		nodeIndexToChildren=nodeIndex;

	//Neighbors//
	int nodeIndex2 = svoGetNodeNeighbor(nodeIndex, 0x1, 0);
	res = svoFetchGBuffer(nodeIndex2, ivec3(0) );
	svoAccumSampleStruct(newCol, res, interp.x*(1.0f-interp.y)*(1.0f-interp.z) *(1.0f-interpD));
	
	if(targetPosDiffI==1)
		nodeIndexToChildren=nodeIndex2;

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex2, 0x2, 1);
	res = svoFetchGBuffer(nodeIndex2, ivec3(0) );
	svoAccumSampleStruct(newCol, res, interp.x*interp.y*(1.0f-interp.z) *(1.0f-interpD));
	
	if(targetPosDiffI==3)
		nodeIndexToChildren=nodeIndex2;

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex, 0x2, 1);
	res = svoFetchGBuffer(nodeIndex2, ivec3(0) );
	svoAccumSampleStruct(newCol, res, (1.0f-interp.x)*interp.y*(1.0f-interp.z) *(1.0f-interpD));
	
	if(targetPosDiffI==2)
		nodeIndexToChildren=nodeIndex2;

	//Z
	nodeIndex = svoGetNodeNeighbor(nodeIndex, 0x4, 2);
	res = svoFetchGBuffer(nodeIndex, ivec3(0) );
	svoAccumSampleStruct(newCol, res, (1.0f-interp.x)*(1.0f-interp.y)*interp.z *(1.0f-interpD));
	
	if(targetPosDiffI==4)
		nodeIndexToChildren=nodeIndex;

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex, 0x1, 0);
	res = svoFetchGBuffer(nodeIndex2, ivec3(0) );
	svoAccumSampleStruct(newCol, res, interp.x*(1.0f-interp.y)*interp.z *(1.0f-interpD));
	
	if(targetPosDiffI==5)
		nodeIndexToChildren=nodeIndex2;

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex2, 0x2, 1);
	res = svoFetchGBuffer(nodeIndex2, ivec3(0) );
	svoAccumSampleStruct(newCol, res, interp.x*interp.y*interp.z *(1.0f-interpD));
	
	if(targetPosDiffI==7)
		nodeIndexToChildren=nodeIndex2;

	nodeIndex2 = svoGetNodeNeighbor(nodeIndex, 0x2, 1);
	res = svoFetchGBuffer(nodeIndex2, ivec3(0) );
	svoAccumSampleStruct(newCol, res, (1.0f-interp.x)*interp.y*interp.z *(1.0f-interpD));
	
	if(targetPosDiffI==6)
		nodeIndexToChildren=nodeIndex2;
#else

	//Neighbors//
	int nodeIndex10 = svoGetNodeNeighbor(nodeIndex, 0x4, 2); //Z
	int nodeIndex1 = svoGetNodeNeighbor(nodeIndex, 0x1, 0);
	int nodeIndex2 = svoGetNodeNeighbor(nodeIndex, 0x2, 1);
	

	SampleStruct res10 = svoFetchGBuffer(nodeIndex10, ivec3(0) );
	SampleStruct res1 = svoFetchGBuffer(nodeIndex1, ivec3(0) );
	SampleStruct res2 = svoFetchGBuffer(nodeIndex2, ivec3(0) );


	res = svoFetchGBuffer(nodeIndex, ivec3(0));
	svoCopySampleStruct(newCol, res, (1.0f-interp.x)*(1.0f-interp.y)*(1.0f-interp.z) *(1.0f-interpD) );

	svoAccumSampleStruct(newCol, res1, interp.x*(1.0f-interp.y)*(1.0f-interp.z) *(1.0f-interpD));
	svoAccumSampleStruct(newCol, res2, (1.0f-interp.x)*interp.y*(1.0f-interp.z) *(1.0f-interpD));
	svoAccumSampleStruct(newCol, res10, (1.0f-interp.x)*(1.0f-interp.y)*interp.z *(1.0f-interpD));


	int nodeIndex11 = svoGetNodeNeighbor(nodeIndex10, 0x1, 0);
	int nodeIndex13 = svoGetNodeNeighbor(nodeIndex10, 0x2, 1);
	int nodeIndex3 = svoGetNodeNeighbor(nodeIndex1, 0x2, 1);



	SampleStruct res11 = svoFetchGBuffer(nodeIndex11, ivec3(0) );
	SampleStruct res13 = svoFetchGBuffer(nodeIndex13, ivec3(0) );
	SampleStruct res3 = svoFetchGBuffer(nodeIndex3, ivec3(0) );

	

	svoAccumSampleStruct(newCol, res11, interp.x*(1.0f-interp.y)*interp.z *(1.0f-interpD));
	svoAccumSampleStruct(newCol, res13, (1.0f-interp.x)*interp.y*interp.z *(1.0f-interpD));
	svoAccumSampleStruct(newCol, res3, interp.x*interp.y*(1.0f-interp.z) *(1.0f-interpD));


	int nodeIndex12 = svoGetNodeNeighbor(nodeIndex11, 0x2, 1);
	SampleStruct res12 = svoFetchGBuffer(nodeIndex12, ivec3(0) );
	svoAccumSampleStruct(newCol, res12, interp.x*interp.y*interp.z *(1.0f-interpD));
	
	if(targetPosDiffI==0)
		nodeIndexToChildren=nodeIndex;
	else if(targetPosDiffI==1)
		nodeIndexToChildren=nodeIndex1;
	else if(targetPosDiffI==2)
		nodeIndexToChildren=nodeIndex2;
	else if(targetPosDiffI==4)
		nodeIndexToChildren=nodeIndex10;
	else if(targetPosDiffI==3)
		nodeIndexToChildren=nodeIndex3;
	else if(targetPosDiffI==5)
		nodeIndexToChildren=nodeIndex11;
	else if(targetPosDiffI==6)
		nodeIndexToChildren=nodeIndex13;
	else if(targetPosDiffI==7)
		nodeIndexToChildren=nodeIndex12;

#endif

	////LEVEL 1////
# if 1

#if 0
	if( (targetPosDiffI&1)==1 )
		nodeIndexToChildren = svoGetNodeNeighbor(nodeIndexToChildren, 0x1, 0);

	if( (targetPosDiffI&2)==2 )
		nodeIndexToChildren = svoGetNodeNeighbor(nodeIndexToChildren, 0x2, 1);

	if( (targetPosDiffI&4)==4 )
		nodeIndexToChildren = svoGetNodeNeighbor(nodeIndexToChildren, 0x4, 2);
#endif

	interp=fract( (interp-0.25f)/0.5f +1.0f );

	/////////////////////////////////////////

	//Child//
	nodeIndex = svoGetNodeChildren(nodeIndexToChildren);
	if(nodeIndex>0){
		nodeIndex += offsetInTile2;
		outLevel++;
	

	res = svoFetchGBuffer(nodeIndex, ivec3(0) );
	svoAccumSampleStruct(newCol, res, (1.0f-interp.x)*(1.0f-interp.y)*(1.0f-interp.z) *(interpD));

	svoSampleNeighborsTrilinear(newCol, nodeIndex, interp, interpD);

	}
# endif

	}

#endif

	return newCol;
}
//////////////////////////////////////////////


GLSL_FUNC_DEC
SampleStruct svoSample(vec3 rayDir, float targetDepthF, vec3 samplePos, GLSL_INOUT_PARAM(float) nextStepJump){
	SampleStruct newCol;


	SVO_LEVEL_VAR_TYPE targetLevel = SVO_LEVEL_VAR_TYPE(targetDepthF);

#if 1 //Boundary check//
	
	const float minBound=1.0f/2048.0f; const float maxBound=1.0f-minBound;
# if 0
	if(samplePos.x>=maxBound || samplePos.y>=maxBound || samplePos.z>=maxBound || samplePos.x<=minBound || samplePos.y<=minBound|| samplePos.z<=minBound)
		return newCol;
#else
	samplePos = clamp(samplePos, vec3(minBound), vec3(maxBound) );
# endif
#endif


#if SVO_USE_TOP_MIPMAP
	if(targetLevel<SVO_TOP_MIPMAP_MAX_LEVEL){

		float mipLevel = float(SVO_TOP_MIPMAP_NUM_LEVELS-1) - targetDepthF;

		newCol = svoSampleTopMipMap( mipLevel, samplePos);

	}else
#endif
	{

	
	SVO_LEVEL_VAR_TYPE outLevel;

#if SVO_USE_TEXTURE_FILTERING==0

	//int targetLevel=clamp((int)ceil(targetDepthF), 1, maxLevel);
	
# if SVO_SAMPLE_QUADLINEAR		//Quadlinear interpolation
	newCol = svoSampleQuadlinear(rayDir, targetDepthF, samplePos, outLevel);

# elif SVO_SAMPLE_TRILINEAR		//Trilinear interpolation
	newCol = svoSampleTrilinear(rayDir, targetLevel, samplePos, outLevel);

# else
	
	targetLevel = SVO_LEVEL_VAR_TYPE( ceil(targetDepthF) );

	int levelRes=1<<targetLevel;
	float levelResF=float(levelRes);
	vec3 targetPosF=samplePos*levelResF;
	ivec3	targetPos = ivec3(targetPosF);
	
	int nodeIndex;
	newCol  = svoFetchNode(targetLevel, targetPos, outLevel, nodeIndex);



	//MipMap unfiltered values
#  if SVO_SAMPLE_NEAREST_MIPMAP
	float interpD = float(targetLevel) - targetDepthF;
	//if(interpD>0.01f)//Optim
	{  
		svoScaleSampleStruct(newCol, (1.0f-interpD) );

		// Advance into the child
		int parentIndex = int(imageLoad(parentIndexBuffer, nodeIndex/8 ).r);
	
#if SVO_USE_BRICKS
	//ERROR !!!	
#endif
		ivec3 brickOffset=ivec3(0);
		SampleStruct newCol2 = svoFetchGBuffer(parentIndex, brickOffset );

		//hackColorFromLevel(targetLevel-1, newCol2.normal);
		//newCol2.normal*=0.1f;

		svoAccumSampleStruct(newCol, newCol2, interpD );

		//newCol.normal.rgb = vec3(interpD)*newCol.normal.w;
			
		
	}
#  endif


# endif

	//Empty space skipping was here

#else	//Texture filtering

	
# if 0	// MIPMAP interpolation 
	SampleStruct newCol0;
	SampleStruct newCol1;

	newCol0 = svoTraverseSampleBrick(rayDir, targetLevel, samplePos);
	newCol1 = svoTraverseSampleBrick(rayDir, targetLevel+1, samplePos);

	float interp =  targetDepthF-float(targetLevel);
	newCol.normal = newCol0.normal*(1.0f-interp)+newCol1.normal*interp;
	# ifdef GBUFFER_CHANNEL_svo_SVO_COVARIANCE_MAT1
		newCol.cov1 = newCol0.cov1*(1.0f-interp)+newCol1.cov1*interp;
	# endif
	# ifdef GBUFFER_CHANNEL_svo_SVO_COVARIANCE_MAT1
		newCol.cov2 = newCol0.cov2*(1.0f-interp)+newCol1.cov2*interp;
	#endif

# else
	newCol = svoTraverseSampleBrick(rayDir, targetLevel, samplePos, outLevel);
# endif

#endif

	/////////////////////////////////
#if SVO_EMPTY_SPACE_SKIPPING
	if(outLevel<targetLevel){
		int outLevelRes = 1<<(outLevel+0);	

		float outLevelResF = float(outLevelRes);
		float outNodeSize = 1.0f/outLevelResF;
		vec3 nodePos=floor(samplePos/outNodeSize)*outNodeSize;
		vec3 posInNode = samplePos-nodePos;

		//float newStep = getRayNodeLength(posInNode, outNodeSize, rayDir);
		float newStep = getEmptySpaceLength(posInNode, outNodeSize, rayDir);


#if (SVO_USE_TEXTURE_FILTERING || SVO_USE_BRICKS)
		newStep *= 0.3f;
#endif

		nextStepJump = max( newStep + nextStepJump, nextStepJump);
		//nextStepJump = max(nextStepJump, (newStep)*1.0f - nextStepJump);
	}
#endif
	////////////////////////////////

	}


	return newCol;
}

//# ifdef SVO_RAYCASTING_ENABLED


SampleStruct svoTraverseSampleBrick(vec3 rayDir, SVO_LEVEL_VAR_TYPE targetLevel, vec3 samplePos, GLSL_OUT_PARAM(SVO_LEVEL_VAR_TYPE) outLevel){
	
	SVO_LEVEL_VAR_TYPE targetLevelOctree = targetLevel-SVO_OCTREE_BIAS;

	int levelRes=1<<(targetLevelOctree);
	float levelResF=float(levelRes);

	vec3	targetPosF= (samplePos*levelResF) -1.0f/float(SVO_BRICK_RES);	//Trick for fetching neighboring brick
	//vec3	targetPosF= (samplePos*levelResF);

	ivec3	targetPos = ivec3(targetPosF);
	//SVO_LEVEL_VAR_TYPE outLevel;

	int nodeIndex=svoGetNodeIndex(targetLevelOctree, targetPos, outLevel);
	//int nodeIndex=svoGetNodeIndexCached(targetLevel, targetPos);
	//int nodeIndex=svoGetNodeIndexBlock(targetLevel, targetPos);

	SampleStruct newCol;
	if( (nodeIndex!=0) && (nodeIndex!=0xFFFFFFFF) )
	{
		

#if 1 //SVO_OCTREE_BIAS>0

		vec3 nodePos= floor( (targetPosF)*0.5f )*float(SVO_BRICK_RES);

		int levelResOK=1<<(targetLevel);
		float levelResOKF=float(levelResOK);
		targetPosF= samplePos*levelResOKF;

		//targetPosF = targetPosF*2.0f + 1.0f;
		
#else
		vec3 nodePos= floor( targetPosF*0.5f )*2.0f;

		//targetPosF += 0.5f;	//Was here, why ?
#endif
		
		newCol = svoSampleBrick(nodeIndex, nodePos, targetPosF);


	}else{

#   foreach(NAME, name) in (WS_NORMAL, normal), (CS_NORMAL, csNormal), (WS_FACE_NORMAL, faceNormal), (CS_FACE_NORMAL, csFaceNormal), (WS_POSITION, wsPosition), (CS_POSITION, csPosition), (LAMBERTIAN, lambertian), (GLOSSY, glossy), (TRANSMISSIVE, transmissive), (EMISSIVE, emissive), (CS_POSITION_CHANGE, csPosChange), (SS_POSITION_CHANGE, ssPosChange), (CS_Z, csZ), (DEPTH_AND_STENCIL, depthStencil), (TS_NORMAL, tsNormal), (SVO_POSITION, svoPos), (SVO_COVARIANCE_MAT1, cov1), (SVO_COVARIANCE_MAT2, cov2)
#       ifdef GBUFFER_CHANNEL_svo_$(NAME)
		newCol.$(name) = vec4(0.0f);
#       endif
#   endforeach

	}

	return newCol;
}

//# endif //SVO_RAYCASTING_ENABLED


#endif