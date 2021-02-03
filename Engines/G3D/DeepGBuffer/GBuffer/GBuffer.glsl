// -*- c++ -*-
/** \file GBuffer/GBuffer.glsl 

 G3D Innovation Engine (http://g3d.sf.net)
 Copyright 2000-2014, Morgan McGuire.
 All rights reserved.
*/

#ifndef GBuffer_glsl
#define GBuffer_glsl

#include <compatibility.glsl>
#include <Camera/Camera.glsl>

/**
 \def uniform_GBuffer

 Declares all uniforms needed to read all fields of
 the GBuffer. On the host, invoke GBuffer::setShaderReadArgs
 to pass these values. Unused variables in the device 
 shader will be removed by the compiler.

 \param name Include the underscore suffix, if a name is desired

 \sa G3D::GBuffer, G3D::GBuffer::setShaderArgsRead, G3D::Args, uniform_Texture
 */
#define uniform_GBuffer(name)\
    uniform_Texture(2D, name##LAMBERTIAN_);\
    uniform_Texture(2D, name##GLOSSY_);\
    uniform_Texture(2D, name##EMISSIVE_);\
    uniform_Texture(2D, name##WS_NORMAL_);\
    uniform_Texture(2D, name##CS_NORMAL_);\
    uniform_Texture(2D, name##WS_FACE_NORMAL_);\
    uniform_Texture(2D, name##CS_FACE_NORMAL_);\
    uniform_Texture(2D, name##CS_POSITION_);\
    uniform_Texture(2D, name##WS_POSITION_);\
    uniform_Texture(2D, name##CS_POSITION_CHANGE_);\
    uniform_Texture(2D, name##SS_POSITION_CHANGE_);\
    uniform_Texture(2D, name##SS_EXPRESSIVE_MOTION_);\
    uniform_Texture(2D, name##CS_Z_);\
    uniform_Texture(2D, name##DEPTH_);\
    uniform_Texture(2D, name##TS_NORMAL_);\
    uniform_Texture(2D, name##SVO_POSITION_);\
    uniform_Camera(name##camera_);
    

#endif
