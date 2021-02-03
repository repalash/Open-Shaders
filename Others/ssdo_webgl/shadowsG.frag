#ifdef GL_ES
precision highp float;
#endif

uniform float PI;

uniform sampler2D shadowMap;
uniform sampler2D shadowMap1;
uniform int shadowMode;

// Lights
uniform mat4 lightsView[2];
uniform mat4 lightsProj[2];
uniform vec3 lightsPos[2];
uniform vec4 lightsColor[2];
uniform float lightsIntensity[2];
uniform float lightsAngle[2];
uniform float lightsAttenuation[2];
uniform float skyLightIntensity;
uniform float lightNearFar[2];

uniform sampler2D geometryBuffer;

// 3D point properties
varying vec2 vUv;
/*
vec3 unpackVec3FromFloat(float src) {
	float c3 = fract(src);
	float c2 = fract((src - c3) / 1024.0);
	float c1 = (src - c2) / 1048575.0;
	/*float c1 = src / 1048575.0;
	float c2 = (src - c1 * 1048575.0) / 1024.0;
	float c3 = (src - c1 * 1048575.0 - c2 * 1024.0);
	return vec3(c1, c2, c3);
}*/

vec3 unpackVec3FromFloat(float src) {
	const vec3 bitSh = vec3(1024.0 * 1024.0, 1024.0, 2.0);
	const vec3 bitMsk = vec3(0.0, 1.0 / 1024.0, 1.0 / 1024.0);

	vec3 result = fract(src * bitSh);
	result -= result.xxy * bitMsk;
	return result;
}

float getDepth(vec2 uv) {
	return texture2D(geometryBuffer, uv).r;
}

vec3 getNormal(vec2 uv) {
	return unpackVec3FromFloat(texture2D(geometryBuffer, uv).g) * 2.0 - 1.0;
}

vec3 getMatDiff(vec2 uv) {
	return unpackVec3FromFloat(texture2D(geometryBuffer, uv).b);
}

vec3 getWorldCoords(vec2 uv) {
	return unpackVec3FromFloat(texture2D(geometryBuffer, uv).a) * 1000.0 - 500.0;
}

float attenuation(vec3 dir, float div) {
	float dist = length(dir);
	float radiance = 1.0 / (1.0 + pow(dist * div / 100.0, 2.0));
	return clamp(radiance * 10.0, 0.0, 1.0); // * 10.0
}

float influence(vec3 normal, float coneAngle) {
	float minConeAngle = ((360.0 - coneAngle - 10.0) / 360.0) * PI;
	float maxConeAngle = ((360.0 - coneAngle) / 360.0) * PI;
	return smoothstep(minConeAngle, maxConeAngle, acos(normal.z));
}

float lambert(vec3 surfaceNormal, vec3 lightDirNormal) {
	return max(0.0, dot(surfaceNormal, lightDirNormal));
}

vec3 phong(vec3 p, vec3 n, int i) {
	vec3 v = normalize(cameraPosition - p);
	vec3 l = normalize(lightsPos[i] - p);
	float diffuse = max(dot(l, n), 0.0);
	vec3 r = reflect(-l, n);
	
	return vec3((diffuse * vec4(getMatDiff(vUv), 1.0)) * lightsColor[i] * lightsIntensity[i]);
}

vec3 skyLight(vec3 normal) {
	return vec3(smoothstep(0.0, PI, PI - acos(normal.y))) * skyLightIntensity;
}

vec3 gamma(vec3 color) {
	return pow(color, vec3(2.2));
}

float adaptDepth(float z) {
	return (z - lightNearFar[0]) / (lightNearFar[1] - lightNearFar[0]);
}

float linstep(float low, float high, float v){
    return clamp((v-low) / (high-low), 0.0, 1.0);
}

float VSM(sampler2D depths, vec2 uv, float compare){
    vec3 moments = texture2D(depths, uv).yzw;
	float linearizedDepth = adaptDepth(moments.z);
	float p = smoothstep(compare-0.02, compare, linearizedDepth);
	if (shadowMode == 1) {
		float variance = moments.x;
		float d = (compare - linearizedDepth) * 0.1;
		float p_max = linstep(0.2, 1.0, variance / (variance + d*d));
		return clamp(max(p, p_max), 0.0, 1.0);
	}
	return step(compare, linearizedDepth + 0.001);
}

void main() {
	gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
	vec4 worldPos = vec4(getWorldCoords(vUv), 1.0);
	//if (worldPos.a == 0.0) { // not in the background
		worldPos = vec4(worldPos.xyz, 1.0);
		vec3 p = vec3(worldPos);
		vec3 n = normalize(getNormal(vUv));
		for (int i = 0 ; i < 2 ; i++) {
			vec3 lightSpacePos = (lightsView[i] * worldPos).xyz;
			vec3 lightSpacePosNormalized = normalize(lightSpacePos);
			vec4 lightScreenSpacePos = lightsProj[i] * vec4(lightSpacePos, 1.0);
			vec2 lightSSpacePosNormalized = lightScreenSpacePos.xy / lightScreenSpacePos.w;
			vec2 lightUV = lightSSpacePosNormalized * 0.5 + 0.5;
			
			vec4 data;
			float visibility = 0.0;
			if (i == 0) {
				data = texture2D(shadowMap, lightUV);
				if (data.r == 0.0)
					visibility = VSM(shadowMap, lightUV, adaptDepth(length(lightSpacePos)));
			}
			else {
				data = texture2D(shadowMap1, lightUV);
				if (data.r == 0.0)
					visibility = VSM(shadowMap1, lightUV, adaptDepth(length(lightSpacePos)));
			}
			
			if (lightUV.x >= 0.0 && lightUV.x <= 1.0 && lightUV.y >= 0.0 && lightUV.y <= 1.0) {
				vec3 excident = (
					skyLight(n) +
					phong(p, n, i) *
					influence(lightSpacePosNormalized, lightsAngle[i]) *
					attenuation(lightSpacePos, lightsAttenuation[i]) *
					visibility *
					vec3(1.0, 1.0, 1.0)
				);
				gl_FragColor += vec4(gamma(excident), 1.0);
			}
		}
	//}
//	else
	//	gl_FragColor = vec4(0.2, 0.3, 0.4, 1.0);
}
