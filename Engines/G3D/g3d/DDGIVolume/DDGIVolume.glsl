#ifndef DDGIVolume_glsl
#define DDGIVolume_glsl

// If you want to call the sampleIrradiance function, then you
// must #define NUM_DDGIVOLUMES to be the length of the array used
// with it.

#include <g3dmath.glsl>
#include <Texture/Texture.glsl>
#include <octahedral.glsl>

// In case of applications wishing to use the old shader path.
#ifndef NUM_DDGIVOLUMES
#define NUM_DDGIVOLUMES 0
#endif

#if NUM_DDGIVOLUMES != 0
#expect FIRST_FRAME
#expect OFFSET_BITS_PER_CHANNEL
#else
#ifndef OFFSET_BITS_PER_CHANNEL
#define OFFSET_BITS_PER_CHANNEL
#endif
#endif

// zyx bit pattern indicating which probe we're currently using within the cell on [0, 7]
#define CycleIndex int

// Linear index to a probe. On [0, L.probeCounts.x * L.probeCounts.y * L.probeCounts.z - 1]
#define ProbeIndex int

// Probe xyz logical indices
#define GridCoord ivec3

const float highestSignedValue = float(1 << (OFFSET_BITS_PER_CHANNEL - 1));

struct DDGIVolume {
	Vector3int32            probeCounts;
	Vector3int32            logProbeCounts;

	Point3                  probeGridOrigin;
	Vector3                 probeSpacing;
	// 1 / probeSpacing
	Vector3                 invProbeSpacing;

	Vector3int32            phaseOffsets;


	sampler2D               irradianceTexture;
	vec2                    invIrradianceTextureSize;

	sampler2D               visibilityTexture;
	vec2                    invVisibilityTextureSize;

	// probeOffsetLimit on [0,0.5] where max probe 
	// offset = probeOffsetLimit * probeSpacing
	// Usually 0.4, controllable from GUI.
	float                   probeOffsetLimit;

	isampler2D              probeOffsetsTexture;
	layout(rgba8i) iimage2D probeOffsetsImage;

	int                     irradianceProbeSideLength;
	int                     visibilityProbeSideLength;

	float                   selfShadowBias;

	float                   irradianceGamma;
	float                   invIrradianceGamma;

	bool					cameraLocked;
};

#ifndef G3D_screenSpaceRayTrace_glsl
float distanceSquared(Point2 v0, Point2 v1) {
	Point2 d = v1 - v0;
	return dot(d, d);
}
#endif

/**
 \param probeCoords Integer (stored in float) coordinates of the probe on the probe grid
 */
ProbeIndex gridCoordToProbeIndex(in DDGIVolume ddgiVolume, in Point3 probeCoords) {
	return int(probeCoords.x + probeCoords.y * ddgiVolume.probeCounts.x + probeCoords.z * ddgiVolume.probeCounts.x * ddgiVolume.probeCounts.y);
}


GridCoord baseGridCoord(in DDGIVolume ddgiVolume, Point3 X) {
	// Implicit floor in the convert to int
	GridCoord unOffsetGridCoord = clamp(GridCoord((X - ddgiVolume.probeGridOrigin) * ddgiVolume.invProbeSpacing),
		GridCoord(0, 0, 0),
		ddgiVolume.probeCounts - 1);
	return ivec3(mod(unOffsetGridCoord - ddgiVolume.phaseOffsets, ddgiVolume.probeCounts));
}


/** Returns the index of the probe at the floor along each dimension. */
ProbeIndex baseProbeIndex(in DDGIVolume ddgiVolume, Point3 X) {
	return gridCoordToProbeIndex(ddgiVolume, baseGridCoord(ddgiVolume, X));
}


/** Matches code in LightFieldModel::debugDraw() */
Color3 gridCoordToColor(GridCoord gridCoord) {
	gridCoord.x &= 1;
	gridCoord.y &= 1;
	gridCoord.z &= 1;

	if (gridCoord.x + gridCoord.y + gridCoord.z == 0) {
		return Color3(0.1);
	}
	else {
		return Color3(gridCoord) * 0.9;
	}
}


