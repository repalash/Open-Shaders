// -*- c++ -*-
/** \file UniversalMaterial/UniversalMaterial.glsl 

 G3D Innovation Engine (http://g3d.sf.net)
 Copyright 2000-2014, Morgan McGuire.
 All rights reserved.
*/
#ifndef UniversalMaterial_glsl
#define UniversalMaterial_glsl

#include <compatibility.glsl>
#include <Texture/Texture.glsl>

/**
 \def uniform_UniversalMaterial

 Declares all material properties. Additional macros will also be bound 
 by UniversalMaterial::setShaderArgs:

 - name##NUM_LIGHTMAP_DIRECTIONS
 - name##NORMALBUMPMAP
 - name##PARALLAXSTEPS
 
 \param name Include the underscore suffix, if a name is desired

 \sa G3D::UniversalMaterial, G3D::UniversalMaterial::setShaderArgs, G3D::Args, uniform_Texture
 \beta
 */
#define uniform_UniversalMaterial(name)\
	uniform_Texture(2D, name##LAMBERTIAN_);\
	uniform_Texture(2D, name##GLOSSY_);\
	uniform vec3		name##emissiveConstant;\
	uniform sampler2D	name##emissiveMap;\
	uniform vec3		name##transmissiveConstant;\
	uniform sampler2D	name##transmissiveMap;\
	uniform vec4		name##customConstant;\
	uniform sampler2D	name##customMap;\
	uniform float		name##lightMapConstant;\
	uniform sampler2D	name##lightMap0;\
	uniform sampler2D	name##lightMap1;\
	uniform sampler2D	name##lightMap2;\
    uniform sampler2D   name##normalBumpMap;\
    uniform float       name##bumpMapScale;\
	uniform float       name##bumpMapBias;\
    uniform_Texture(2D, name##customMap_);

#endif
