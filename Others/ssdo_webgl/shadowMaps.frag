#extension GL_OES_standard_derivatives : enable
#extension GL_OES_texture_float : enable

#ifdef GL_ES
precision highp float;
#endif

uniform float lightNearFar[2];

// 3D point properties
varying vec4 camSpacePos;
varying vec3 worldNormal;

float adaptDepth(float z) {
	return (z - lightNearFar[0]) / (lightNearFar[1] - lightNearFar[0]);
}

void main() {
	float depth = length(camSpacePos.xyz);
	float d = adaptDepth(depth);
	float dx = dFdx(d);
	float dy = dFdy(d);
	float moment2 = pow(d, 2.0) + 0.25 * (dx*dx + dy*dy);
	float variance = max(moment2 - d*d, -0.001);
	gl_FragData[0] = vec4(0.0, variance, moment2, depth);
}