GridCoord probeIndexToGridCoord(in DDGIVolume L, ProbeIndex index) {
	/* Works for any # of probes */
	/*
	iPos.x = index % L.probeCounts.x;
	iPos.y = (index % (L.probeCounts.x * L.probeCounts.y)) / L.probeCounts.x;
	iPos.z = index / (L.probeCounts.x * L.probeCounts.y);
	*/

	// Assumes probeCounts are powers of two.
	// Saves ~10ms compared to the divisions above
	// Precomputing the MSB actually slows this code down substantially
	ivec3 iPos;
	iPos.x = index & (L.probeCounts.x - 1);
	iPos.y = (index & ((L.probeCounts.x * L.probeCounts.y) - 1)) >> findMSB(L.probeCounts.x);
	iPos.z = index >> findMSB(L.probeCounts.x * L.probeCounts.y);

	return iPos;
}


Color3 probeIndexToColor(in DDGIVolume L, ProbeIndex index) {
	return gridCoordToColor(probeIndexToGridCoord(L, index));
}


/** probeCoords Coordinates of the probe, computed as part of the process. */
ProbeIndex nearestProbeIndex(in DDGIVolume L, Point3 X, out Point3 probeCoords) {
	probeCoords = clamp(round((X - L.probeGridOrigin) / L.probeSpacing),
		Point3(0, 0, 0),
		Point3(L.probeCounts - 1));

	return gridCoordToProbeIndex(L, probeCoords);
}



Vector4 readProbeOffset(in DDGIVolume L, ivec2 texelCoord) {
	vec4 v = vec4(texelFetch(L.probeOffsetsTexture, texelCoord, 0));
	return vec4(v.xyz * L.probeOffsetLimit * L.probeSpacing / highestSignedValue, v.w);
}

void writeProbeOffset(in DDGIVolume L, in ivec2 texelCoord, in vec4 offsetAndFlags) {
	imageStore(L.probeOffsetsImage, texelCoord, ivec4(ivec3(ceil(highestSignedValue * offsetAndFlags.xyz * L.invProbeSpacing / L.probeOffsetLimit)), offsetAndFlags.w));
}

// Apply the per-axis phase offset to derive the correct location for each probe.
Point3 gridCoordToPositionNoOffset(in DDGIVolume L, GridCoord c) {
	// Phase offset may be negative, which is fine for modular arithmetic.
	GridCoord phaseOffsetGridCoord = ivec3(mod(c + L.phaseOffsets, L.probeCounts));
	return L.probeSpacing * Vector3(phaseOffsetGridCoord) + L.probeGridOrigin;
}

Point3 gridCoordToPosition(in DDGIVolume L, GridCoord c) {

	//Add per-probe offset
	int idx = gridCoordToProbeIndex(L, c);
	int probeXY = L.probeCounts.x * L.probeCounts.y;
	ivec2 C = ivec2(idx % probeXY, idx / probeXY);

	vec3 offset =
#if FIRST_FRAME
		ivec3(0)
#else
		readProbeOffset(L, C).xyz; // readProbeOffset multiplies by probe step.
#endif
	;
	return gridCoordToPositionNoOffset(L, c) + offset;
}

Point3 probeLocation(in DDGIVolume L, ProbeIndex index) {
	return gridCoordToPosition(L, probeIndexToGridCoord(L, index));
}


/** GLSL's dot on ivec3 returns a float. This is an all-integer version */
int idot(ivec3 a, ivec3 b) {
	return a.x * b.x + a.y * b.y + a.z * b.z;
}

/**
   \param baseProbeIndex Index into L.radianceProbeGrid's TEXTURE_2D_ARRAY. This is the probe
   at the floor of the current ray sampling position.

   \param relativeIndex on [0, 7]. This is used as a set of three 1-bit offsets

   Returns a probe index into L.radianceProbeGrid. It may be the *same* index as
   baseProbeIndex.

   This will wrap in crazy ways when the camera is outside of the bounding box
   of the probes...but that's ok. If that case arises, then the trace is likely to
   be poor quality anyway. Regardless, this function will still return the index
   of some valid probe, and that probe can either be used or fail because it does not
   have visibility to the location desired.

   \see nextCycleIndex, baseProbeIndex
 */
