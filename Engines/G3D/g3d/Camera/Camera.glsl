/**
  \file data-files/shader/Camera/Camera.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/

#ifndef Camera_glsl
#define Camera_glsl

#include <compatibility.glsl>
#include <reconstructFromDepth.glsl>

/**
 \def uniform_Camera

 Declares frame (CameraToWorld matrix), previousFrame, projectToPixelMatrix, clipInfo, and projInfo.
 On the host, invoke Camera::setShaderArgs
 to pass these values. Unused variables in the device 
 shader will be removed by the compiler.

 \param name Include the underscore suffix, if a name is desired

 \sa G3D::Camera, G3D::Camera::setShaderArgs, G3D::Args, uniform_GBuffer

 \deprecated
 */
#define uniform_Camera(name)\
    uniform mat4x3 name##frame;\
    uniform mat4x3 name##previousFrame;\
    uniform mat4x4 name##projectToPixelMatrix;\
    uniform float3 name##clipInfo;\
    uniform ProjInfo name##projInfo;\
    uniform float2 name##pixelOffset;\
    uniform float name##nearPlaneZ;\
    uniform float name##farPlaneZ

/**  
  Important properties of a G3D::Camera

  Bind this from C++ by calling camera->setShaderArgs("camera.");

  \sa G3D::Camera, G3D::Camera::setShaderArgs, G3D::Args, uniform_GBuffer */
struct Camera {
    mat4x3 frame;
    mat4x3 invFrame;
    mat4x3 previousFrame;
    mat4x4 projectToPixelMatrix;
    float3 clipInfo;
    ProjInfo projInfo;
    float2 pixelOffset;
    float nearPlaneZ;
    float farPlaneZ;
};
    
#endif
