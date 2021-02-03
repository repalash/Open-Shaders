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

void main() {
	gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
	
	vec4 matDiff = matDiffuse * matDiffuseColor;
	if (isTextured == 1)
		matDiff *= texture2D(diffMap, vUv);

	gl_FragColor += matDiff;
}
