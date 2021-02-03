#ifdef GL_ES
precision highp float;
#endif

// multiply by : 
	// modelMatrix to go from model space to world space
	// viewMatrix = cameraViewInverse to go from world space to camera space
	// modelViewMatrix = viewMatrix * modelMatrix
		// model space to camera space
	// projectionMatrix to go from cam space to screen space

varying vec4 worldPos;
varying vec3 worldNormal;

void main() {
	worldPos = modelMatrix * vec4(position, 1.0);
	worldNormal = normalize(mat3(modelMatrix) * normal);

	gl_Position = projectionMatrix * viewMatrix * worldPos;
}