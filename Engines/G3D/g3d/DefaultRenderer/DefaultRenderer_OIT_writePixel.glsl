/**
  \file data-files/shader/DefaultRenderer/DefaultRenderer_OIT_writePixel.glsl

  This shader corresponds to listing 1 of: 

    McGuire and Mara, A Phenomenological Scattering Model for Order-Independent Transparency, 
    Proceedings of the ACM Symposium on Interactive 3D Graphics and Games (I3D), Feburary 28, 2016

  http://graphics.cs.williams.edu/papers/TransparencyI3D16/
  
  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/

/** (Ar, Ag, Ab, Aa) */
layout(location = 0) out vec4 _accum;

/** (Br, Bg, Bb, D^2) */
layout(location = 1) out vec4 _modulate;

/** (deltax, deltay) */
layout(location = 2) out vec2 _refraction;

struct _Texture2D {
    sampler2D sampler;
    vec2       size;
    vec2       invSize;
    vec4       readMultiplyFirst;
    vec4       readAddSecond;

    /** false if the underlying texture was nullptr when bound */
    bool       notNull;
};

uniform _Texture2D _depthTexture;

/** Result is in texture coordinates */
Vector2 computeRefractionOffset
   (float           backgroundZ,
    vec3            csN,
    vec3            csPosition,
    float           etaRatio) {
    if (etaRatio > 1.0) {
        // Exiting. As a hack, eliminate refraction on the back
        // surface to help compensate for the fixed-distance assumption
        return vec2(0);
    }

    /* Incoming ray direction from eye, pointing away from csPosition */
    vec3 csw_i = normalize(-csPosition);

    /* Refracted ray direction, pointing away from wsPos */
    vec3 csw_o = refract(-csw_i, csN, etaRatio);

    bool totalInternalRefraction = (dot(csw_o, csw_o) < 0.01);
    if (totalInternalRefraction) {
        /* No transmitted light */
        return vec2(0.0);
    } else {
        /* Take to the reference frame of the background (i.e., offset) */
        vec3 d = csw_o;

        /* Take to the reference frame of the background, where it is the plane z = 0 */
        vec3 P = csPosition;
        P.z -= backgroundZ;

        /* Find the xy intersection with the plane z = 0 */
        vec2 hit = (P.xy - d.xy * P.z / d.z);

        /* Hit is now scaled in meters from the center of the screen; adjust scale and offset based
          on the actual size of the background */
        vec2 backCoord = (hit / backSizeMeters) + vec2(0.5);

        if (! g3d_InvertY) {
            backCoord.y = 1.0 - backCoord.y;
        }

        vec2 startCoord = (csPosition.xy / backSizeMeters) + vec2(0.5);
    
        vec2 delta = backCoord - startCoord;
        return delta * 0.15;
    }
}

/* Pasted in from reconstructFromDepth.glsl because we're defining a macro and can't have includes */
float _reconstructCSZ(float d, vec3 clipInfo) {
    return clipInfo[0] / (clipInfo[1] * d + clipInfo[2]);
}

/** Not used in the final version */
float randomVal(vec3 p) {
    return frac(sin(p.x * 1e2 + p.y) * 1e5 + sin(p.y * 1e3 + p.z * 1e2) * 1e3);
}

/** Instead of writing directly to the framebuffer in a forward or deferred shader, the 
    G3D engine invokes this writePixel() function. This allows mixing different shading 
    models with different OIT models. */
void writePixel
   (vec3        premultipliedReflectionAndEmission,
    float       coverage, 
    vec3        transmissionCoefficient,
    float       collimation, 
    float       etaRatio, 
    vec3        csPosition, 
    vec3        csNormal) {
    /* Perform this operation before modifying the coverage to account for transmission */
    _modulate.rgb = coverage * (vec3(1.0) - transmissionCoefficient);

    /* Modulate the net coverage for composition by the transmission. This does not affect the color channels of the
    transparent surface because the caller's BSDF model should have already taken into account if transmission modulates
    reflection. See:

    McGuire and Enderton, Colored Stochastic Shadow Maps, ACM I3D, February 2011
    http://graphics.cs.williams.edu/papers/CSSM/

    for a full explanation and derivation.*/
    coverage *= 1.0 - (transmissionCoefficient.r + transmissionCoefficient.g + transmissionCoefficient.b) * (1.0 / 3.0);
    
    if (etaRatio != 1.0) {
        float backgroundZ = csPosition.z - 4;
        Vector2 refractionOffset = computeRefractionOffset(backgroundZ, csNormal, csPosition, etaRatio);
        // Encode into snorm. Maximum offset is 1 / 8 of the screen
        _refraction = refractionOffset * coverage * 8.0;

        if (etaRatio > 1.0) {
            // Exiting; probably the back surface. Dim reflections 
            // based on the assumption of traveling through the medium.
            premultipliedReflectionAndEmission *= transmissionCoefficient * transmissionCoefficient; 
        }
    } else {
        _refraction = vec2(0);
    }
   

    /* Alternative weighting functions: */
    /* float tmp = 2.0 * max(1.0 + csPosition.z / 200.0, 0.0); tmp *= tmp * 1e3; */

    /* Looks better on clouds */
    float tmp = 1.0 - gl_FragCoord.z * 0.99; tmp *= tmp * tmp * 1e4;
    tmp = clamp(tmp, 1e-3, 1.0);
    
    /*
      If you're running out of compositing range and overflowing to inf, multiply the upper bound (3e2) by a small
      constant. Note that R11G11B10F has no "inf" and maps all floating point specials to NaN, so you won't actually
      see inf in the frame buffer.
      */

    /* Weight function tuned for the general case */
    float w = clamp(coverage * tmp, 1e-3, 1.5e2);    
    _accum = vec4(premultipliedReflectionAndEmission, coverage) * w;
    
    if (collimation < 1.0) {
        float trueBackgroundCSZ = _reconstructCSZ(texelFetch(_depthTexture.sampler, ivec2(gl_FragCoord.xy), 0).r, g3d_ClipInfo);

        /* Diffusion scaling constant. Adjust based on the precision of the _modulate.a texture channel. */
        const float k_0 = 8.0;

        /** Focus rate. Increase to make objects come into focus behind a frosted glass surface more quickly,
            decrease to defocus them quickly. */
        const float k_1 = 0.1;

        /* Compute standard deviation */
        _modulate.a = k_0 * coverage * (1.0 - collimation) * (1.0 - k_1 / (k_1 + csPosition.z - trueBackgroundCSZ)) / max(abs(csPosition.z), 1e-5);
        /* Convert to variance */
        _modulate.a *= _modulate.a;

        /* Prevent underflow in 8-bit color channels: */
        if (_modulate.a > 0) {
            _modulate.a = max(_modulate.a, 1.0 / 256.0);
        }

        /* We tried this stochastic rounding scheme to avoid banding for very low coverage surfaces, but
           it doesn't look good:

        if ((_modulate.a > 0) && (_modulate.a < 254.5 / 255.0)) {
            _modulate.a = clamp(_modulate.a + randomVal(vec3(gl_FragCoord.xy * 100.0, 0)) * (1.0 / 255.0), 0.0, 1.0);
        }
        */

    } else {
        /* There is no diffusion for this surface */
        _modulate.a = 0.0;
    }
}
