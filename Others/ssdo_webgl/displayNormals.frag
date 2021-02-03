#ifdef GL_ES
precision highp float;
#endif

uniform sampler2D texture;
varying vec2 vUv;

void main() {
	vec3 color = texture2D(texture, vUv).rgb * 0.5 + 0.5;
	gl_FragColor = vec4(color, 1.0);
}
