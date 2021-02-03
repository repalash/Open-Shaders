/**SSAOOnly.frag
* Last modified : 26/06/13
* Compute the visibility factor with the SSAO algorithm.
*/
#ifdef GL_ES
precision highp float;
#endif
#define NUMBER_OF_SAMPLES_MAX 32

// input buffers
uniform sampler2D positionsBuffer;
uniform sampler2D normalsAndDepthBuffer;
uniform sampler2D secondDepthBuffer;
uniform sampler2D randomTexture;

// camera properties
uniform mat4 cameraProjectionM;
uniform mat4 cameraViewMatrix;

//3D point properties
varying vec2 vUv;

//Number of samples we use for the SSAO algorithm
uniform vec3 randomDirections[NUMBER_OF_SAMPLES_MAX];
uniform int numberOfSamples;
uniform float numberOfSamplesF;
uniform float rmax;
uniform float bias;

void main() 
{
	vec4 currentPos = texture2D(positionsBuffer,vUv);
	float visibilityFactor = 0.0;
	
	if (currentPos.a == 0.0) // the current point is not in the background
	{
		vec3 position = currentPos.xyz;
		vec3 normal = normalize(texture2D(normalsAndDepthBuffer, vUv).xyz);
	
		//John Chapman SSAO implementation : http://john-chapman-graphics.blogspot.com/2013/01/ssao-tutorial.html
		//Precompute only numberOfSamples directions in the half positive hemisphere (randomDirections vector)
		//Add a random rotation (with normal axis)  when you put the direction in the normal space
		//Result : less noise due to random numbers
		vec3 vector = normalize(2.0*texture2D(randomTexture, vUv).xyz -1.0);
		vec3 tangent = normalize(vector - dot(vector,normal)*normal); //Dans le plan orthogonal à la normale (avec une rotation aléatoire dans ce plan)
		vec3 bitangent = normalize(cross(normal, tangent));
		mat3 normalSpaceMatrix = mat3(tangent, bitangent, normal);
	
		vec3 sampleDirection;
		vec3 samplePosition;
		vec4 projectionInCamSpaceSample;
	
		vec4 camSpaceSample; //sample is back projected in the cameraspace
		vec2 screenSpacePositionSampleNormalized; //(x,y) coordinates in screen space, normalize by the w coordinate
		vec2 sampleUV; //Screen space UV coordinates for the sample
		float distanceCameraSample; //Distance from the camera to the sample

		//The samples are in the hemisphere oriented by the normal vector	
		float ii = 0.0;
		for(int i = 0 ; i< NUMBER_OF_SAMPLES_MAX ; i++)
		{
			if(i>= numberOfSamples)
				break;
			// random numbers
			sampleDirection = randomDirections[i];
			sampleDirection = normalize(normalSpaceMatrix * sampleDirection); //Put the sampleDirection in the normal Space (positive half space)
		
			float r4 = texture2D(randomTexture, vUv).w * rmax;
		
			samplePosition = position + bias*normal+ r4*sampleDirection; //bias*normal to avoid auto occlusion

			//Samples are back projected to the image
			camSpaceSample = cameraViewMatrix*vec4(samplePosition,1.0);
			projectionInCamSpaceSample = (cameraProjectionM * camSpaceSample);
			screenSpacePositionSampleNormalized = projectionInCamSpaceSample.xy/(projectionInCamSpaceSample.w);//Normalize with the 4th coordinate
			sampleUV = screenSpacePositionSampleNormalized*0.5 + 0.5;

			//Determines if the sample is visible or not
			distanceCameraSample = length((camSpaceSample).xyz/camSpaceSample.w);//Normalize with the 4th coordinate

			if(sampleUV.x >= 0.0 && sampleUV.x <= 1.0 && sampleUV.y >= 0.0 && sampleUV.y <= 1.0)
			{
				vec4 sampleProjectionOnSurface =  texture2D(positionsBuffer, sampleUV); //Projection of the sample on the surface displayed by the camera

				if (sampleProjectionOnSurface.a == 0.0) // not in the background
				{
					float distanceCameraSampleProjection = texture2D(normalsAndDepthBuffer,sampleUV).a; //value of the z buffer
					if(distanceCameraSample > distanceCameraSampleProjection+bias) //if the sample is inside the surface : it may be an occluder
					{
						//Depth peeling
						float secondDepth = texture2D(secondDepthBuffer, sampleUV).a;
						if(distanceCameraSample>secondDepth+bias)//The sample is behind an object : it is visible
						{
							visibilityFactor += 1.0/numberOfSamplesF;
						}	
					}
					else
					{
						//visibilityFactor is calculted with visible samples
						visibilityFactor += 1.0/numberOfSamplesF;
					}
				
				}
				else//If the sample is in the background it is always visible
				{
					visibilityFactor += 1.0/numberOfSamplesF;
				}
			}
			ii += 1.0;
		}//End for on samples
	}//End if (currentPos.a == 0.0) // the current point is not in the background
		
	gl_FragColor = vec4(visibilityFactor, visibilityFactor, visibilityFactor, 1.0);
	
}
