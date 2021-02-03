#ifdef GL_ES
precision highp float;
#endif

// Material properties
uniform float matSpecular;
uniform vec4 matSpecularColor;
uniform float shininess;
//uniform sampler2D texture;
//uniform int isTextured;

// 3D point properties
varying vec2 vUv;

void main() {
	gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
	
	vec4 matSpec = matSpecular * matSpecularColor;
	//if (isTextured == 1)
		//matSpec *= texture2D(texture, vUv);

	gl_FragColor += matSpec;
	gl_FragColor.a = shininess;
}
