#ifndef utilities_glsl
#define utilities_glsl

float signNotZero(in float k) {
    return k >= 0.0 ? 1.0 : -1.0;
}

vec2 signNotZero(in vec2 v) {
    return vec2( signNotZero(v.x), signNotZero(v.y) );
}


float packSnorm8Float(float f) {
    return round(clamp(f + 1.0, 0.0, 2.0) * float(127));
}

vec2 packSnorm8Float(vec2 v) {
    return vec2(packSnorm8Float(v.x), packSnorm8Float(v.y));
}

/** 
    One component version of the packSnorm functions here: http://www.opengl.org/sdk/docs/manglsl/xhtml/packUnorm2x16.xml  
    Values stored in the least significant 8 bits.
*/
uint packSnorm8(float f) {
    return uint(packSnorm8Float(f));
} 

float packSnormFloor8Float(float f) {
    return floor(clamp(f + 1.0, 0.0, 2.0) * float(127));
}

vec2 packSnormFloor8Float(vec2 v) {
    return vec2( packSnormFloor8Float(v.x), packSnormFloor8Float(v.y) );
}

uint packSnormFloor8(float f) {
    return uint( packSnormFloor8Float(f) );
}

float unpackSnorm8(float f) {
    return clamp((float(f) / float(127)) - 1.0, -1.0, 1.0);
}

/** 
    One component version of the unpackSnorm functions here: http://www.opengl.org/sdk/docs/manglsl/xhtml/unpackUnorm2x16.xml  
    Values were stored in the least significant 8 bits 
*/
float unpackSnorm8(uint u) {
    return unpackSnorm8(float(u));
}

vec2 unpackSnorm8(vec2 v) {
    return vec2(unpackSnorm8(v.x), unpackSnorm8(v.y));
}


float packUnorm8Float(float f) {
    //return uint(clamp(f, 0.0, 1.0) * float(255) + 0.5);
    return round(clamp(f, 0.0, 1.0) * float(255));
}

/** 
    One component version of the packUnorm functions here: http://www.opengl.org/sdk/docs/manglsl/xhtml/packUnorm2x16.xml  
    Values stored in the least significant 8 bits.
*/
uint packUnorm8(float f) {
    return uint(packUnorm8Float(f));
}

/** 
    One component version of the unpackUnorm functions here: http://www.opengl.org/sdk/docs/manglsl/xhtml/unpackUnorm2x16.xml  
    Values were stored in the least significant 8 bits 
*/
float unpackUnorm8(uint u) {
    return float(u) / float(255);
}

float unpackUnorm8(float u) {
    return float(u) / float(255);
}

uint signedFloatToUnorm8(float f) {
    return packUnorm8(f*0.5 + 0.5);
}

float unorm8ToSignedFloat(uint u) {
    return unpackUnorm8(u) * 2.0 - 1.0;
}

uint pack2Norm8s(uint u, uint v) {
    return (u << 8) + v;
}

void unpack2Norm8s(in uint p, out uint u, out uint v) {
    uint one = uint(1);
    u = p >> uint(8);
    v = p & ((one << uint(8)) - one);
}

uint packVec2Into2Unorm8s(vec2 v) {
    return pack2Norm8s(packUnorm8(v.x), packUnorm8(v.y));
}

uint packVec2Into2Snorm8s(vec2 v) {
    return pack2Norm8s(packSnorm8(v.x), packSnorm8(v.y));
}

vec2 unpack2Unorm8sIntoVec2(uint u) {
    uint x_int, y_int;
    unpack2Norm8s(u, x_int, y_int);
    return vec2(unpackUnorm8(x_int), unpackUnorm8(y_int));
}

vec2 unpack2Snorm8sIntoVec2(uint u) {
    uint x_int, y_int;
    unpack2Norm8s(u, x_int, y_int);
    return vec2(unpackSnorm8(x_int), unpackSnorm8(y_int));
}

float packSnorm12Float(float f) {
    return round(clamp(f + 1.0, 0.0, 2.0) * float(2047));
}

vec2 packSnorm12Float(vec2 v) {
    return vec2(packSnorm12Float(v.x), packSnorm12Float(v.y));
}

/** 
    One component version of the packSnorm functions here: http://www.opengl.org/sdk/docs/manglsl/xhtml/packUnorm2x16.xml  
    Values stored in the least significant 12 bits.
*/
uint packSnorm12(float f) {
    return uint(packSnorm12Float(f));
} 

float packSnormFloor12Float(float f) {
    return floor(clamp(f + 1.0, 0.0, 2.0) * float(2047));
}

vec2 packSnormFloor12Float(vec2 v) {
    return vec2( packSnormFloor12Float(v.x), packSnormFloor12Float(v.y) );
}

uint packSnormFloor12(float f) {
    return uint( packSnormFloor12Float(f) );
}

float unpackSnorm12(float f) {
    return clamp((float(f) / float(2047)) - 1.0, -1.0, 1.0);
}

