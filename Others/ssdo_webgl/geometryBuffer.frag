#ifdef GL_ES
precision highp float;
#endif

// Material properties
uniform float matDiffuse;
uniform vec4 matDiffuseColor;
uniform sampler2D diffMap;
uniform int isTextured;

// 3D point properties
varying vec2 vUv;

// 3D point properties
varying vec4 worldPos;
varying vec3 worldNormal;

// each component of src is in the range [0,1]
/*float packVec3ToFloat(vec3 src) {
	return floor(src.x * 1048575.0) + floor(src.y * 1024.0) + src.z;
}*/

// each component of src is in the range [0,1]
float packVec3ToFloatB(vec3 src) {
	const vec3 unshift = vec3(1.0 / (1024.0 * 1024.0), 1.0 / 1024.0, 1.0);
	return dot(src, unshift);
}

vec4 packData(float depth, vec3 normal, vec3 matDiff, vec3 worldCoord) {
	return vec4(depth, packVec3ToFloatB((normal + 1.0) * 0.5), packVec3ToFloatB(matDiff * 0.9), packVec3ToFloatB((worldCoord + 500.0) / 1000.0));
}

void main() {
	// depth
	float zBuffer = length(worldPos.xyz - cameraPosition.xyz);
	// normal
	vec3 normal = normalize(worldNormal);
	// diffuse color
	vec4 matDiff4 = matDiffuse * matDiffuseColor;
	/*if (isTextured == 1)
		matDiff4 *= texture2D(diffMap, vUv);*/
	vec3 matDiff = matDiff4.xyz;
	
	
	gl_FragData[0] = packData(zBuffer, normal, matDiff, vec3(worldPos));
}
