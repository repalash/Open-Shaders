// Copyright Epic Games, Inc. All Rights Reserved.

/*================================================================================================
	RayTracingBuiltInResources.h: used in ray tracing shaders and C++ code to define resources 
	available in all hit groups, such as root nostants, index and vertex buffers.
	!!! Changing this file requires recompilation of the engine !!!
=================================================================================================*/

#pragma once

#ifndef RAYTRACINGBUILTINRESOURCES_USH_INCLUDED
#define RAYTRACINGBUILTINRESOURCES_USH_INCLUDED // Workarround for UE-66460

#include "RayTracingDefinitions.h"

#if defined(__cplusplus)
	#define INCLUDED_FROM_CPP_CODE  1
	#define INCLUDED_FROM_HLSL_CODE 0
#elif defined(SM5_PROFILE)
	// #dxr_todo: we should use a built-in macro to detect if this shader is compiled using DXC (depends on https://github.com/Microsoft/DirectXShaderCompiler/issues/1686)
	#define INCLUDED_FROM_CPP_CODE  0
	#define INCLUDED_FROM_HLSL_CODE 1
#else
	#error Unknown Compiler
#endif

#if INCLUDED_FROM_HLSL_CODE
	#define UINT_TYPE uint
#elif INCLUDED_FROM_CPP_CODE
	#define UINT_TYPE unsigned int
#endif

struct FHitGroupSystemRootConstants
{
	// Config is a bitfield:
	// uint IndexStride  : 8; // Can be just 1 bit to indicate 16 or 32 bit indices
	// uint VertexStride : 8; // Can be just 2 bits to indicate float3, float2 or half2 format
	// uint Unused       : 16;
	UINT_TYPE Config;

	// Offset into HitGroupSystemIndexBuffer
	UINT_TYPE IndexBufferOffsetInBytes;

	// User-provided constant assigned to the hit group
	UINT_TYPE UserData;

	// Index of the first geometry instance that belongs to the current batch.
	// Can be used to emulate SV_InstanceID in ray tracing shaders.
	UINT_TYPE BaseInstanceIndex;

	// Helper functions

	UINT_TYPE GetIndexStride()
	{
		return Config & 0xFF;
	}

	UINT_TYPE GetVertexStride()
	{
		return (Config >> 8) & 0xFF;
	}

	#if INCLUDED_FROM_CPP_CODE
		void SetVertexAndIndexStride(UINT_TYPE Vertex, UINT_TYPE Index)
		{
			Config = (Index & 0xFF) | ((Vertex & 0xFF) << 8);
		}
	#endif
};

#define RAY_TRACING_SYSTEM_INDEXBUFFER_REGISTER  0
#define RAY_TRACING_SYSTEM_VERTEXBUFFER_REGISTER 1
#define RAY_TRACING_SYSTEM_ROOTCONSTANT_REGISTER 0

#if INCLUDED_FROM_HLSL_CODE

#ifndef OVERRIDE_RAYTRACINGBUILTINSHADERS_USH
	#define RT_CONCATENATE2(a, b) a##b
	#define RT_CONCATENATE(a, b) RT_CONCATENATE2(a, b)
	#define RT_REGISTER(InType, InIndex, InSpace) register(RT_CONCATENATE(InType, InIndex), RT_CONCATENATE(space, InSpace))
	// Built-in local root parameters that are always bound to all hit shaders
	ByteAddressBuffer									HitGroupSystemIndexBuffer   : RT_REGISTER(t, RAY_TRACING_SYSTEM_INDEXBUFFER_REGISTER,  RAY_TRACING_REGISTER_SPACE_SYSTEM);
	ByteAddressBuffer									HitGroupSystemVertexBuffer  : RT_REGISTER(t, RAY_TRACING_SYSTEM_VERTEXBUFFER_REGISTER, RAY_TRACING_REGISTER_SPACE_SYSTEM);
	ConstantBuffer<FHitGroupSystemRootConstants>		HitGroupSystemRootConstants : RT_REGISTER(b, RAY_TRACING_SYSTEM_ROOTCONSTANT_REGISTER, RAY_TRACING_REGISTER_SPACE_SYSTEM);
	#undef RT_REGISTER
	#undef RT_CONCATENATE
	#undef RT_CONCATENATE2
#endif // !OVERRIDE_RAYTRACINGBUILTINSHADERS_USH

#endif // INCLUDED_FROM_HLSL_CODE


#undef INCLUDED_FROM_CPP_CODE
#undef INCLUDED_FROM_HLSL_CODE
#undef UINT_TYPE

#endif // RAYTRACINGBUILTINRESOURCES_USH_INCLUDED // Workarround for UE-66460
