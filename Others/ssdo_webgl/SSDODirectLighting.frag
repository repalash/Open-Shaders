/**SSDODirectLightingShader.frag
* Last modified : 26/06/13
* Computes the first pass (direct light) of the SSDO algorithm
*/

#ifdef GL_ES
precision highp float;
#endif

const int NUMBER_OF_SAMPLES_MAX = 32;

// input buffers
uniform sampler2D positionsBuffer;
uniform sampler2D normalsAndDepthBuffer;
uniform sampler2D secondDepthBuffer;
uniform sampler2D diffuseTexture;
uniform sampler2D randomTexture;
uniform sampler2D shadowMap;
uniform sampler2D shadowMap1;

// camera properties
uniform mat4 cameraProjectionM;
uniform mat4 cameraViewMatrix;

// lights properties
uniform mat4 lightsView[2];
uniform mat4 lightsProj[2];
uniform vec3 lightsPos[2];
uniform vec4 lightsColor[2];
uniform float lightsIntensity[2];

//3D point properties
varying vec2 vUv;

//SSDO parameters
uniform vec3 randomDirections[NUMBER_OF_SAMPLES_MAX];
uniform int numberOfSamples;
uniform float numberOfSamplesF;
uniform float rmax;
uniform float bias;

/**
* Compute the incoming radiance coming to the sample.
*/
vec4 computeRadiance(vec3 samplePosition)
{
	vec4 incomingRadiance = vec4(0.0,0.0,0.0,0.0);
	for(int j = 0 ; j < 2 ; j++)
	{
		//Visibility Test...
		vec4 lightSpacePos4 = lightsView[j] * vec4(samplePosition,1.0);
		vec3 lightSpacePos = lightSpacePos4.xyz/lightSpacePos4.w;
		vec3 lightSpacePosNormalized = normalize(lightSpacePos);
		vec4 lightScreenSpacePos = lightsProj[j] * vec4(lightSpacePos, 1.0);
		vec2 lightSSpacePosNormalized = lightScreenSpacePos.xy / lightScreenSpacePos.w;
		vec2 lightUV = lightSSpacePosNormalized * 0.5 + 0.5;

		float lightFar = 1000.0;
		float storedDepth = lightFar;
		vec4 data;
		if (j == 0)
		{
			data = texture2D(shadowMap, lightUV);
		}
		else
		{
			data = texture2D(shadowMap1, lightUV);
		}

		if (data.r == 0.0) // not in the background
		{
			storedDepth = data.a;
			float depth = clamp(storedDepth / lightFar, 0.0, 1.0);
			float currentDepth = clamp(length(lightSpacePos) / lightFar, 0.0, 1.0);

			if (lightUV.x >= 0.0 && lightUV.x <= 1.0 && lightUV.y >= 0.0 && lightUV.y <= 1.0) 
			{
				if(currentDepth <= depth + bias)//The light j sees the sample
				{
					incomingRadiance += lightsIntensity[j]*lightsColor[j];
				}
			}
		}
	}
	return incomingRadiance;
}

