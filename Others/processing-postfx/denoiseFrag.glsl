#ifdef GL_ES
precision mediump float;
precision mediump int;
#endif

#define PROCESSING_TEXTURE_SHADER

uniform sampler2D texture;

varying vec4 vertColor;
varying vec4 vertTexCoord;

uniform float exponent;
uniform vec2 resolution;

void main() {
	vec4 center = texture2D(texture, vertTexCoord.xy);
	vec4 color = vec4(0.0);
	float total = 0.0;
	for (float x = -4.0; x <= 4.0; x += 1.0) {
		for (float y = -4.0; y <= 4.0; y += 1.0) {
			vec4 s = texture2D(texture, vertTexCoord.xy + vec2(x, y) / resolution);
			float weight = 1.0 - abs(dot(s.rgb - center.rgb, vec3(0.25)));
			weight = pow(weight, exponent);
			color += s * weight;
			total += weight;
		}
	}
	gl_FragColor = color / total;
}