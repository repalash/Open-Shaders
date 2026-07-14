#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;

varying vec4 vertColor;
varying vec4 vertTexCoord;

uniform float amount;
uniform float speed;
uniform float time;

float random(vec2 n, float offset ){
	return .5 - fract(sin(dot(n.xy + vec2(offset, 0.), vec2(12.9898, 78.233)))* 43758.5453);
}

void main() {
	vec4 color = texture2D(texture, vertTexCoord.xy);
	color += vec4(vec3(amount * random(vertTexCoord.xy, .00001 * speed * time)), 1.);
	gl_FragColor = color;
}