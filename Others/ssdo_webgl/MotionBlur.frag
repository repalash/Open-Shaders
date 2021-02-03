#ifdef GL_ES
precision highp float;
#endif

uniform sampler2D colorTexture;
uniform sampler2D velocityTexture;
varying vec2 vUv;
uniform float samplesNumber;

const float MAX_SAMPLES_NUMBER = 50.0;

void main() {
	vec4 color = texture2D(colorTexture, vUv); 
	vec2 velocity = texture2D(velocityTexture, vUv).xy;
	vec2 uv = vUv - velocity; 
	float count = 0.0;
	for (float i = 1.0 ; i < MAX_SAMPLES_NUMBER ; ++i, uv -= velocity) {  
		if (i >= samplesNumber)
			break;
		if (uv.x >= 0.0 && uv.y >= 0.0 && uv.x <= 1.0 && uv.y <= 1.0) {
			color += texture2D(colorTexture, uv);
			count++;
		}
	}
	gl_FragColor = count > 0.0 ? color / count : color;
}
