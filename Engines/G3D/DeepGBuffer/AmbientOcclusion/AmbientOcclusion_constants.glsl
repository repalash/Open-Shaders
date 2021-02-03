#ifndef AmbientOcclusion_constants_glsl
#define AmbientOcclusion_constants_glsl

// If using depth mip levels, the log of the maximum pixel offset before we need to switch to a lower 
// miplevel to maintain reasonable spatial locality in the cache
// If this number is too small (< 3), too many taps will land in the same pixel, and we'll get bad variance that manifests as flashing.
// If it is too high (> 5), we'll get bad performance because we're not using the MIP levels effectively
#define LOG_MAX_OFFSET (3)

// This must be less than or equal to the MAX_MIP_LEVEL defined in SAmbientOcclusion.cpp
#define MAX_MIP_LEVEL (5)

/** Used for preventing AO computation on the sky (at infinite depth) and defining the CS Z to bilateral depth key scaling. 
    This need not match the real far plane but should not be much more than it.*/
const float FAR_PLANE_Z = -1000.0;

#endif