#version 410 or 460
/**
  \file data-files/shader/ParticleSurface/ParticleSurface_wireframe.geo

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#include <compatibility.glsl>
#include <g3dmath.glsl>

layout(points) in;

// If you are debugging where your actual triangles are, turn on.
#define SHOW_CENTER_VERTEX 0
#if SHOW_CENTER_VERTEX
layout(line_strip, max_vertices = 10) out;
#else
layout(line_strip, max_vertices = 5) out;
#endif


uniform float   nearPlaneZ;

// These arrays have a single element because they are GL_POINTS
layout(location = 0) in vec3    wsCenterVertexOutput[];
layout(location = 1) in vec3    shapeVertexOutput[];
layout(location = 2) in int4    materialIndexVertexOutput[];
layout(location = 3) in float   angleVertexOutput[];

/** Produce a vertex.  Note that x and y are compile-time constants, so 
    most of this arithmetic compiles out. */
void emit(float x, float y, Vector2 csRight, Vector2 csUp, Vector3 wsRight, Vector3 wsUp) {
    gl_Position = g3d_ProjectionMatrix * float4(gl_in[0].gl_Position.xy + csRight * x + csUp * y, gl_in[0].gl_Position.z, 1.0);
    EmitVertex();
}


void main() {
    float radius = shapeVertexOutput[0].x;
    float csZ    = gl_in[0].gl_Position.z;
    if (csZ >= nearPlaneZ) return; // culled by near plane

    float angle = angleVertexOutput[0];

    // Rotate the particle
    Vector2 csRight = float2(cos(angle), sin(angle)) * radius;
    Vector2 csUp    = float2(-csRight.y, csRight.x);

    Vector3 wsRight = g3d_CameraToWorldMatrix[0].xyz * csRight.x + g3d_CameraToWorldMatrix[1].xyz * csRight.y;
    Vector3 wsUp    = g3d_CameraToWorldMatrix[0].xyz * csUp.x    + g3d_CameraToWorldMatrix[1].xyz * csUp.y;
    
    // 
    //   C-------D    C-------D
    //   |       |    | \   / |
    //   |       |    |   E   |
    //   |       |    | /   \ |
    //   A-------B    A-------B
    //
    //     ABDCA       ABDCAEC DEB

    emit(-1, -1, csRight, csUp, wsRight, wsUp); // A
    emit(-1, +1, csRight, csUp, wsRight, wsUp); // B
    emit(+1, +1, csRight, csUp, wsRight, wsUp); // D
    emit(+1, -1, csRight, csUp, wsRight, wsUp); // C
    emit(-1, -1, csRight, csUp, wsRight, wsUp); // A
#   if SHOW_CENTER_VERTEX
        emit( 0,  0, csRight, csUp, wsRight, wsUp); // E
        emit(+1, -1, csRight, csUp, wsRight, wsUp); // C
        EndPrimitive();
        emit(+1, +1, csRight, csUp, wsRight, wsUp); // D
        emit( 0,  0, csRight, csUp, wsRight, wsUp); // E
        emit(-1, +1, csRight, csUp, wsRight, wsUp); // B
#   endif
    EndPrimitive();
}
