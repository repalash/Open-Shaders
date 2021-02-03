/**
  \file data-files/shader/SVO/SVO.glsl

  For use with G3D::Shader.
  This file is included into NonShadowedPass.pix and ShadowMappedLightPass.pix.
  This files define helper functions for manipulating Sparse Voxel Octrees.

  \sa G3D::SVO

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef SVO_glsl
#define SVO_glsl

#expect SVO_MAX_LEVEL
#expect SVO_NUM_LEVELS

#expect SVO_USE_BRICKS
#expect SVO_BRICK_NUM_LEVELS
#expect SVO_BRICK_RES
#expect SVO_BRICK_RES_WITH_BORDER
#expect SVO_BRICK_BORDER
#expect SVO_BRICK_BORDER_OFFSET

#expect SVO_OCTREE_BIAS

#expect SVO_VOXELPOOL_RES_X
#expect SVO_VOXELPOOL_RES_Y
#expect SVO_VOXELPOOL_RES_Z
#expect SVO_VOXELPOOL_RES_BRICK_X
#expect SVO_VOXELPOOL_RES_BRICK_Y
#expect SVO_VOXELPOOL_RES_BRICK_Z

#expect SVO_USE_TOP_MIPMAP
#expect SVO_TOP_MIPMAP_NUM_LEVELS
#expect SVO_TOP_MIPMAP_MAX_LEVEL
#expect SVO_TOP_MIPMAP_RES
#expect SVO_TOP_MIPMAP_MAX_LEVEL_INDEX

#include <compatibility.glsl>
#include <GBuffer/GBuffer2.glsl>

DECLARE_GBUFFER(svo)			//Declares a GBuffer which name is svo

#if SVO_USE_TOP_MIPMAP
DECLARE_GBUFFER(svoTopMipMap)	//Top MipMap GBuffer
#endif

/** The tree itself */

/** The top part of the tree is used for traversal.  The leaves are then flagged
    with 0xFFFFFFFF if they have any child
 */
layout(r32ui, bindless_image) uniform uimageBuffer		childIndexBuffer;
uniform usamplerBuffer									childIndexBufferTex;
uniform uint											*d_childIndexBuffer;


layout(r32ui, bindless_image) uniform uimageBuffer		parentIndexBuffer;
coherent volatile uniform uint							*d_parentIndexBuffer;

layout(r32ui, bindless_image) uniform uimageBuffer		levelIndexBuffer;

coherent volatile uniform uint							*d_rootIndexBuffer;		//New
uniform usamplerBuffer									rootIndexBufferTex;


uniform uint		octreePoolNumNodes;




////////Ground truth////////
uniform int		groundTruthMode;
uniform float	projectionScale;
uniform vec2	projectionOffset;
////////////////////////////

uniform mat4	svoWorldToSVOMat;

vec3			svo_triangle_normal;		//Global var

///////////////////////////////////////////////////////////////////
#include <SVO/SVO_base.glsl>

#include <SVO/SVO_traversal.glsl>

#include <SVO/SVO_sampling.glsl>

///////////////////////////////////////////////////////////////////

GLSL_FUNC_DEC
int svoGetNodeIndex(SVO_LEVEL_VAR_TYPE targetLevel, SVO_COORD_VAR_TYPE targetPos);

GLSL_FUNC_DEC
int svoGetNodeIndex(SVO_LEVEL_VAR_TYPE targetLevel, SVO_COORD_VAR_TYPE targetPos, GLSL_OUT_PARAM(SVO_LEVEL_VAR_TYPE) outLevel);




#if SVO_USE_TOP_MIPMAP
SampleStruct svoSampleTopMipMap(float miplevel, vec3 samplePos){

	SampleStruct res;

# if defined(GBUFFER_READ_ENABLED_svoTopMipMap) && defined(GBUFFER_CHANNEL_svoTopMipMap_WS_NORMAL)
	res.normal=textureLod( GBUFFER_TEX(svoTopMipMap, WS_NORMAL), samplePos, miplevel);
	//res.normal=vec4(0.0f, 1.0f, 0.0f, 1.0f);
# endif

#if defined(GBUFFER_READ_ENABLED_svoTopMipMap)
# ifdef GBUFFER_CHANNEL_svoTopMipMap_SVO_COVARIANCE_MAT1

	res.cov1 = textureLod( GBUFFER_TEX(svoTopMipMap, SVO_COVARIANCE_MAT1),  samplePos, miplevel);

# endif

# ifdef GBUFFER_CHANNEL_svoTopMipMap_SVO_COVARIANCE_MAT2

	res.cov2 = textureLod( GBUFFER_TEX(svoTopMipMap, SVO_COVARIANCE_MAT2),  samplePos, miplevel);

# endif
#endif

	return res;
}
#endif






#endif