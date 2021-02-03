/** -*- c++ -*-
 \file UniversalSurface/UniversalSurface_SVO.geo
 */
#version 420
#include <compatibility.glsl>

layout(triangles) in;
layout(triangle_strip, max_vertices = 3) out;

// Specify locations explicitly so that the names can differ between 
// stages.
in layout(location=0) vec2 texCoord_in[3];
out layout(location=0) vec2 texCoord;

in layout(location=1) vec3 wsPosition_in[3];
out layout(location=1) vec3 wsPosition;

in layout(location=2) vec3 tan_Z_in[3]; 
out layout(location=2) vec3 tan_Z;

#if defined(NUM_LIGHTMAP_DIRECTIONS) && (NUM_LIGHTMAP_DIRECTIONS > 0)
    in layout(location=3) vec2 lightMapCoord_in[3];
    out layout(location=3) vec2 lightMapCoord;
#endif

#ifdef NORMALBUMPMAP  
    /** Tangent space to world space.
        Note that this will be linearly interpolated across the polygon. */
    in layout(location=4) vec3 tan_X_in[3];
    out layout(location=4) vec3 tan_X;

    in layout(location=5) vec3 tan_Y_in[3];
    out layout(location=5) vec3 tan_Y;

#   if PARALLAXSTEPS > 0
        /** Vector to the eye in tangent space (needed for parallax) */
        in layout(location=6) vec3 _tsE_in[3];
        out layout(location=6) vec3 _tsE;
#   endif
#endif

#if defined(CS_POSITION_CHANGE) || defined(SS_POSITION_CHANGE)
    in layout(location=7) vec3 csPrevPosition_in[3];
    out layout(location=7) vec3 csPrevPosition;
#endif

#ifdef SVO_POSITION
    out layout(location=8) vec3			svoPosition;
	flat out layout(location=9) int		triangleAxis;
#endif
	

void main() {
    vec3 axisMagnitude = abs(cross(gl_in[1].gl_Position.xyz - gl_in[0].gl_Position.xyz, gl_in[2].gl_Position.xyz - gl_in[0].gl_Position.xyz));
    float axisMax = max(axisMagnitude.x, max(axisMagnitude.y, axisMagnitude.z));

    // Choose an orthographic projection based on the primary axis
    mat2x3 P;
    if (axisMagnitude.x == axisMax) {
        P = mat2x3(0, 0, 1,   0, 1, 0);
#ifdef SVO_POSITION
		triangleAxis=2;
#endif
    } else if (axisMagnitude.y == axisMax) {
        P = mat2x3(1, 0, 0,   0, 0, 1);
#ifdef SVO_POSITION
		triangleAxis=1;
#endif
    } else { // z
        P = mat2x3(1, 0, 0,   0, 1, 0);
#ifdef SVO_POSITION
		triangleAxis=0;
#endif
    }


    for (int i = 0; i < 3; ++i) {

        // Copy over most vertex properties
        texCoord    = texCoord_in[i];
        wsPosition  = wsPosition_in[i];
        tan_Z       = tan_Z_in[i]; 

#       if defined(NUM_LIGHTMAP_DIRECTIONS) && (NUM_LIGHTMAP_DIRECTIONS > 0)
            lightMapCoord = lightMapCoord_in[i];
#       endif

#       ifdef NORMALBUMPMAP  
            tan_X = tan_X_in[i];
            tan_Y = tan_Y_in[i];

#           if PARALLAXSTEPS > 0
                _tsE = _tsE_in[i];
#           endif
#       endif

#       if defined(CS_POSITION_CHANGE) || defined(SS_POSITION_CHANGE)
            csPrevPosition = csPrevPosition_in[i];
#       endif

        // Projection (gl_in[i].gl_Position should be on [0, 1] within the bounding box of the oct-tree)
#       ifdef SVO_POSITION
			//svoPosition[i] doesn't generate a compilation error !!	-> compiler bug ?
            svoPosition = (gl_in[i].gl_Position.xyz+1.0f)*0.5f;
#       endif

        // Map to OpenGL [-1, 1]
        //gl_Position = vec4(gl_in[i].gl_Position.xyz * P * 2 - 1, 0, 1);
		gl_Position = vec4(gl_in[i].gl_Position.xyz * P, 0, 1);

        EmitVertex();
    }

    EndPrimitive();
}