/** 
    One component version of the unpackSnorm functions here: http://www.opengl.org/sdk/docs/manglsl/xhtml/unpackUnorm2x16.xml  
    Values were stored in the least significant 12 bits 
*/
float unpackSnorm12(uint u) {
    return unpackSnorm12(float(u));
}

vec2 unpackSnorm12(vec2 v) {
    return vec2(unpackSnorm12(v.x), unpackSnorm12(v.y));
}


float packUnorm12Float(float f) {
    return round(clamp(f, 0.0, 1.0) * float(4095));
}

/** 
    One component version of the packUnorm functions here: http://www.opengl.org/sdk/docs/manglsl/xhtml/packUnorm2x16.xml  
    Values stored in the least significant 12 bits.
*/
uint packUnorm12(float f) {
    return uint(packUnorm12Float(f));
}

/** 
    One component version of the unpackUnorm functions here: http://www.opengl.org/sdk/docs/manglsl/xhtml/unpackUnorm2x16.xml  
    Values were stored in the least significant 12 bits 
*/
float unpackUnorm12(uint u) {
    return float(u) / float(4095);
}

float unpackUnorm12(float u) {
    return float(u) / float(4095);
}

uint signedFloatToUnorm12(float f) {
    return packUnorm12(f*0.5 + 0.5);
}

float unorm12ToSignedFloat(uint u) {
    return unpackUnorm12(u) * 2.0 - 1.0;
}

uint pack2Norm12s(uint u, uint v) {
    return (u << 12) + v;
}

void unpack2Norm12s(in uint p, out uint u, out uint v) {
    uint one = uint(1);
    u = p >> uint(12);
    v = p & ((one << uint(12)) - one);
}

uint packVec2Into2Unorm12s(vec2 v) {
    return pack2Norm12s(packUnorm12(v.x), packUnorm12(v.y));
}

uint packVec2Into2Snorm12s(vec2 v) {
    return pack2Norm12s(packSnorm12(v.x), packSnorm12(v.y));
}

vec2 unpack2Unorm12sIntoVec2(uint u) {
    uint x_int, y_int;
    unpack2Norm12s(u, x_int, y_int);
    return vec2(unpackUnorm12(x_int), unpackUnorm12(y_int));
}

vec2 unpack2Snorm12sIntoVec2(uint u) {
    uint x_int, y_int;
    unpack2Norm12s(u, x_int, y_int);
    return vec2(unpackSnorm12(x_int), unpackSnorm12(y_int));
}

float packSnorm16Float(float f) {
    return round(clamp(f + 1.0, 0.0, 2.0) * float(32767));
}

vec2 packSnorm16Float(vec2 v) {
    return vec2(packSnorm16Float(v.x), packSnorm16Float(v.y));
}

/** 
    One component version of the packSnorm functions here: http://www.opengl.org/sdk/docs/manglsl/xhtml/packUnorm2x16.xml  
    Values stored in the least significant 16 bits.
*/
uint packSnorm16(float f) {
    return uint(packSnorm16Float(f));
} 

float packSnormFloor16Float(float f) {
    return floor(clamp(f + 1.0, 0.0, 2.0) * float(32767));
}

vec2 packSnormFloor16Float(vec2 v) {
    return vec2( packSnormFloor16Float(v.x), packSnormFloor16Float(v.y) );
}

uint packSnormFloor16(float f) {
    return uint( packSnormFloor16Float(f) );
}

float unpackSnorm16(float f) {
    return clamp((float(f) / float(32767)) - 1.0, -1.0, 1.0);
}

/** 
    One component version of the unpackSnorm functions here: http://www.opengl.org/sdk/docs/manglsl/xhtml/unpackUnorm2x16.xml  
    Values were stored in the least significant 16 bits 
*/
float unpackSnorm16(uint u) {
    return unpackSnorm16(float(u));
}

vec2 unpackSnorm16(vec2 v) {
    return vec2(unpackSnorm16(v.x), unpackSnorm16(v.y));
}


float packUnorm16Float(float f) {
    //return uint(clamp(f, 0.0, 1.0) * float(65535) + 0.5);
    return round(clamp(f, 0.0, 1.0) * float(65535));
}

/** 
    One component version of the packUnorm functions here: http://www.opengl.org/sdk/docs/manglsl/xhtml/packUnorm2x16.xml  
    Values stored in the least significant 16 bits.
*/
uint packUnorm16(float f) {
    return uint(packUnorm16Float(f));
}

/** 
    One component version of the unpackUnorm functions here: http://www.opengl.org/sdk/docs/manglsl/xhtml/unpackUnorm2x16.xml  
    Values were stored in the least significant 16 bits 
*/
float unpackUnorm16(uint u) {
    return float(u) / float(65535);
}

float unpackUnorm16(float u) {
    return float(u) / float(65535);
}

uint signedFloatToUnorm16(float f) {
    return packUnorm16(f*0.5 + 0.5);
}

