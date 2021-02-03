/**SSDOIndirectBounceShader.frag
* Last modified : 26/06/13
* Computes the second pass (indirect light) of the SSDO algorithm
*/

#ifdef GL_ES
precision highp float;
#endif
const int NUMBER_OF_SAMPLES_MAX = 32;

// input buffers
uniform sampler2D directLightBuffer;
uniform sampler2D directLightBuffer90;
uniform sampler2D positionsBuffer;
uniform sampler2D positionsBuffer90;
uniform sampler2D normalsAndDepthBuffer;
uniform sampler2D normalsAndDepthBuffer90;
uniform sampler2D secondDepthBuffer;
uniform sampler2D diffuseTexture;
uniform sampler2D randomTexture;
uniform sampler2D randomDirectionsTexture;
uniform sampler2D shadowMap;
uniform sampler2D shadowMap1;

// camera properties
uniform mat4 cameraProjectionM;
uniform mat4 cameraViewMatrix;
uniform mat4 cameraProjectionM90;
uniform mat4 cameraViewMatrix90;

// lights properties
uniform mat4 lightsView[2];
uniform mat4 lightsProj[2];
uniform vec3 lightsPos[2];
uniform vec4 lightsColor[2];
uniform float lightsIntensity[2];

//SSDO parameters
uniform vec3 randomDirections[NUMBER_OF_SAMPLES_MAX];
uniform int numberOfSamples;
uniform float numberOfSamplesF;
uniform float rmax;
uniform float bounceIntensity;
uniform float bias;

varying vec2 vUv;

uniform int enableMultipleViews;

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
		vec3 vector = normalize(2.0*texture2D(randomTexture,  vUv).xyz-1.0);
		vec3 tangent = normalize(vector - dot(vector,normal)*normal); //Dans le plan orthogonal à la normale
		vec3 bitangent = normalize(cross(normal, tangent));
		
		mat3 normalSpaceMatrix = mat3(tangent, bitangent, normal);
		mat3 normalSpaceMatrixInverse;

		vec3 sampleDirection;
		vec3 samplePosition;
		vec4 projectionInCamSpaceSample;

		float r4;
		vec4 camSpaceSample; //sample is back projected in the camera space
		vec2 screenSpacePositionSampleNormalized; //(x,y) coordinates in screen space, normalize by the w coordinate
		vec2 sampleUV; //Screen space UV coordinates for the sample
		float distanceCameraSample;//Distance from the camera to the sample

		vec4 sampleProjectionOnSurface;


		float ii = 0.0;
		for(int i = 0 ; i<NUMBER_OF_SAMPLES_MAX ; i++)
		{
			if (i >= numberOfSamples)
				break;
			sampleDirection = randomDirections[i];
			sampleDirection = normalize(normalSpaceMatrix * sampleDirection); //Put the sampleDirection in the normal Space (positive half space)
			
			r4 = texture2D(randomTexture, vUv).w * rmax; 
			samplePosition = position + bias*normal + r4*sampleDirection;

			//Samples are back projected to the image
			projectionInCamSpaceSample= (cameraProjectionM * cameraViewMatrix * vec4(samplePosition, 1.0));
			screenSpacePositionSampleNormalized = projectionInCamSpaceSample.xy/(projectionInCamSpaceSample.w);
			sampleUV = screenSpacePositionSampleNormalized*0.5 + 0.5; //UV coordinates

			//Determines if the sample is visible or not
			camSpaceSample = cameraViewMatrix*vec4(samplePosition,1.0);
			distanceCameraSample = length((camSpaceSample).xyz/camSpaceSample.w);//Normalize with the 4th coordinate
			sampleProjectionOnSurface =  texture2D(positionsBuffer, sampleUV);

				if (sampleProjectionOnSurface.a == 0.0) // not in the background
				{
					vec4 cameraSpaceProjection = cameraViewMatrix * sampleProjectionOnSurface;
					vec3 sampleNormalOnSurface = normalize(texture2D(normalsAndDepthBuffer, sampleUV).xyz);//Normal

					float distanceCameraSampleProjection = texture2D(normalsAndDepthBuffer,sampleUV).a;
					//The distance between the sender and the receiver is clamped to 1.0 to avoid singularity problems
					vec3 transmittanceDirection =	position - sampleProjectionOnSurface.xyz;
					float distanceSenderReceiver = clamp(length(transmittanceDirection), 0.0, 1.0);
					transmittanceDirection = normalize(transmittanceDirection);

					if(distanceCameraSample > distanceCameraSampleProjection+bias) //if the sample is inside the surface it may be an occluder
					{
						//The sample is an eventual occluder
						//Verification with depth peeling
						float secondDepth = texture2D(secondDepthBuffer, sampleUV).a;
						if(distanceCameraSample < secondDepth) //The sample is inside an object
						{
							vec4 directLightingVector = texture2D(directLightBuffer,sampleUV);
							vec3 normalSpaceSampleProjectionOnSurface = normalSpaceMatrix* sampleProjectionOnSurface.xyz;
							if( normalSpaceSampleProjectionOnSurface.z >= 0.0) //Consider samples projections that are in the positive half space
							{	
								color += bounceIntensity * max(dot(-transmittanceDirection, normal),0.0)* directLightingVector/(numberOfSamplesF* pow(distanceSenderReceiver,2.0));
							}
						}//End if verification second depth for depth peeling
						else
						{
							if(enableMultipleViews == 1)
							{
								//The sample is visible but hidden between 2 objects
								//Multiple views : same verifications but in the other camera
								//No depth peeling for this camera
								vec4 projectionInCam90SpaceSample = (cameraProjectionM90 * cameraViewMatrix90 * vec4(samplePosition, 1.0));
								vec2 screenSpace90PositionSampleNormalized = projectionInCam90SpaceSample.xy/(projectionInCam90SpaceSample.w);
								vec2 sampleUV90 = screenSpace90PositionSampleNormalized*0.5 + 0.5; //UV coordinates
						
								vec4 directLightingVector90 = texture2D(directLightBuffer90,sampleUV90);
						
								vec4 cam90SpaceSample = cameraViewMatrix90*vec4(samplePosition,1.0);
								float distanceCamera90Sample = length((cam90SpaceSample).xyz/cam90SpaceSample.w);//Normalize with the 4th coordinate
								vec4 sampleProjectionOnSurfaceCam90 =  texture2D(positionsBuffer90, sampleUV90);
								float distanceCamera90SampleProjection = texture2D(normalsAndDepthBuffer90,sampleUV90).a;
								vec3 normalSpaceSampleProjectionOnSurface90 = normalSpaceMatrix* sampleProjectionOnSurfaceCam90.xyz;

								if( normalSpaceSampleProjectionOnSurface90.z >= 0.0) //Consider samples projections that are in the positive half space
								{
									if(distanceCamera90Sample > distanceCamera90SampleProjection)//The sample is an occluder in the 2nd camera
									{	
										color += bounceIntensity * max(dot(-transmittanceDirection, normal),0.0)* directLightingVector90/(numberOfSamplesF* pow(distanceSenderReceiver,2.0));	
									}
								}
							}
						}
					}
				}//End if (sampleProjectionOnSurface.a == 0.0) not in the backgound
			ii += 1.0; 
		}//End for on samples
		gl_FragColor = vec4(clamp(color.xyz,0.0,1.0), 1.0);
	}
	else
	{
		gl_FragColor = vec4(0.2, 0.3, 0.4, 1.0);
	}
							
}
