/**
  \file data-files/shader/Texture/Texture.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/

#ifndef Texture_glsl
#define Texture_glsl

#extension GL_ARB_texture_cube_map_array : require

#ifndef vec1
#define vec1 float
#endif

#ifndef ivec1
#define ivec1 int
#endif

/**
 \def uniform_Texture

 Declares a uniform sampler and the float4 readMultiplyFirst and readAddSecond variables.
 The host Texture::setShaderArgs call will also bind a macro name##notNull if the arguments
 are bound on the host side. If they are not bound and the device code does not use them, then 
 GLSL will silently ignore the uniform declarations.

 \param samplerType sampler2D, sampler2DShadow, sampler3D, samplerRect, or samplerCube
 \param name Include the underscore suffix

 \sa G3D::Texture, G3D::Texture::setShaderArgs, G3D::Args
 */
#define uniform_Texture(samplerType, name)\
    uniform samplerType  name##buffer;\
    uniform vec3         name##size;\
    uniform vec3         name##invSize;\
    uniform vec4         name##readMultiplyFirst;\
    uniform vec4         name##readAddSecond

/**
 \def Texture2D

 Bind with Texture::setShaderArgs("texture.")

 \sa G3D::Texture, G3D::Texture::setShaderArgs, G3D::Args
*/
#foreach (dim, n) in (1D, 1), (2D, 2), (3D, 3), (Cube, 2), (2DRect, 2), (1DArray, 2), (2DArray, 3), (CubeArray, 2), (Buffer, 1), (2DMS, 2), (2DMSArray, 3), (1DShadow, 1), (2DShadow, 2), (CubeShadow, 2), (2DRectShadow, 2), (1DArrayShadow, 2), (2DArrayShadow, 3), (CubeArrayShadow, 3)
    struct Texture$(dim) {
        sampler$(dim) sampler;
        vec$(n)       size;
        vec$(n)       invSize;
        vec4          readMultiplyFirst;
        vec4          readAddSecond;

        /** false if the underlying texture was nullptr when bound */
        bool          notNull;
    };
#endforeach
#foreach (dim, n) in (1D, 1), (2D, 2), (3D, 3), (Cube, 2), (2DRect, 2), (1DArray, 2), (2DArray, 3), (CubeArray, 2), (Buffer, 1), (2DMS, 2), (2DMSArray, 3)
    struct IntTexture$(dim) {
        isampler$(dim) sampler;
        vec$(n)       size;
        vec$(n)       invSize;
        vec4          readMultiplyFirst;
        vec4          readAddSecond;

        /** false if the underlying texture was nullptr when bound */
        bool          notNull;
    };
#endforeach
#foreach (dim, n) in (1D, 1), (2D, 2), (3D, 3), (Cube, 2), (2DRect, 2), (1DArray, 2), (2DArray, 3), (CubeArray, 2), (Buffer, 1), (2DMS, 2), (2DMSArray, 3)
    struct UIntTexture$(dim) {
        usampler$(dim) sampler;
        vec$(n)       size;
        vec$(n)       invSize;
        vec4          readMultiplyFirst;
        vec4          readAddSecond;

        /** false if the underlying texture was nullptr when bound */
        bool          notNull;
    };
#endforeach
   


#foreach (dim, n, addr) in (1D, 1, 1), (2D, 2, 2), (3D, 3, 3), (Cube, 2, 3), (1DArray, 2, 2), (2DArray, 3, 3)
//,(CubeArray, 2, 4), (1DShadow, 1, 3), (2DShadow, 2, 3), (CubeShadow, 2, 3), (2DRectShadow, 2, 2), (1DArrayShadow, 2, 3), (2DArrayShadow, 3, 3)
    vec4 sampleTexture(Texture$(dim) tex, vec$(addr) coord) {
        return texture(tex.sampler, coord) * tex.readMultiplyFirst + tex.readAddSecond;
    }

    vec4 sampleTexture(Texture$(dim) tex, vec$(addr) coord, float lodBias) {
        return texture(tex.sampler, coord
#if !defined(G3D_OSX) && !defined(G3D_INTEL)
                       , lodBias
#endif
                       ) * tex.readMultiplyFirst + tex.readAddSecond;
    }

    vec4 sampleTextureLod(Texture$(dim) tex, vec$(addr) coord, float lod) {
        return textureLod(tex.sampler, coord, lod) * tex.readMultiplyFirst + tex.readAddSecond;
    }
#endforeach

#foreach (dim, n, addr) in (1D, 1, 1), (2D, 2, 2), (3D, 3, 3), (1DArray, 2, 2), (2DArray, 3, 3)
    vec4 sampleTextureFetch(Texture$(dim) tex, ivec$(addr) coord, int lod) {
        return texelFetch(tex.sampler, coord, lod) * tex.readMultiplyFirst + tex.readAddSecond;
    }
#endforeach

/*
#if __VERSION >= 400
#foreach (dim, n, addr) in (CubeArrayShadow, 3, 3)
    vec4 sampleTexture(Texture$(dim) tex, vec$(addr) coord) {
        return texture(tex.sampler, coord) * tex.readMultiplyFirst + tex.readAddSecond;
    }

    vec4 sampleTextureLod(Texture$(dim) tex, vec$(addr) coord, float lod) {
        return textureLod(tex.sampler, coord, lod) * tex.readMultiplyFirst + tex.readAddSecond;
    }
#endforeach
#endif
*/

#endif