ProbeIndex relativeProbeIndex(in DDGIVolume ddgiVolume, ProbeIndex baseProbeIndex, CycleIndex relativeIndex) {
	ProbeIndex numProbes = ddgiVolume.probeCounts.x * ddgiVolume.probeCounts.y * ddgiVolume.probeCounts.z;

	// Use the bits of 0 <= relativeIndex < 8 to enumerate the +1 or +0 offsets along each axis.
	//
	// relativeIndex bit 0 = x offset
	// relativeIndex bit 1 = y offset
	// relativeIndex bit 2 = z offset
	ivec3 offset = ivec3(relativeIndex & 1, (relativeIndex >> 1) & 1, (relativeIndex >> 2) & 1);
	ivec3 stride = ivec3(1, ddgiVolume.probeCounts.x, ddgiVolume.probeCounts.x * ddgiVolume.probeCounts.y);

	// If the probe is outside of the grid, return *some* probe so that the code 
	// doesn't crash. With cascades implemented (even one), this case is never needed because
	// the cascade will fade out before the sample point leaves the grid.
	//
	// (numProbes is guaranteed to be a power of 2 in the current implementation, 
	// which allows us to use a bitand instead of a modulo operation.)
	return (baseProbeIndex + idot(offset, stride)) & (numProbes - 1);
}


Point2 probeTextureCoordFromDirection
(Vector3             dir,
	GridCoord           probeGridCoord,
	const in bool       useIrradiance,
	DDGIVolume          ddgiVolume) {

	vec2 invTextureSize = useIrradiance ? ddgiVolume.invIrradianceTextureSize : ddgiVolume.invVisibilityTextureSize;
	int probeSideLength = useIrradiance ? ddgiVolume.irradianceProbeSideLength : ddgiVolume.visibilityProbeSideLength;

	vec2 signedOct = octEncode(dir);
	vec2 unsignedOct = (signedOct + 1.0f) * 0.5f;
	Point2 octCoordNormalizedToTextureDimensions = (unsignedOct * (float)probeSideLength) * invTextureSize;

	int probeWithBorderSide = probeSideLength + 2;

	vec2 probeTopLeftPosition = vec2((probeGridCoord.x + probeGridCoord.y * ddgiVolume.probeCounts.x) * probeWithBorderSide,
		probeGridCoord.z * probeWithBorderSide) + vec2(1, 1);

	vec2 normalizedProbeTopLeftPosition = vec2(probeTopLeftPosition) * invTextureSize;

	return vec2(normalizedProbeTopLeftPosition + octCoordNormalizedToTextureDimensions);
}