void main() 
{
	vec4 currentPos = texture2D(positionsBuffer, vUv);

	if (currentPos.a == 0.0) // the current point is not in the background
	{
		gl_FragColor = vec4(0.0, 0.0, 0.0, 1.0);
		vec3 position = currentPos.xyz;
		vec3 normal = normalize(texture2D(normalsAndDepthBuffer, vUv).xyz);
		vec4 color = vec4(0.0,0.0,0.0,0.0);
	
		//John Chapman SSAO implementation : http://john-chapman-graphics.blogspot.com/2013/01/ssao-tutorial.html
		//Precompute only numberOfSamples directions in the half positive hemisphere (randomDirections vector)
		//Add a random rotation (with normal axis)  when you put the direction in the normal space
		//Result : less noise due to random numbers
		vec3 vector = normalize(2.0*texture2D(randomTexture, vUv).xyz-1.0);
		vec3 tangent = normalize(vector - dot(vector,normal)*normal); //Dans le plan orthogonal à la normale (rotation aléatoire de la tangente)
		vec3 bitangent = normalize(cross(normal, tangent));
		mat3 normalSpaceMatrix = mat3(tangent, bitangent, normal);
	
		vec3 sampleDirection;
		vec3 samplePosition;
		vec4 projectionInCamSpaceSample;

		float r4;
		vec4 camSpaceSample; //sample is back projected in the camera space
		vec2 screenSpacePositionSampleNormalized; //(x,y) coordinates in screen space, normalize by the w coordinate
		vec2 sampleUV; // Screen space UV coordinates for the sample
		float distanceCameraSample; //Distance from the camera to the sample

		vec4 sampleProjectionOnSurface; 
		float distanceCameraSampleProjection;
		float secondDepth;
		float ii = 0.0; //i in float
	
		for(int i = 0 ; i < NUMBER_OF_SAMPLES_MAX ; i++)
		{
			if (i >= numberOfSamples)
				break;
			// random numbers
			sampleDirection = randomDirections[i];
			sampleDirection = normalize(normalSpaceMatrix * sampleDirection); //Put the sampleDirection in the normal Space (positive half space)
			r4 = texture2D(randomTexture, vUv).w*rmax; 

			samplePosition = position + bias*normal + r4 * sampleDirection;
			//Samples are back projected to the image
			camSpaceSample = cameraViewMatrix*vec4(samplePosition,1.0);
			projectionInCamSpaceSample = (cameraProjectionM * camSpaceSample);
			screenSpacePositionSampleNormalized = projectionInCamSpaceSample.xy/(projectionInCamSpaceSample.w);
			sampleUV = screenSpacePositionSampleNormalized*0.5 + 0.5;

			//Determines if the sample is visible or not
			distanceCameraSample = length((camSpaceSample).xyz/camSpaceSample.w);//Normalize with the 4th coordinate

			if(sampleUV.x >= 0.0 && sampleUV.x <= 1.0 && sampleUV.y >= 0.0 && sampleUV.y <= 1.0)
			{
				sampleProjectionOnSurface =  texture2D(positionsBuffer, sampleUV); //Projection of the sample on the surface displayed by the camera

				if (sampleProjectionOnSurface.a == 0.0) // not in the background
				{
					distanceCameraSampleProjection = texture2D(normalsAndDepthBuffer,sampleUV).a;//value of the z buffer
					if(distanceCameraSample > distanceCameraSampleProjection+bias) //if the sample is inside the surface it may be an occluder
					{
						secondDepth = texture2D(secondDepthBuffer, sampleUV).a;
						if(distanceCameraSample>secondDepth)//The sample is behind an object : it is visible
						{
							color += 2.0*texture2D(diffuseTexture,vUv)*max(dot(normal, sampleDirection),0.0)*computeRadiance(samplePosition)/numberOfSamplesF;
						}	

					}
					else
					{
						//Direct illumination is calculted with visible samples
						//compute the incoming radiance coming in the direction sampleDirection
						color += 2.0*texture2D(diffuseTexture,vUv)*max(dot(normal, sampleDirection),0.0)*computeRadiance(samplePosition)/numberOfSamplesF;
					}	
				}//End 	if (sampleProjectionOnSurface.a == 0.0) not in the background
				else//If the sample is in the background it is always visible
				{
						color += 2.0*texture2D(diffuseTexture,vUv)*max(dot(normal, sampleDirection),0.0)*computeRadiance(samplePosition)/numberOfSamplesF;
				}
			}//End SampleUV between  0.0 and 0.1
			ii += 1.0; 
		}//End for on samples
		gl_FragColor = vec4(clamp(color.xyz, 0.0,1.0), 1.0);
	}//End if (currentPos.a == 0.0) // the current point is not in the background
	else
	{
		gl_FragColor = vec4(0.2, 0.3, 0.4, 1.0);
	}
	
}

