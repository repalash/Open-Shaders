#ifdef GL_ES
precision highp float;
#endif

varying vec2 velocity;

void main() {
	gl_FragData[0] = vec4(velocity, 0.0, 0.0);
}
