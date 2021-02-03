#ifdef GL_ES
precision highp float;
#endif

varying vec4 worldPos;
varying vec3 worldNormal;
varying vec2 vUv;

void main() {
	worldPos = modelMatrix * vec4(position, 1.0);
	worldNormal = normalize(mat3(modelMatrix) * normal);
	vUv = uv;

	gl_Position = projectionMatrix * viewMatrix * worldPos;
}