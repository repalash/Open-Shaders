#ifdef GL_ES
precision highp float;
#endif

uniform sampler2D texture;
uniform float lightNearFar[2];

// 3D point properties
varying vec4 P;
varying vec3 N;

varying vec2 vUv;

float adaptDepth(float z) {
	return (z - lightNearFar[0]) / (lightNearFar[1] - lightNearFar[0]);
}

void main() {
	vec4 depth = texture2D(texture, vUv);
	if (depth.r == 0.0) { // not in the background
		float color = adaptDepth(depth.a);
		gl_FragColor = vec4(color, color, color, 1.0);
	}
	else
		gl_FragColor = vec4(1.0, 1.0, 1.0, 1.0);
}
