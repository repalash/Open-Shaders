// -*- c++ -*-
/** \file Texture/Texture.glsl 

 G3D Innovation Engine (http://g3d.sf.net)
 Copyright 2000-2014, Morgan McGuire.
 All rights reserved.
*/

#ifndef Texture_glsl
#define Texture_glsl

/**
 \def uniform_Texture

 Declares a uniform sampler and the float4 readMultiplyFirst and readAddSecond variables.
 The host Texture::setShaderArgs call will also bind a macro name##notNull if the arguments
 are bound on the host side. If they are not bound and the device code does not use them, then 
 GLSL will silently ignore the uniform declarations.

 \param dimension 2D, 2DShadow, 3D, Rect, or Cube
 \param name Include the underscore suffix

 \sa G3D::Texture, G3D::Texture::setShaderArgs, G3D::Args
 */
#define uniform_Texture(dimension, name)\
    uniform sampler##dimension  name##buffer;\
    uniform vec3                name##size;\
    uniform vec3                name##invSize;\
    uniform vec4                name##readMultiplyFirst;\
    uniform vec4                name##readAddSecond;

#endif
