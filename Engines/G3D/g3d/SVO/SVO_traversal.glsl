/**
  \file data-files/shader/SVO/SVO_traversal.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef SVO_traversal_glsl
#define SVO_traversal_glsl




//targetPos is expressed at SVO_REF_MAX_LEVEL
GLSL_FUNC_DEC
int svoTraverseOctreeDown(int startNodeIndex, SVO_LEVEL_VAR_TYPE startLevel, SVO_COORD_VAR_TYPE targetPos, SVO_LEVEL_VAR_TYPE targetLevel, GLSL_OUT_PARAM(SVO_LEVEL_VAR_TYPE) outLevel){


#if SVO_USE_TOP_MIPMAP
	if(targetLevel>SVO_TOP_MIPMAP_MAX_LEVEL){

		startLevel = SVO_TOP_MIPMAP_MAX_LEVEL;
		startNodeIndex = SVO_TOP_MIPMAP_MAX_LEVEL_INDEX;

		//int startLevelRes = 1<<(startLevel-1);
		//ivec3	mipMapMaxPos = clamp(targetPos>>(targetLevel-startLevel+1), ivec3(0), ivec3(startLevelRes));
		ivec3	mipMapMaxPos = targetPos>>(targetLevel-startLevel+1);

		startNodeIndex += (svoTopMipMapLevelOffset( mipMapMaxPos, startLevel-1 ) ) <<3; // *8
	}
#endif


	// Current node (initially the root)
    int nodeIndex = startNodeIndex;
#if SVO_TRAVERSE_NODEIDX_OPTIM==0
	int nextNodeIndex = startNodeIndex;
#endif

#if SVO_TRAVERSE_SHIFT_OPTIM==0
	SVO_COORD_VAR_TYPE	posI = targetPos;
	SVO_COORD_BASE_TYPE shiftOffset=(targetLevel-startLevel);
#else
	SVO_COORD_VAR_TYPE	posI = targetPos<<2;
	SVO_COORD_BASE_TYPE shiftOffset=(targetLevel-startLevel)+2;
#endif

	// Traverse the tree
	int curLevel;
	for (curLevel = startLevel; (curLevel <= targetLevel) && 
#if SVO_TRAVERSE_NODEIDX_OPTIM==0
		(nextNodeIndex != NULL) && (nextNodeIndex != 0xFFFFFFFFU) 
#else
		(nodeIndex != NULL) && (nodeIndex != 0xFFFFFFFFU) 
#endif
		; ++curLevel) 
	{

#if SVO_TRAVERSE_NODEIDX_OPTIM==0
		nodeIndex = nextNodeIndex;
#endif

#if SVO_TRAVERSE_SHIFT_OPTIM==0
# if 0
		SVO_COORD_VAR_TYPE	offset2DTemp = posI>>(shiftOffset);
		SVO_COORD_VAR_TYPE	offset2D = offset2DTemp & SVO_COORD_VAR_TYPE(1);

        // Every three bits describe one level, where the LSB are level 0 in the form (zyx)
        nodeIndex += (offset2D.x | offset2D.y<<1 | offset2D.z<<2);
# else
		SVO_COORD_VAR_TYPE	offset2DTemp = posI>>(shiftOffset);
		SVO_COORD_VAR_TYPE	offset2D = offset2DTemp % SVO_COORD_VAR_TYPE(2);

        // Every three bits describe one level, where the LSB are level 0 in the form (zyx)
        nodeIndex += (offset2D.x + offset2D.y*2 + offset2D.z*4);
# endif
#else
		SVO_COORD_VAR_TYPE	offset2DTemp = posI>>ivec3(shiftOffset, shiftOffset-1, shiftOffset-2);
		//SVO_COORD_VAR_TYPE	offset2DTemp = posI/ivec3(pow(2, shiftOffset), pow(2, shiftOffset-1), pow(2, shiftOffset-2));
		SVO_COORD_VAR_TYPE	offset2D = offset2DTemp & ivec3(1, 2, 4);

		// Every three bits describe one level, where the LSB are level 0 in the form (zyx)
		nodeIndex += (offset2D.x | offset2D.y | offset2D.z) ;
#endif

#if SVO_TRAVERSE_NODEIDX_OPTIM
		if( curLevel < targetLevel )
#endif
		{


			// Advance into the child
#if SVO_TRAVERSE_NODEIDX_OPTIM==0
			nextNodeIndex 
#else
			nodeIndex
#endif
#if SVO_TRAVERSE_FETCH_THROUGH_TEX==0
				= int( GLSL_GLOBAL_LOAD(d_childIndexBuffer+nodeIndex) );
				//= int(imageLoad(childIndexBuffer, nodeIndex).x);
#else

				= int(texelFetch(childIndexBufferTex, nodeIndex).x);
#endif


			shiftOffset--;
		}
    }

#if 0	
	outLevel = (curLevel-1);		//old
#else //New
	if(curLevel==targetLevel+1)
		outLevel = targetLevel;
	else
		outLevel = curLevel;
#endif


	//outLevel = targetLevel;
	return nodeIndex;
}



GLSL_FUNC_DEC
int svoGetNodeIndex(SVO_LEVEL_VAR_TYPE targetLevel, SVO_COORD_VAR_TYPE targetPos, GLSL_OUT_PARAM(SVO_LEVEL_VAR_TYPE) outLevel){

	int startNodeIndex = (int)svoGetRootLocation(
#ifdef SVO_USE_VARIABLE_SVO_ID
		svoCurrentSvoID
#else
		SVO_CUR_SVO_ID
#endif
		);

	SVO_LEVEL_VAR_TYPE startLevel = 1;
	
	int nodeIndex;

#if SVO_USE_TOP_DENSE
	
	//float mipLevel = float(SVO_TOP_MIPMAP_NUM_LEVELS-1) - targetDepthF;
	//newCol = svoSampleTopMipMap( mipLevel, samplePos);
#if 1
	int usedTopLevel = min(targetLevel, SVO_TOP_MIPMAP_MAX_LEVEL);
	ivec3 usedTargetPos = targetPos>>ivec3(targetLevel-usedTopLevel);

	int levelRes = 1<<usedTopLevel;
	//int offsetAtLevel = usedTargetPos.x + (usedTargetPos.y + usedTargetPos.z*levelRes) * levelRes;
	int offsetAtLevel = int(interleaveBits( uvec3(usedTargetPos) ) );

#if 0
	int topLevelOffset = 0;
	for(int l=1; l<usedTopLevel; l++){
		topLevelOffset += svoTopDenseTreeGetLevelNumNodes(l);
	}
	
	int topNodeIndex = startNodeIndex + topLevelOffset + offsetAtLevel;
#else

	startNodeIndex = (int)svoGetRootLocation(SVO_CUR_SVO_ID, usedTopLevel);
	int topNodeIndex = startNodeIndex + offsetAtLevel;

#endif

	if( (targetLevel<=SVO_TOP_MIPMAP_MAX_LEVEL) ){
		
		outLevel = targetLevel;
		nodeIndex = topNodeIndex;

		//TODO: empty space skipping in dense tree ! (go up until not empty node)
	}else
#endif
	{

#if 1
		startLevel = usedTopLevel;
		//startNodeIndex = startNodeIndex + topLevelOffset + (offsetAtLevel/8)*8;
		startNodeIndex = startNodeIndex + (offsetAtLevel/8)*8;
#else
		int usedTopLevel = min(targetLevel, SVO_TOP_MIPMAP_MAX_LEVEL-3);
		startLevel = usedTopLevel;

		ivec3 usedTargetPos = targetPos>>ivec3(targetLevel-(usedTopLevel-1));

		int levelRes = 1<<(usedTopLevel-1);
		//int offsetAtLevel = usedTargetPos.x + (usedTargetPos.y + usedTargetPos.z*levelRes) * levelRes;
		int offsetAtLevel = int(interleaveBits( uvec3(usedTargetPos) ) );

		int topLevelOffset = 0;
		for(int l=1; l<usedTopLevel; l++){
			topLevelOffset += svoTopDenseTreeGetLevelNumNodes(l);
		}

		startNodeIndex = startNodeIndex + topLevelOffset + offsetAtLevel*8;
#endif


#else
	{
#endif
	
		nodeIndex = svoTraverseOctreeDown(startNodeIndex, startLevel, targetPos, targetLevel, outLevel);

		if(outLevel!=targetLevel){
			nodeIndex=0;
		}
	}

	return nodeIndex;
}

GLSL_FUNC_DEC
int svoGetNodeIndex(SVO_LEVEL_VAR_TYPE targetLevel, SVO_COORD_VAR_TYPE targetPos){

	SVO_LEVEL_VAR_TYPE outLevel;
	
	return svoGetNodeIndex(targetLevel, targetPos, outLevel);
}


GLSL_FUNC_DEC
int svoGetNodeChildren(int nodeIndex){
	int childrenTile=0;

	if( nodeIndex!=0 ){
		childrenTile = int( GLSL_GLOBAL_LOAD(d_childIndexBuffer+nodeIndex) );
	}
	
	return childrenTile;
	
}


#endif
