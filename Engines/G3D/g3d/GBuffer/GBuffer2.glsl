/**
  \file data-files/shader/GBuffer/GBuffer2.glsl

  For use with G3D::Shader.
  This files define helper functions for manipulating GBuffers.

  \sa G3D::SVO

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef GBuffer2_glsl
#define GBuffer2_glsl


#ifndef GBUFFER_CONNECTED
//# error "The GBuffers need to be connected to the shader by calling  GBuffer::connectToShader(...)"
#endif

#define DECLARE_GBUFFER_INNER(gbufferName) \
	GBUFFER_FIELDS_DECLARATIONS_ ## gbufferName
#define DECLARE_GBUFFER(gbufferName) \
	DECLARE_GBUFFER_INNER( gbufferName )


//Use "#ifdef GBUFFER_CHANNEL_gbufferName_channel" to detect if a channel is present into the GBuffer


//#define GBUFFER_USE_IMAGE_STORE(gbufferName) \
//	GBUFFER_USE_IMAGE_STORE_##gbufferName


#define GBUFFER_DIMENSION(gbufferName) \
	GBUFFER_DIMENSION_##gbufferName


#define GBUFFER_WIDTH(gbufferName) \
	GBUFFER_WIDTH_##gbufferName

#define GBUFFER_HEIGHT(gbufferName) \
	GBUFFER_HEIGHT_##gbufferName


#define GBUFFER_WIDTH_MASK_INNER(gbufferName) \
	GBUFFER_WIDTH_MASK_##gbufferName
#define GBUFFER_WIDTH_MASK(gbufferName) \
	GBUFFER_WIDTH_MASK_INNER(gbufferName)

#define GBUFFER_WIDTH_SHIFT_INNER(gbufferName) \
	GBUFFER_WIDTH_SHIFT_##gbufferName
#define GBUFFER_WIDTH_SHIFT(gbufferName) \
	GBUFFER_WIDTH_SHIFT_INNER(gbufferName)

#define GBUFFER_HEIGHT_MASK(gbufferName) \
	GBUFFER_HEIGHT_MASK_##gbufferName

#define GBUFFER_WIDTH_HEIGHT_SHIFT(gbufferName) \
	GBUFFER_WIDTH_HEIGHT_SHIFT_##gbufferName


#define GBUFFER_TYPE(gbufferName, field) \
	GBUFFER_TYPE_##gbufferName##_##field

#define GBUFFER_COMPONENTS(gbufferName, field) \
	GBUFFER_COMPONENTS_##gbufferName##_##field


#define GBUFFER_WRITE_SCALEBIAS(gbufferName, field) \
	gbufferName##_##field##_writeScaleBias

#define GBUFFER_READ_SCALEBIAS(gbufferName, field) \
	gbufferName##_##field##_readScaleBias


#define GBUFFER_GLOBAL_VAR(gbufferName, field) \
	gbufferName##_##field


#define GBUFFER_TEX(gbufferName, field) \
	gbufferName##_##field##_tex


#define GBUFFER_IMAGE_INNER(gbufferName, field) \
	gbufferName##_##field##_image

//For NV bug, not working
//#define GBUFFER_IMAGE_INNER(gbufferName, field) \
//	GBUFFER_IMAGE_REF_##gbufferName##_##field

#define GBUFFER_IMAGE(gbufferName, field) \
	GBUFFER_IMAGE_INNER(gbufferName, field)

#define GBUFFER_COORDS_INNER(gbufferName, coords) \
	GBUFFER_COORDS_##gbufferName(coords)
#define GBUFFER_COORDS(gbufferName, coords) \
	GBUFFER_COORDS_INNER(gbufferName, coords)

#define GBUFFER_VALUE_WRITE(val) \
	gbufferWriteValueHelper(val)

//WRITE//
#define GBUFFER_WRITE_GLOBAL_VARS(gbufferName, coords)\
	GBUFFER_WRITE_GLOBAL_VARS_3D(gbufferName, gbufferCoordsHelper(coords))

#define GBUFFER_WRITE_GLOBAL_VARS_3D(gbufferName, coords)\
	gbufferWriteGlobalVars_##gbufferName(coords)

//LOAD//
#define GBUFFER_LOAD_GLOBAL_VARS(gbufferName, coords)\
	GBUFFER_LOAD_GLOBAL_VARS_3D(gbufferName, gbufferCoordsHelper(coords))

#define GBUFFER_LOAD_GLOBAL_VARS_3D(gbufferName, coords)\
	gbufferLoadGlobalVars_##gbufferName(coords, 0)

#define GBUFFER_LOAD_GLOBAL_VARS_MULTISAMPLE(gbufferName, coords, sampleID)\
	gbufferLoadGlobalVars_##gbufferName( gbufferCoordsHelper(coords), sampleID)

//Generic STORE
#define GBUFFER_STORE_VARS(srcGbufferName, dstGbufferName, coords)\
	GBUFFER_STORE_VARS_3D(srcGbufferName, dstGbufferName, gbufferCoordsHelper(coords))

#define GBUFFER_STORE_VARS_3D(srcGbufferName, dstGbufferName, coords) \
	GBUFFER_STORE_VARS_3D_##dstGbufferName(srcGbufferName, coords)


#ifdef GBUFFER_USE_IMAGE_STORE
#   ifndef GL_ARB_shader_image_load_store
#       error "Using the SVO shaders requires the GL_ARB_shader_image_load_store extension"
#   endif
#endif

ivec3 gbufferCoordsHelper(ivec3 coords){ return coords; }
ivec3 gbufferCoordsHelper(ivec2 coords){ return ivec3(coords, 0); }
ivec3 gbufferCoordsHelper(int coords){ return ivec3(coords, 0, 0); }

vec3 gbufferCoordsHelper(vec3 coords){ return coords; }
vec3 gbufferCoordsHelper(vec2 coords){ return vec3(coords, 0.0f); }


vec4 gbufferWriteValueHelper(vec4 val){ return val; }
vec4 gbufferWriteValueHelper(vec3 val){ return vec4(val, 0.0f); }
vec4 gbufferWriteValueHelper(vec2 val){ return vec4(val, 0.0f, 0.0f); }
vec4 gbufferWriteValueHelper(float val){ return vec4(val, 0.0f, 0.0f, 0.0f); }


//TODO: clean this ?
 /** Do not read color attributes (except LAMBERTIAN, if an alpha test is required)
        outside of this rectangle.  Used to implement the trim band outside of which
        only depth is recorded. */
uniform vec2            lowerCoord, upperCoord;


#endif //GBuffer_glsl