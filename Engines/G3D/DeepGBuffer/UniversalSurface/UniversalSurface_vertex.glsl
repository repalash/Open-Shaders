// -*- c++ -*-
/**
 \file UniversalSurface_vertex.glsl
 \author Morgan McGuire, Michael Mara

 Declares the input variables and provides a helper function transform() that computes the
 object-to-world space transformation and related vertex attributes.

 This is packaged separately from UniversalSurface_render.vrt to make it easy to compute 
 the object-space positions procedurally in related shaders but still use the material and
 lighting model from UniversalSurface.

 \beta

 \created 2007-10-22
 \edited  2014-04-04
 */
#ifndef UniversalSurface_vertex_h
#define UniversalSurface_vertex_h
#include <compatibility.glsl>

#expect HAS_VERTEX_COLORS
#expect NUM_LIGHTMAP_DIRECTIONS "0, 1, or 3"

#if __VERSION__ < 330
#   extension GL_ARB_separate_shader_objects : enable
#endif

#if (__VERSION__ < 420)
#   define layout(ignore)
#endif

#ifdef CUSTOMCONSTANT
    uniform vec4        customConstant;
#endif

/** Set to -1 to flip the normal for normal-offset shadow mapping.*/
uniform float       backside;


// Specify locations explicitly so that the geometry shader is not required 
// to match the vertex shader output names
varying layout(location=0) vec2 texCoord;
varying layout(location=1) vec3 wsPosition;
varying layout(location=2) vec3 tan_Z; 

#if (NUM_LIGHTMAP_DIRECTIONS > 0)
    varying layout(location=3) vec2 lightMapCoord;
#endif

#ifdef NORMALBUMPMAP  
    /** Tangent space to world space.
        Note that this will be linearly interpolated across the polygon. */
    varying layout(location=4) vec3 tan_X;
    varying layout(location=5) vec3 tan_Y;

#   if PARALLAXSTEPS > 0
        /** Vector to the eye in tangent space (needed for parallax) */
        varying layout(location=6) vec3 _tsE;
#   endif
#endif

#if HAS_VERTEX_COLORS
    varying layout(location=10) vec4 vertexColor;
#endif

#include <UniversalSurface/UniversalSurface_vertexHelpers.glsl>

#endif
