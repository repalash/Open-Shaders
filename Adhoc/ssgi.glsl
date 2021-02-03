#version 420
// https://github.com/jdupuy/ssgi/blob/master/src/shaders/ssgi.glsl

#ifndef SAMPLE_CNT
#	error SAMPLE_CNT undefined
#endif
#define PI 3.14


// --------------------------------------------------
// Uniforms
// --------------------------------------------------
uniform sampler2D sNoise;  // random vectors
uniform sampler2DRect sNd; // normal + depth
uniform sampler2DRect sKa; // albedo

uniform vec2 uScreenSize;  // screen dimensions
uniform vec2 uClipZ;       // clipping planes
uniform vec2 uTanFovs;     // tangent of field of views
uniform vec3 uLightPos;    // ligh pos in view space
uniform int uSampleCnt;    // number of samples
uniform float uRadius;     // radius size
uniform float uGiBoost;    // gi boost

layout(std140)
uniform Samples {
    vec4 uSamples[SAMPLE_CNT]; // sampling directions
};

// --------------------------------------------------
// Functions
// --------------------------------------------------
// get the view position of a sample from its depth
// and eye information
vec3 ndc_to_view(vec2 ndc,
float depth,
vec2 clipPlanes,
vec2 tanFov);
vec2 view_to_ndc(vec3 view,
vec2 clipPlanes,
vec2 tanFov);


// --------------------------------------------------
// Vertex shader
// --------------------------------------------------
#ifdef _VERTEX_
layout(location=0) out vec2 oTexCoord;
void main() {
    oTexCoord = vec2(gl_VertexID & 1, gl_VertexID >> 1 & 1);
    gl_Position = vec4(oTexCoord*2.0-1.0,0,1);
}
    #endif //_VERTEX_


    // --------------------------------------------------
    // Fragment shader
    // --------------------------------------------------
    #ifdef _FRAGMENT_
layout(location=0) in vec2 iTexCoord;
layout(location=0) out vec4 oColour;
void main() {
    const float ATTF = 1e-5; // attenuation factor
    vec2 st = iTexCoord*uScreenSize;
    vec4 t1 = texture(sNd,st);      // read normal + depth
    vec3 t2 = texture(sKa,st).rgb; // colour
    vec3 n = t1.rgb*2.0-1.0; // rebuild normal
    vec3 p = ndc_to_view(iTexCoord*2.0-1.0, t1.a, uClipZ, uTanFovs); // get view pos
    vec3 l = uLightPos - p; // light vec
    float att = 1.0+ATTF*length(l);
    float nDotL = max(0.0,dot(normalize(l),n));
    oColour.rgb = t2*nDotL/(att*att);

    #if defined GI_SSAO
    float occ = 0.0;
    float occCnt = 0.0;
    vec3 rvec = normalize(texture(sNoise, gl_FragCoord.xy/64.0).rgb*2.0-1.0);
    for(int i=0; i<uSampleCnt && t1.a < 1.0; ++i) {
        vec3 dir = reflect(uSamples[i].xyz,rvec); // a la Crysis
        dir -= 2.0*dir*step(dot(n,dir),0.0);      // a la Starcraft
        vec3 sp = p + (dir * uRadius) * (t1.a * 1e2); // scale radius with depth
        vec2 spNdc = view_to_ndc(sp, uClipZ, uTanFovs); // get sample ndc coords
        bvec4 outOfScreen = bvec4(false); // check if sample projects to screen
        outOfScreen.xy = lessThan(spNdc, vec2(-1));
        outOfScreen.zw = greaterThan(spNdc, vec2(1));
        if(any(outOfScreen)) continue;
        vec4 spNd = texture(sNd,(spNdc*0.5 + 0.5)*uScreenSize); // get nd data
        vec3 occEye = -sp/sp.z*(spNd.a*uClipZ.x+uClipZ.y); // compute correct pos
        vec3 occVec = occEye - p; // vector
        float att2 = 1.0+ATTF*length(occVec); // quadratic attenuation
        occ += max(0.0,dot(normalize(occVec),n)-0.25) / (att2*att2);
        ++occCnt;
    };
    oColour.rgb*= occCnt > 0.0 ? vec3(1.0-occ*uGiBoost/occCnt) : vec3(1);
#elif defined GI_SSDO
    vec3 gi = vec3(0.0);
    float giCnt = 0.0;
    vec3 rvec = normalize(texture(sNoise, gl_FragCoord.xy/64.0).rgb*2.0-1.0);
    for(int i=0; i<uSampleCnt && t1.a < 1.0; ++i) {
        vec3 dir = reflect(uSamples[i].xyz,rvec); // a la Crysis
        dir -= 2.0*dir*step(dot(n,dir),0.0);      // a la Starcraft
        vec3 sp = p + (dir * uRadius) * (t1.a * 1e2); // scale radius with depth
        vec2 spNdc = view_to_ndc(sp, uClipZ, uTanFovs); // get sample ndc coords
        bvec4 outOfScreen = bvec4(false); // check if sample projects to screen
        outOfScreen.xy = lessThan(spNdc, vec2(-1));
        outOfScreen.zw = greaterThan(spNdc, vec2(1));
        if(any(outOfScreen)) continue;
        vec2 spSt = (spNdc*0.5 + 0.5)*uScreenSize;
        vec4 spNd = texture(sNd,spSt); // get nd data
        vec3 occEye = -sp/sp.z*(spNd.a*uClipZ.x+uClipZ.y); // compute correct pos //samplePosition
        vec3 occVec = occEye - p; // vector
        float att2 = 1.0+ATTF*length(occVec); // quadratic attenuation
        vec3 spL = uLightPos - occEye; // sample light vec
        vec3 spKa = texture(sKa, spSt).rgb; // sample albedo
        vec3 spN = spNd.rgb*2.0-1.0; // sample normal
        float spAtt = 1.0+ATTF*length(spL); // quadratic attenuation
        vec3 spE = spKa*max(0.0,dot(normalize(spL),spN))/(spAtt*spAtt); // can precomp.
        float v = 1.0-max(0.0,dot(n,spN));
        gi+= spE*v*max(0.0,dot(normalize(occVec),n))/(att2*att2);
        ++giCnt;
    };
    oColour.rgb+= giCnt > 0.0 ? t2*gi*nDotL*uGiBoost/giCnt : vec3(0);
    #endif // GI_SSAO
}
    #endif // _FRAGMENT_


// --------------------------------------------------
// Functions impl.
// --------------------------------------------------
vec3 ndc_to_view(vec2 ndc,
float depth,
vec2 clipPlanes,
vec2 tanFov) {
    // go from [0,1] to [zNear, zFar]
    float z = depth * clipPlanes.x + clipPlanes.y;
    // view space position
    return vec3(ndc * tanFov, -1) * z;
}

vec2 view_to_ndc(vec3 view,
vec2 clipPlanes,
vec2 tanFov) {
    return -view.xy / (tanFov*view.z);
}


