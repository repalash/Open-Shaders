#ifdef GL_ES
precision highp float;
#endif

varying vec4 camSpacePos;
varying vec3 worldNormal;

void main() {
	camSpacePos = modelViewMatrix * vec4(position, 1.0);
	worldNormal = normalize(mat3(modelMatrix) * normal);
	
	gl_Position = projectionMatrix * camSpacePos;
}
