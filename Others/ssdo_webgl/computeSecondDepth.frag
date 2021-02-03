/**computeSecondDepth.frag
* Last modified : 26/06/13
* Compute the second level of depth for the depth peeling
* The back face culling needs to be disabled
*/

#ifdef GL_ES
precision highp float;
#endif

// input buffers
uniform sampler2D positionsBuffer;
uniform sampler2D normalsAndDepthBuffer;

// screen properties
uniform float screenWidth;
uniform float screenHeight;

varying vec4 camSpacePos;

vec4 spacePos(vec2 screenPos) {
	vec2 uv = vec2(screenPos.x / screenWidth, screenPos.y / screenHeight);
	return texture2D(positionsBuffer, uv);
}

float spaceDepth(vec2 screenPos) {
	vec2 uv = vec2(screenPos.x / screenWidth, screenPos.y / screenHeight);	
	return texture2D(normalsAndDepthBuffer, uv).a;
}

bool equals(float number1, float number2, float epsilon)
{
	bool isEqual = number1 < (number2 + epsilon) && number1 > (number2-epsilon);
	return isEqual;
}

void main() 
{
	float zBufferDepth = spaceDepth(gl_FragCoord.xy);
	float currentDepth = length(camSpacePos.xyz);
	float bias = 1.0;
	if(currentDepth<zBufferDepth + bias)
	{
		discard;
	}
	else
	{
		gl_FragData[0] = vec4(currentDepth, currentDepth, currentDepth, currentDepth);
	}

		
}
