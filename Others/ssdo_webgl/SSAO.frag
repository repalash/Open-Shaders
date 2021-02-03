/**SSAO.frag
* Last modified : 26/06/13
* Add the diffuse color to the ambient occlusion
*/

#ifdef GL_ES
precision highp float;
#endif

// input buffers
uniform sampler2D positionsBuffer;
uniform sampler2D normalsAndDepthBuffer;
uniform sampler2D diffuseTexture;
uniform sampler2D ssaoBuffer;

// lights properties
uniform vec3 lightsPos[2];
uniform vec4 lightsColor[2];
uniform float lightsIntensity[2];

varying vec2 vUv;

void main() 
{
	vec4 currentPos = texture2D(positionsBuffer, vUv);


	vec3 normal = texture2D(normalsAndDepthBuffer, vUv).xyz;
	float visibilityFactor = texture2D(ssaoBuffer, vUv).r;
		
	gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);

	// for each light
	for (int i = 0 ; i < 2 ; i++) 	
	{
		gl_FragColor +=	visibilityFactor * texture2D(diffuseTexture, vUv) * lightsColor[i] * lightsIntensity[i];
	}
}
