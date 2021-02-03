#ifdef GL_ES
precision highp float;
#endif

uniform vec2 texelDirection;
uniform sampler2D shadowMap;
uniform float blurSize;

varying vec2 vUv;

const float MAX_BLUR_SIZE = 50.0;

void main() {
	float halfBlur = blurSize / 2.0;
	float count = 0.0;
	vec4 data = vec4(0.0, 0.0, 0.0, 0.0);
	for (float i = 0.0 ; i < MAX_BLUR_SIZE ; i++) {
		if (i >= blurSize)
			break;
		float offset = i - halfBlur;
		vec2 vOffset = vUv + (texelDirection * offset);
		if (vOffset.x >= 0.0 && vOffset.y >= 0.0 && vOffset.x <= 1.0 && vOffset.y <= 1.0) {
			vec4 dataS = texture2D(shadowMap, vOffset);
			if (dataS.r == 0.0) {
				data += dataS;
				count++;
			}
		}
	}
	gl_FragData[0] = count > 0.0 ? data / count : texture2D(shadowMap, vUv);
}