/**
  Result.rgb = Irradiance3
  Result.a   = weight based on wsPosition vs. probe bounds
*/
Color4 sampleOneDDGIVolume
(DDGIVolume             ddgiVolume,
	Point3                 wsPosition,
	Vector3                offsetPos,
	Vector3                sampleDirection,
	Point3				   cameraPos,

	// Can we skip this volume if it has zero weight?
	bool                   skippable) {

	// Compute the weight for this volume relative to other volumes
	float volumeWeight = 1.0;
	if (skippable) {
		// Compute the non-integer baseGridCoord. Use the unshifted position so that weights are consistent between
		// volumes. Use the geometric mean across all axes.
		Vector3 shiftedOrigin = ddgiVolume.probeGridOrigin;

		if (ddgiVolume.cameraLocked) {
			shiftedOrigin = cameraPos - (ddgiVolume.probeSpacing * (ddgiVolume.probeCounts - vec3(1, 1, 1)) * 0.5);
		}
		Vector3 realGridCoord = (wsPosition - shiftedOrigin) * ddgiVolume.invProbeSpacing;
		for (int axis = 0; axis < 3; ++axis) {
			float a = realGridCoord[axis];
			if (a < 1.0) {
				volumeWeight *= clamp(a, 0.0, 1.0);
			}
			else if (a > float(ddgiVolume.probeCounts[axis]) - 2.0 - (ddgiVolume.cameraLocked ? 1.0 : 0.0)) {
				volumeWeight *= clamp(float(ddgiVolume.probeCounts[axis]) - 1.0 - (ddgiVolume.cameraLocked ? 1.0 : 0.0) - a, 0.0, 1.0);
			}
		}
		// Blending is improved without logarithmic fallof
		//volumeWeight = pow(volumeWeight, 1.0 / 3.0);
	}

	if (volumeWeight == 0.0) {
		// Don't bother sampling, this volume won't be used
		return Color4(0);
	}

	offsetPos *= ddgiVolume.selfShadowBias;

	// We're sampling at (wsPosition + offsetPos). This is inside of some grid cell, which
	// is bounded by 8 probes. Find the coordinate of the corner for the LOWEST probe (i.e.,
	// floor along x,y,z) and call that baseGridCoord. The other seven probes are offset by
	// +0 or +1 in grid space along each axis from this. We'll process them all in the main
	// loop below.
	//
	// This is all analogous to bilinear interpolation for texture maps, but we're doing it
	// in 3D, with visibility, and nonlinearly.
	GridCoord anchorGridCoord = baseGridCoord(ddgiVolume, wsPosition + offsetPos);

	// Don't use the offset to compute trilinear.
	Point3 baseProbePos = //gridCoordToPosition(ddgiVolume, baseGridCoord);
		gridCoordToPositionNoOffset(ddgiVolume, anchorGridCoord);

	// Weighted irradiance accumulated in RGB across probes. The Alpha channel contains the
	// sum of the weights, which is used for normalization at the end.
	float4 irradiance = float4(0);

	// `alpha` is how far from the floor(currentVertex) position. On [0, 1] for each axis.
	// Used for trilinear weighting. 
	Vector3 alpha = clamp((wsPosition + offsetPos - baseProbePos) * ddgiVolume.invProbeSpacing, Vector3(0), Vector3(1));

	// This term is experimental and not in use in the current implementation
	float chebWeightSum = 0;

	// Iterate over adjacent probe cage
	for (int i = 0; i < 8; ++i) {
		// Compute the offset grid coord and clamp to the probe grid boundary
		// Offset = 0 or 1 along each axis. Pull the offsets from the bits of the 
		// loop index: x = bit 0, y = bit 1, z = bit 2
		GridCoord  offset = ivec3(i, i >> 1, i >> 2)& ivec3(1);

		// Compute the trilinear weights based on the grid cell vertex to smoothly
		// transition between probes. Offset is binary, so we're
		// using 1-a when offset = 0 and a when offset = 1.
		Vector3 trilinear3 = max(vec3(0.001), lerp(1.0 - alpha, alpha, offset));
		float trilinear = trilinear3.x * trilinear3.y * trilinear3.z;

		// Because of the phase offset applied for camera locked volumes,
		// we need to add the computed offset modulo the probecounts.
		GridCoord  probeGridCoord = ivec3(mod((anchorGridCoord + offset), ddgiVolume.probeCounts));

		// Make cosine falloff in tangent plane with respect to the angle from the surface to the probe so that we never
		// test a probe that is *behind* the surface.
		// It doesn't have to be cosine, but that is efficient to compute and we must clip to the tangent plane.
		Point3 probePos = gridCoordToPosition(ddgiVolume, probeGridCoord);

		float weight = 1.0;
		// Clamp all of the multiplies. We can't let the weight go to zero because then it would be 
		// possible for *all* weights to be equally low and get normalized
		// up to 1/n. We want to distinguish between weights that are 
		// low because of different factors.

			// Computed without the biasing applied to the "dir" variable. 
			// This test can cause reflection-map looking errors in the image
			// (stuff looks shiny) if the transition is poor.
		Vector3 trueDirectionToProbe = normalize(probePos - wsPosition);

		// The naive soft backface weight would ignore a probe when
		// it is behind the surface. That's good for walls. But for small details inside of a
		// room, the normals on the details might rule out all of the probes that have mutual
		// visibility to the point. So, we instead use a "wrap shading" test below inspired by
		// NPR work.

		// The small offset at the end reduces the "going to zero" impact
		// where this is really close to exactly opposite
#if SHOW_CHEBYSHEV_WEIGHTS == 0
		weight *= square((dot(trueDirectionToProbe, sampleDirection) + 1.0) * 0.5) + 0.2;
#endif

		// Bias the position at which visibility is computed; this avoids performing a shadow 
		// test *at* a surface, which is a dangerous location because that is exactly the line
		// between shadowed and unshadowed. If the normal bias is too small, there will be
		// light and dark leaks. If it is too large, then samples can pass through thin occluders to
		// the other side (this can only happen if there are MULTIPLE occluders near each other, a wall surface
		// won't pass through itself.)
		Vector3 probeToBiasedPointDirection = (wsPosition + offsetPos) - probePos;
		float distanceToBiasedPoint = length(probeToBiasedPointDirection);
		probeToBiasedPointDirection *= 1.0 / distanceToBiasedPoint;

		Point2 visTexCoord = probeTextureCoordFromDirection(probeToBiasedPointDirection, probeGridCoord, false, ddgiVolume);

		float2 temp = texture(ddgiVolume.visibilityTexture, visTexCoord, 0).xy;
		float meanDistanceToOccluder = temp.x;
		float variance = abs(square(temp.x) - temp.y);

		float chebyshevWeight = 1.0;
		if (distanceToBiasedPoint > meanDistanceToOccluder) {
			// In "shadow"

			// http://www.punkuser.net/vsm/vsm_paper.pdf; equation 5
			// Need the max in the denominator because biasing can cause a negative displacement
			chebyshevWeight = variance / (variance + square(distanceToBiasedPoint - meanDistanceToOccluder));

			// Increase contrast in the weight
			chebyshevWeight = max(pow3(chebyshevWeight), 0.0);
		}

		// Avoid visibility weights ever going all of the way to zero because when *no* probe has
		// visibility we need some fallback value.
		chebyshevWeight = max(0.05, chebyshevWeight);

		weight *= chebyshevWeight;

		// Avoid zero weight
		weight = max(0.000001, weight);

		vec2 texCoord = probeTextureCoordFromDirection(sampleDirection, probeGridCoord, true, ddgiVolume);

		// A tiny bit of light is really visible due to log perception, so
		// crush tiny weights but keep the curve continuous.
		const float crushThreshold = 0.2;
		if (weight < crushThreshold) {
			weight *= square(weight) * (1.0 / square(crushThreshold));
		}

		weight *= trilinear;

		Irradiance3 probeIrradiance = texture(ddgiVolume.irradianceTexture, texCoord).rgb;

		// Decode the tone curve, but leave a gamma = 2 curve (=sqrt here) to approximate sRGB blending for the trilinear
		probeIrradiance = pow(probeIrradiance, vec3(ddgiVolume.irradianceGamma * 0.5));

		irradiance += float4(weight * probeIrradiance, weight);
	}

	// Normalize by the sum of the weights
	irradiance.xyz *= 1.0 / irradiance.a;

	// Go back to linear irradiance
	irradiance.xyz = square(irradiance.xyz);

	// Was factored out of probes
	irradiance.xyz *= 2.0 * pi;

	return Color4(irradiance.xyz, volumeWeight);
}

