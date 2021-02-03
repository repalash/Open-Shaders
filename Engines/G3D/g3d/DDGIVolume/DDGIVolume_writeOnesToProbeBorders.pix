#version 400 // -*- c++ -*-
#include <g3dmath.glsl>


uniform int       probeSideLength;

out vec4 result;
out float gl_FragDepth;

void main() {

    result = vec4(0);

    // Write 1 to all border and edge pixels.
    if (any(lessThan(mod(ivec2(gl_FragCoord.xy), probeSideLength + 2), ivec2(2)))) {
        gl_FragDepth = 1.0f;
    }
    
}