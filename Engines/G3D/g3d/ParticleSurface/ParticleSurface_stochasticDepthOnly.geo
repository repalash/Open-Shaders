#version 410 or 460
/**
  \file data-files/shader/ParticleSurface/ParticleSurface_stochasticDepthOnly.geo

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#include <compatibility.glsl>
#include <g3dmath.glsl>

// Need to remove discard statements from the following files
#define discard

// needed to make the bump map code compile on AMD GPUs,
// which don't eliminate the dead code before compiling it for
// this GS profile
#define dFdx(g) ((g) * 0.0)   
#define dFdy(g) ((g) * 0.0)  

#include <UniversalMaterial/UniversalMaterial.glsl>
#include <UniversalMaterial/UniversalMaterial_sample.glsl>
#undef discard

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;


uniform UniversalMaterial2DArray material;

// These arrays have a single element because they are GL_POINTS
layout(location = 0) in Point3       wsCenterVertexOutput[];
layout(location = 1) in float3       shapeVertexOutput[];
layout(location = 2) in int4         materialPropertiesVertexOutput[];
layout(location = 3) in float        angleVertexOutput[];

// Output
out Point3      wsPosition;
out Point3      texCoord;
flat out float  textureID;

float3 wsRight, wsUp;
float2 csRight, csUp;

int texelWidth = materialPropertiesVertexOutput[0].y;

/** Produce a vertex.  Note that x and y are compile-time constants, so 
    most of this arithmetic compiles out. */
void emit(float x, float y) {
    Point3 csPosition = Vector3(gl_in[0].gl_Position.xy + csRight * x + csUp * y, gl_in[0].gl_Position.z);
    gl_Position = g3d_ProjectionMatrix * float4(csPosition, 1.0);
    wsPosition  = wsCenterVertexOutput[0] + wsRight * x + wsUp * y;    
    texCoord.xy = Point2(x, y) * (0.5 * float(texelWidth) * material.lambertian.invSize.xy) + Vector2(0.5, 0.5);
    texCoord.z  = materialPropertiesVertexOutput[0].x;
    EmitVertex();
}


/** Mask for materialProperties[3] */
const int CASTS_SHADOWS    = 1;

void main() {
    float csZ = gl_in[0].gl_Position.z;
    if ((csZ >= 0) || ((materialPropertiesVertexOutput[0].z & CASTS_SHADOWS) == 0)) {
        // culled by near plane or not shadow casting
        return;
    }

    // Do not rotate during shadow casting...it causes too much noise in the texture
    const float angle = 0.0;

    // Rotate the particle
    float radius = shapeVertexOutput[0].x;
    csRight = Vector2(cos(angle), sin(angle)) * radius;
    csUp    = Vector2(-csRight.y, csRight.x);
    
    wsRight = g3d_CameraToWorldMatrix[0].xyz * csRight.x + g3d_CameraToWorldMatrix[1].xyz * csRight.y;
    wsUp    = g3d_CameraToWorldMatrix[0].xyz * csUp.x    + g3d_CameraToWorldMatrix[1].xyz * csUp.y;

    emit(-1, -1);
    emit(+1, -1);
    emit(-1, +1);
    emit(+1, +1);
  
    EndPrimitive();
}
