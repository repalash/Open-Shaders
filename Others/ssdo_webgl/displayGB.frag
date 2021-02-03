#ifdef GL_ES
precision highp float;
#endif

uniform sampler2D texture;
varying vec2 vUv;

float adaptDepth(float z) {
	return (z - 0.1) / (10000.0 - 0.1);
}

/*vec3 unpackVec3FromFloat(float src) {
	float c3 = fract(src);
	float c2 = fract((src - c3) / 1024.0);
	float c1 = (src - c2) / 1048575.0;
	/*float c1 = floor(src / 1048575.0);
	float c2 = floor((src - c1 * 1048575.0) / 1024.0);
	float c3 = (src - c1 * 1048575.0 - c2 * 1024.0);
	return vec3(c1, c2, c3);
}*/

vec3 unpackVec3FromFloatB(float src) {
	const vec3 bitSh = vec3(1024.0 * 1024.0, 1024.0, 1.0);
	const vec3 bitMsk = vec3(0.0, 1.0 / 1024.0, 1.0 / 1024.0);

	vec3 result = fract(src * bitSh);
	result.y -= result.x / 1024.0;
	result.z -= result.y / 1024.0;
	//result -= result.xxy * bitMsk;
	return result;
}

void main() {
	//float color = adaptDepth(texture2D(texture, vUv).r);
	//vec3 color = unpackVec3FromFloatB(texture2D(texture, vUv).g);
	vec3 color = unpackVec3FromFloatB(texture2D(texture, vUv).b) / 0.9;
	
	gl_FragColor = vec4(color.x, color.y, color.z, 1.0);
}
