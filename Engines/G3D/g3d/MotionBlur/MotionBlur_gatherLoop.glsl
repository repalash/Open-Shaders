/**
  \file data-files/shader/MotionBlur/MotionBlur_gatherLoop.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#error Use MotionBlur_gather.pix directly
// The inner loop of MotionBlur_gather.pix
// Sample along the largest PSF vector in the neighborhood
for (int i = 0; i < numSamplesOdd; ++i) {

    // The original algorithm ignores the center sample, but we include it because doing so
    // produces better results for thin objects at the expense of adding a slight amount of grain.
    // That is because the jitter will bounce this slightly off the actual center
#   if SMOOTHER
        if (i == numSamplesOdd / 2) { continue; }
#   endif
        
    // Signed step distance from X to Y.
    // Because cone(r_Y) = 0, we need this to never reach +/- r_neighborhood, even with jitter.
    // If this value is even slightly off then gaps and bands will appear in the blur.
    // This pattern is slightly different than the original paper.
    float t = clamp(2.4 * (float(i) + 1.0 + jitter) / (numSamplesOdd + 1.0) - 1.2, -1, 1);

    float dist = t * r_neighborhood;

    float2 sampling_direction = (((i & 1) == 1) ? w_center : w_neighborhood);

    float2 offset =
        // Alternate between the neighborhood direction and this pixel's direction.
        // This significantly helps avoid tile boundary problems when other are
        // two large velocities in a tile. Favor the neighborhood velocity on the farthest 
        // out taps (which also means that we get slightly more neighborhood taps, as we'd like)
        dist * sampling_direction;
        
    // Point being considered; offset and round to the nearest pixel center.
    // Then, clamp to the screen bounds
    int2 other = clamp(int2(offset + gl_FragCoord.xy), trimBandThickness, SCREEN_MAX);

    float depth_sample = texelFetch(depthBuffer, other, 0).x;

    // is other in the foreground or background of me?
    float inFront = softDepthCompare(depth_center, depth_sample);
    float inBack  = softDepthCompare(depth_sample, depth_center);

    // Relative contribution of sample to the center
    float coverage_sample = 0.0;

    // Blurry me, estimate background
    coverage_sample += inBack * fastCone(dist, invRadius_center);

    COMPUTE_RADIUS_SAMPLE();

    float3 color_sample    = texelFetch(colorBuffer, clamp(other - trimBandThickness, ivec2(0), NO_TRIM_BAND_SCREEN_MAX), 0).rgb;

    // Blurry other over any me
    coverage_sample += inFront * cone(dist, radius_sample);

    // Mutually blurry me and other
    coverage_sample += 
		// Optimized implementation
		cylinder(dist, min(radius_center, radius_sample)) * 2.0;
		
//        coverage_sample = saturate(coverage_sample * abs(dot(normalize(velocity_sample), sampling_direction)));
//       coverage_sample = saturate(dot(normalize(velocity_sample), sampling_direction));
		// Code from paper:
		// cylinder(dist, radius_center) * cylinder(dist, radius_sample) * 2.0;

    // Accumulate (with premultiplied coverage)
    resultColor   += color_sample * coverage_sample;
    totalCoverage += coverage_sample;
}