float unorm16ToSignedFloat(uint u) {
    return unpackUnorm16(u) * 2.0 - 1.0;
}

uint pack2Norm16s(uint u, uint v) {
    return (u << 16) + v;
}

void unpack2Norm16s(in uint p, out uint u, out uint v) {
    uint one = uint(1);
    u = p >> uint(16);
    v = p & ((one << uint(16)) - one);
}

uint packVec2Into2Unorm16s(vec2 v) {
    return pack2Norm16s(packUnorm16(v.x), packUnorm16(v.y));
}

uint packVec2Into2Snorm16s(vec2 v) {
    return pack2Norm16s(packSnorm16(v.x), packSnorm16(v.y));
}

vec2 unpack2Unorm16sIntoVec2(uint u) {
    uint x_int, y_int;
    unpack2Norm16s(u, x_int, y_int);
    return vec2(unpackUnorm16(x_int), unpackUnorm16(y_int));
}

vec2 unpack2Snorm16sIntoVec2(uint u) {
    uint x_int, y_int;
    unpack2Norm16s(u, x_int, y_int);
    return vec2(unpackSnorm16(x_int), unpackSnorm16(y_int));
}


#define LOWER_8_MASK uint(255)

uvec3 packUInt24IntoUVec3(uint u) {
    return uvec3((u >> uint(16)),
                 (u >> uint(8)) & LOWER_8_MASK,
                 u & LOWER_8_MASK);
}

uint unpackUVec3IntoUInt(uvec3 u) {
    return u.z + (u.y << uint(8)) + (u.x << uint(16));
}

uvec3 vec2To2Unorm12sEncodedAsUVec3(vec2 v) {
    return packUInt24IntoUVec3(packVec2Into2Unorm12s(v));
}

uvec3 vec2To2Snorm12sEncodedAsUVec3(vec2 v) {
    return packUInt24IntoUVec3(packVec2Into2Snorm12s(v));
}

vec2 twoNorm12sEncodedAsUVec3InVec3FormatToPackedVec2(vec3 v) {
    vec2 s;
    // Roll the (*255s) in during the quasi bit shifting. This causes two of the three multiplications to happen at compile time
    float temp = v.y * (255.0/16.0);
    s.x = v.x * (255.0*16.0) + floor(temp);
    s.y =  fract(temp) * (16 * 256) + (v.z * 255.0);
    return s;
}

vec2 twoUnorm12sEncodedAsUVec3InVec3FormatToVec2(vec3 v) {
    vec2 s = twoNorm12sEncodedAsUVec3InVec3FormatToPackedVec2(v);
    return vec2(unpackUnorm12(s.x), unpackUnorm12(s.y));
}

vec2 twoSnorm12sEncodedAsUVec3InVec3FormatToVec2(vec3 v) {
    vec2 s = twoNorm12sEncodedAsUVec3InVec3FormatToPackedVec2(v);
    return vec2(unpackSnorm12(s.x), unpackSnorm12(s.y));
}

vec2 twoNorm12sEncodedAsUVec3ToPackedVec2(uvec3 u) {
    vec2 s;
    vec3 u_f = vec3(u);
    float temp = u_f.y * (1.0/16.0);
    s.x = u_f.x * 16.0 + floor(temp);
    s.y =  fract(temp) * (16 * 256) + u_f.z;
    return s;
}

vec2 twoUnorm12sEncodedAsUVec3ToVec2(uvec3 u) {
    vec2 s = twoNorm12sEncodedAsUVec3ToPackedVec2(u);
    return vec2(unpackUnorm12(s.x), unpackUnorm12(s.y));
}

vec2 twoSnorm12sEncodedAsUVec3ToVec2(uvec3 u) {
    vec2 s = twoNorm12sEncodedAsUVec3ToPackedVec2(u);
    return vec2(unpackSnorm12(s.x), unpackSnorm12(s.y));
}

vec3 twoNorm12sEncodedAs3Unorm8sInVec3Format(vec2 s) {
    vec3 u;
    u.x = s.x * (1.0/16.0);
    float t = floor(s.y*(1.0/256));
    u.y = (fract(u.x)*256) + t;
    u.z = s.y - (t * 256);
    // Instead of a floor, you could just add vec3(-0.5) to u, 
    // and the hardware will take care of the flooring for you on save to an RGB8 texture
    return floor(u) * (1.0 / 255.0);
}

vec3 vec2To2Snorm12sEncodedAs3Unorm8sInVec3Format(vec2 v) {
    vec2 s = vec2(packSnorm12Float(v.x), packSnorm12Float(v.y));
    return twoNorm12sEncodedAs3Unorm8sInVec3Format(s);
}

vec3 vec2To2Unorm12sEncodedAs3Unorm8sInVec3Format(vec2 v) {
    vec2 s = vec2(packUnorm12Float(v.x), packUnorm12Float(v.y));
    return twoNorm12sEncodedAs3Unorm8sInVec3Format(s);
}

#endif