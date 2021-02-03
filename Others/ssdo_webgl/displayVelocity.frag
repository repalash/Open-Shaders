#ifdef GL_ES
precision highp float;
#endif

uniform sampler2D texture;
varying vec2 vUv;

void main() {
	vec2 velocity = texture2D(texture, vUv).xy * 0.5 + 0.5;
	gl_FragData[0] = vec4(velocity, 1.0, 1.0);
}
