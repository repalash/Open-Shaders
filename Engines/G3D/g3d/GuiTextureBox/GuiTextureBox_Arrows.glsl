#ifndef GuiTextureBox_Arrows_glsl
#define GuiTextureBox_Arrows_glsl

// Enum values
const int   ARROW_V_STYLE = 1;
const int   ARROW_LINE_STYLE = 2;

// Current arrow head style
const int   ARROW_STYLE = ARROW_LINE_STYLE;
const vec3	ARROW_COLOR = vec3(0);

// Higher numbers are sharper. In radians. 
const float ARROW_HEAD_ANGLE = 0.7854;

/* Returns the center pixel of the tile containing pixel pos */
vec2 arrowTileCenterCoord(vec2 pos, float motionVectorSpacing) {
	return (floor(pos / motionVectorSpacing) + 0.5) * motionVectorSpacing;
}

/*  v = field sampled at tileCenterCoord(p), scaled by the length
	desired in pixels for arrows
	Returns the alpha channel of the arrow. */
float arrowAlpha(vec2 p, vec2 v, float arrowTileSize) {
	// Used for ARROW_LINE_STYLE
	float headLength = arrowTileSize * (1.0 / 6.0);
	float shaftThickness = arrowTileSize * (1.0 / 20.0);

	float mag_v = length(v), mag_p = length(p);

	if (mag_v > 0.0) {
		// Non-zero velocity case
		vec2 dir_p = p * (1.0 / mag_p), dir_v = v * (1.0 / mag_v);

		// We can't draw arrows larger than the tile radius, so clamp magnitude.
		// Enforce a minimum length to help see direction
		mag_v = clamp(mag_v, 5.0, arrowTileSize * 0.5);

		// Arrow tip location
		v = dir_v * mag_v;

		// Define a 2D implicit surface so that the arrow is antialiased.
		// In each line, the left expression defines a shape and the right controls
		// how quickly it fades in or out.

		float dist;
		if (ARROW_STYLE == ARROW_LINE_STYLE) {
			// Line arrow style
			dist = max(
					// Shaft
					shaftThickness * (1.0 / 4.0) -
					max(abs(dot(p, vec2(dir_v.y, -dir_v.x))), // Width
						abs(dot(p, dir_v)) - mag_v + 0.5 * headLength), // Length

					// Arrow head
					min(0.0, dot(v - p, dir_v) - cos(ARROW_HEAD_ANGLE / 2.0) * length(v - p)) * 2.0 + // Front sides
					min(0.0, dot(p, dir_v) + headLength - mag_v)); // Back
		} else {
			// V arrow style
			dist = min(0.0, mag_v - mag_p) * 2.0 + // length
				min(0.0, dot(normalize(v - p), dir_v) - cos(ARROW_HEAD_ANGLE / 2.0)) * 2.0 * length(v - p) + // head sides
				min(0.0, dot(p, dir_v) + 1.0) + // head back
				min(0.0, cos(ARROW_HEAD_ANGLE / 2.0) - dot(normalize(v * 0.33 - p), dir_v)) * mag_v * 0.8; // cutout
		}

		return clamp(1.0 + dist, 0.0, 1.0);
	} else {
		// Center of the pixel is always on the arrow
		return max(0.0, 1.2 - mag_p);
	}
}

#endif
