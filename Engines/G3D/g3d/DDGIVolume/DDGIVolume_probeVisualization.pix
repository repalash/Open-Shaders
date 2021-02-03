#version 460

#include "DDGIVolume.glsl"

const Color3 OFF_COLOR     = Color3(0, 0, 0);        // Black
const Color3 ASLEEP_COLOR   = Color3(0.06f, 0.02f, 0);   // Brown: halfway between awake and dead
const Color3 JUST_WOKE_COLOR= Color3(1, 0, 0);        // Red for momentary wake
const Color3 AWAKE_COLOR    = Color3(1, 1, 0.1);      // Yellow
const Color3 JUST_VIGILANT_COLOR  = Color3(1,0,1);          // Magenta for momentary vigilant
const Color3 VIGILANT_COLOR = Color3(0, 1, 0);        // Green
const Color3 UNINITIALIZED_COLOR = Color3(0,1,1);     // Cyan

in Vector3          sampleDirection;
in flat int3        probeGridCoord;
in float            edgeProximityScaleFactor;

uniform DDGIVolume  ddgiVolume;
uniform float       maxDistance;
uniform int			probeSleeping;
uniform Color3		volumeColor;

out Color3          color;

void main() {
    Point2      texCoord;

#   if VISUALIZE_DEPTH
    {
        texCoord = probeTextureCoordFromDirection(normalize(sampleDirection), probeGridCoord, false, ddgiVolume);

        color = Irradiance3(texture(ddgiVolume.visibilityTexture, texCoord).r) / (maxDistance);
    }
#   else
    {
        texCoord = probeTextureCoordFromDirection(normalize(sampleDirection), probeGridCoord, true, ddgiVolume);
        color = max(texture(ddgiVolume.irradianceTexture, texCoord).rgb, vec3(0));

        // Decode 
        color = pow(color, vec3(ddgiVolume.irradianceGamma));

        // Needed to match surface intensity
        color *= 1.0 / (0.5 * pi);
    }
#   endif

#if VISUALIZE_VOLUME_COLOR
	color = volumeColor;
#else

    // Hack for rendering different volume visualization 
    // for camera tracking volumes.
    //if (volumeColor.y > 0.0f) {
    //    if (int(gl_FragCoord.x + gl_FragCoord.y) % 2 == 0) {
    //        discard;
    //    }
    //    return;
    //}

    // Color the edge of the probe based on the state
	if (probeSleeping == 1 && edgeProximityScaleFactor < 0.55f) {
	    // Apply per-probe position offset
	    int idx = gridCoordToProbeIndex(ddgiVolume, probeGridCoord);
	    int probeXY = ddgiVolume.probeCounts.x * ddgiVolume.probeCounts.y;
	    ivec2 C = ivec2(idx % probeXY, idx / probeXY);
	    int state = (int)readProbeOffset(ddgiVolume, C).w;
		
        const int STATE_OFF           = 0;
        const int STATE_ASLEEP        = 1;
        const int STATE_JUST_WOKE     = 2;
        const int STATE_AWAKE         = 3;
        const int STATE_JUST_VIGILANT = 4;
        const int STATE_VIGILANT      = 5;
        const int STATE_UNINITIALIZED = 6;

        if      (state == STATE_OFF)            {  color = OFF_COLOR;          }
        else if (state == STATE_ASLEEP)         {  color = ASLEEP_COLOR;       }
        else if (state == STATE_JUST_WOKE)      {  color = JUST_WOKE_COLOR;    }
        else if (state == STATE_AWAKE)          {  color = AWAKE_COLOR;        }
	    else if (state == STATE_JUST_VIGILANT)  {  color = JUST_VIGILANT_COLOR;}
	    else if (state == STATE_VIGILANT)       {  color = VIGILANT_COLOR;     }
        else if (state == STATE_UNINITIALIZED)  {  color = UNINITIALIZED_COLOR;}
	}
#endif
}