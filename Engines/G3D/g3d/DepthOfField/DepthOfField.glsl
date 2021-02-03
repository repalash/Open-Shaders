/**
  \file data-files/shader/DepthOfField/DepthOfField.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/

#define NONE 0
#define PHYSICAL 1
#define ARTIST 2

/** All the z values are negative numbers (in front of the camera).
Return value is a signed number where negative values mean that
the point spread function is upside down and far from the camera 
and positive values are close.
\see DepthOfField::computeCoC

If `model == PHYSICAL` the scale argument is computed as follows:
~~~~~~~~~~~~~~~~~~
const float scale = (screenSize * 0.5f / tan(camera->fieldOfViewAngle() * 0.5f)) * camera->depthOfFieldSettings().lensRadius() / 
                (camera->depthOfFieldSettings().focusPlaneZ());
~~~~~~~~~~~~~~~~~~
				*/
float circleOfConfusionRadiusPixels
	(float z,
	 float focusPlaneZ,
	 float screenFocusZ,
	 float nearBlurryPlaneZ,
	 float nearSharpPlaneZ,
	 float farBlurryPlaneZ,
	 float farSharpPlaneZ,
	 float nearScale,
	 float farScale,
     float scale,
	 const bool chromaBlur,
	 const int model) {

	float radius = 0.0;
	if (MODEL == PHYSICAL) {
		if (chromaBlur) {
			float retinalRadiusForScreen = (screenFocusZ - focusPlaneZ) * scale / screenFocusZ;
			float retinalRadiusForObject = (z - focusPlaneZ) * scale / z;

			if (abs(retinalRadiusForObject) > abs(retinalRadiusForScreen)) {
				radius = sign(retinalRadiusForObject) * sqrt(square(retinalRadiusForObject) - square(retinalRadiusForScreen));
			} else {
				radius = 0.0;
			}
		} else {
			radius = (z - focusPlaneZ) * scale / z;
		}

		if (radius < 0) {
			// Compensate for differing blur algorithm in the far field. 
			// This gives results that match an analytic PSF very closely.
			// No impact on near field.
			radius *= 0.6;
		}

	} else if (MODEL == ARTIST) {
		if (z > nearSharpPlaneZ) {
			// Make the radius grow nonlinearly in the foreground to better approximate the physical phenomenon
			radius = square(min(z, nearBlurryPlaneZ) - nearSharpPlaneZ) * nearScale;
		} else if (z > farSharpPlaneZ) {
			// In the focus field
			radius = 0.0;
		} else {
			// Produce a negative value
			radius = (max(z, farBlurryPlaneZ) - farSharpPlaneZ) * farScale;
		}

		// Work around for the near field blur not being well calibrated due to
		// using a gaussian instead of a disk
		if (radius > 0.0) { radius *= 1.5; }
	} else {
		radius = 0.0;
	}

	return radius;
}