#if NUM_DDGIVOLUMES > 0
Irradiance3 sampleIrradiance
(DDGIVolume             ddgiVolumeArray[NUM_DDGIVOLUMES],
	Point3                 wsPosition,
	Vector3                offsetPos,
	Vector3                sampleDirection,
	Point3			       cameraPos) {

	Color4 sum = Color4(0);

	// Sample until we have "100%" weight covered, and then *stop* looking at lower-resolution
	// volumes because they aren't needed.
	for (int v = 0; (v < NUM_DDGIVOLUMES) && (sum.a < 1.0); ++v) {
		// Can skip if not the last volume or some other volume has already contributed
		bool skippable = (v < NUM_DDGIVOLUMES - 1) || (sum.a > 0.9f);
		Color4 irradiance = sampleOneDDGIVolume(ddgiVolumeArray[v], wsPosition, offsetPos, sampleDirection, cameraPos, skippable);

		// Visualize weights per volume:
		//irradiance.rgb = vec3(0); irradiance[v] = irradiance.a;// 1.0;

		// Max contribution of other probes should be limited by how much more weight is required
		irradiance.a *= saturate(1.0 - sum.a);

		// Premultiply
		irradiance.rgb *= irradiance.a;
		sum += irradiance;
	}

	// Normalize
	return sum.rgb / max(0.001, sum.a);
}
#endif

#endif