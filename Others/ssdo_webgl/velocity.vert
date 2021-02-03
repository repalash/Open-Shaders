#ifdef GL_ES
precision highp float;
#endif

uniform mat4 previousViewMatrix; // camera
uniform mat4 previousModelMatrix; // object
uniform vec2 texelSize;
uniform float intensity;

varying vec2 velocity;

void main() {
	vec4 worldPos = modelMatrix * vec4(position, 1.0);
	vec4 currentProjPos = projectionMatrix * viewMatrix * worldPos;
	vec4 currentProjPos2 = currentProjPos / currentProjPos.w;
	vec4 previousProjPos = projectionMatrix * previousViewMatrix * previousModelMatrix * vec4(position, 1.0);
	previousProjPos /= previousProjPos.w;
	velocity = vec2(currentProjPos2 - previousProjPos) * texelSize * intensity;
	
	gl_Position = currentProjPos;
}