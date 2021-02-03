#ifdef GL_ES
precision highp float;
#endif

varying vec4 worldPos;

void main() {
	// 4th coordinate : 0.0 to know it is not in the background
	vec4 pureWorldPos = modelMatrix * vec4(position, 1.0);
	worldPos = vec4(pureWorldPos.xyz, 0.0);

	gl_Position = projectionMatrix * viewMatrix * pureWorldPos;
}
