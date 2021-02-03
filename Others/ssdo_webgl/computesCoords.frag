#ifdef GL_ES
precision highp float;
#endif

// 3D point properties
varying vec4 worldPos;

void main() {
	gl_FragData[0] = worldPos;
}
