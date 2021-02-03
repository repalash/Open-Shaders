#ifdef GL_ES
precision highp float;
#endif

// screen properties
uniform float screenWidth;
uniform float screenHeight;

uniform sampler2D texture;
varying vec2 vUv;

bool equals(float float1, float float2, float epsilon)
{
	return ((float1<=float2 + epsilon) && (float2-epsilon<=float1));
}

void main() {
	vec4 fourBytesX = texture2D(texture, vec2(gl_FragCoord.x/screenWidth, gl_FragCoord.y / screenHeight));		
//	vec4 fourBytesY = texture2D(texture2, vec2(gl_FragCoord.x/screenWidth,(gl_FragCoord.y) / screenHeight));
//	vec4 fourBytesZ = texture2D(texture3, vec2(gl_FragCoord.x/screenWidth,(gl_FragCoord.y)/ screenHeight));
//	vec4 fourBytesR = texture2D(texture4, vec2(gl_FragCoord.x/screenWidth,(gl_FragCoord.y) / screenHeight));
		
	float xCoord = (fourBytesX.x + fourBytesX.y * 256.0 + fourBytesX.z * 256.0 * 256.0 + fourBytesX.w * 256.0 * 256.0 * 256.0);//(256.0*256.0*256.0);
//	float xCoord = (fourBytesX.x + fourBytesX.y * 256.0 + fourBytesX.z * 256.0 * 256.0 + fourBytesX.w * 256.0 * 256.0 * 256.0)/(256.0*256.0*256.0);
//	float yCoord = (fourBytesY.x + fourBytesY.y * 256.0 + fourBytesY.z * 256.0 * 256.0 + fourBytesY.w * 256.0 * 256.0 * 256.0);///(256.0*256.0*256.0);
//	float zCoord = (fourBytesZ.x + fourBytesZ.y * 256.0 + fourBytesZ.z * 256.0 * 256.0 + fourBytesZ.w * 256.0 * 256.0 * 256.0);///(256.0*256.0*256.0);
//	float rCoord = (fourBytesR.x + fourBytesR.y * 256.0 + fourBytesR.z * 256.0 * 256.0 + fourBytesR.w * 256.0 * 256.0 * 256.0);//(256.0*256.0*256.0*256.0);
//	xCoord = fourBytesX.x;
	gl_FragColor = vec4(fourBytesX.x, fourBytesX.y, fourBytesX.z, fourBytesX.w);
//	gl_FragColor = vec4(xCoord, yCoord, zCoord, rCoord);
//	gl_FragColor = vec4(xCoord, yCoord, zCoord, 1.0);
//	gl_FragColor = vec4(xCoord, 0.0, 0.0, 1.0);
//	gl_FragColor = vec4(0.0, yCoord, 0.0, 1.0);
//	gl_FragColor = vec4(0.0, 0.0, zCoord, 1.0);
//	gl_FragColor = vec4(xCoord, xCoord, xCoord, rCoord);
		
//	gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
//	if(fourBytesX.x<=0.6)
//	if(equals(fourBytesX.x, 0.4, 0.1))
//	{
//		gl_FragColor = vec4(1.0, 0.0, 0.0, 1.0);
//	}
//	else
//	{
//		gl_FragColor = vec4(0.0, 1.0, 0.0, 1.0);
//	}
}
