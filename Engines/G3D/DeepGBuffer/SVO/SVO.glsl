// -*- c++ -*-
#ifndef SVO_glsl
#define SVO_glsl

/**
  \file SVO.glsl
  \author Cyril Crassine, http://www.icare3d.org

  For use with G3D::Shader.
  This file is included into NonShadowedPass.pix and ShadowMappedLightPass.pix.

  \created 2013-07-03
  \edited  2013-07-03

  This files define helper functions for manipulating Sparse Voxel Octrees.

  \sa G3D::SVO
 */

/** The tree itself */
layout(r32ui) uniform uimageBuffer   childIndexBuffer;
layout(r32ui) uniform uimageBuffer   parentIndexBuffer;

/** Location of the root node in the childIndexBuffer */
const int               ROOT_LOCATION = 8;

#define NULL (0)


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


int svoGetNodeIndex(int level, vec3 pos){

	// Current node (initially the root)
    int nodeIndex = ROOT_LOCATION;


	int levelRes=1<<level;

	ivec3	posI = ivec3(pos*float(levelRes));

    // Traverse the tree
    for (int curLevel = 1; (nodeIndex != NULL) && (nodeIndex != 0xFFFFFFFFU) && (curLevel <= level); ++curLevel) {

		ivec3	offset2D= (posI>>(level-curLevel)) & ivec3(1) ;

        // Every three bits describe one level, where the LSB are level 0 in the form (zyx)
        int offset = offset2D.x | offset2D.y<<1 | offset2D.z<<2;
 
        // Move the center following the bits
        vec3 step = vec3(offset2D);

        // Advance into the child
        nodeIndex = int(imageLoad(childIndexBuffer, offset + nodeIndex).r);
    }

	return nodeIndex;
}

#endif