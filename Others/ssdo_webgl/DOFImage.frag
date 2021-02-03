#ifdef GL_ES
precision highp float;
#endif

uniform sampler2D colorTexture;
uniform sampler2D normalsAndDepthBuffer;
uniform sampler2D dofBlur;
varying vec2 vUv;

uniform float blurCoefficient;
uniform float focusDistance;
uniform float near;
uniform float far;
uniform float PPM;

float GetBlurDiameter (float d) {
	// Convert from linear depth to metres
	float Dd = d;
	float xd = abs(Dd - focusDistance);
	float xdd = (Dd < focusDistance) ? (focusDistance - xd) : (focusDistance + xd);
	float b = blurCoefficient * (xd / xdd);

	return b * PPM;
}

void main() {
    // Maximum blur radius to limit hardware requirements.
    // Cannot #define this due to a driver issue with some setups
    const float MAX_BLUR_RADIUS = 10.0;
        
    // Get the colour, depth, and blur pixels
    vec4 colour = texture2D(colorTexture, vUv);
    float depth = texture2D(normalsAndDepthBuffer, vUv).a;
    vec4 blur = texture2D(dofBlur, vUv);
    
    // Linearly interpolate between the colour and blur pixels based on DOF
    float blurAmount = GetBlurDiameter(depth);
    float lerp = min(blurAmount / MAX_BLUR_RADIUS, 1.0);
    
    // Blend
    gl_FragColor = (colour * (1.0 - lerp)) + (blur * lerp);
}
