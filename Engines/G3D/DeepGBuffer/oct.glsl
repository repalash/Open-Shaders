// -*- c++ -*-

#include <utilities.glsl>
#include <compatibility.glsl>

vec2 octEncode(in vec3 v) {
    float l1norm = abs(v.x) + abs(v.y) + abs(v.z);
    vec2 result = v.xy * (1.0/l1norm);
    if (v.z < 0.0) {
        result = (1.0 - abs(result.yx)) * signNotZero(result.xy);
    }
    return result;
}

vec3 octEncode3Components(in vec3 v) {
    float l1norm = abs(v.x) + abs(v.y) + abs(v.z);
    v *= (1.0/l1norm);
    if (v.z < 0.0) {
        v.xy = (1.0 - abs(v.yx)) * signNotZero(v.xy);
    }
    return v;
}

vec3 finalDecode(float x, float y) {
    vec3 v = vec3(x, y, 1.0 - abs(x) - abs(y));
    if (v.z < 0) {
        v.xy = (1.0 - abs(v.yx)) * signNotZero(v.xy);
    }
    return normalize(v);
}


vec3 decode2ComponentSnorm8(in uint x_int, in uint y_int) {
    float x = unpackSnorm8(x_int);
    float y = unpackSnorm8(y_int);
    return finalDecode(x,y);
}

vec3 decodeSnorm8(in uint p) {
    uint x_int, y_int;
    unpack2Norm8s(p, x_int, y_int);
    return decode2ComponentSnorm8(x_int, y_int);
}


vec3 decode2ComponentSnorm12(in uint x_int, in uint y_int) {
    float x = unpackSnorm12(x_int);
    float y = unpackSnorm12(y_int);
    return finalDecode(x,y);
}

vec3 decodeSnorm12(in uint p) {
    uint x_int, y_int;
    unpack2Norm12s(p, x_int, y_int);
    return decode2ComponentSnorm12(x_int, y_int);
}

vec3 decode2ComponentSnorm16(in uint x_int, in uint y_int) {
    float x = unpackSnorm16(x_int);
    float y = unpackSnorm16(y_int);
    return finalDecode(x,y);
}

vec3 decodeSnorm16(in uint p) {
    uint x_int, y_int;
    unpack2Norm16s(p, x_int, y_int);
    return decode2ComponentSnorm16(x_int, y_int);
}

vec3 decode16(in vec2 p) {
    return finalDecode(p.x, p.y);
}

vec3 decode32(in vec2 p) {
    return finalDecode(p.x, p.y);
}

vec2 unorm8x3_to_snorm12x2(vec3 u) {
	u *= 255.0;
	u.y *= (1.0 / 16.0);
	vec2 s = vec2(u.x * 16.0 + floor(u.y),
	fract(u.y) * (16.0 * 256.0) + u.z);
	return clamp(s * (1.0 / 2047.0) - 1.0, vec2(-1.0), vec2(1.0));
}

vec3 snorm12x2_to_unorm8x3(vec2 f) {
	vec2 u = vec2(round(clamp(f, -1.0, 1.0) * 2047 + 2047));
	float t = floor(u.y / 256.0);
	// This code assumes that rounding will occur during storage.
	// If storing to GL_RGB8UI, omit the - 0.5 and / 255 below
	return vec3(floor(u.x / 16.0),
	floor(fract(u.x / 16.0) * 256.0 + t),
	floor(u.y - t * 256.0)) / 255.0;
}

vec3 decode24(in vec3 p) {
    vec2 v = unorm8x3_to_snorm12x2(p);
    return finalDecode(v.x, v.y);
}


vec2 encode16(in vec3 v) {
    return octEncode(v);  
}

vec2 encode32(in vec3 v) {
    return octEncode(v);  
}

vec3 encode24(in vec3 v) {
	return snorm12x2_to_unorm8x3(octEncode(v));  
}
