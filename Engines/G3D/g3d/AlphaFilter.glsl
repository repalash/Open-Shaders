/**
  \file data-files/shader/AlphaFilter.glsl

  G3D Innovation Engine http://casual-effects.com/g3d
  Copyright 2000-2019, Morgan McGuire
  All rights reserved
  Available under the BSD License
*/
#ifndef G3D_AlphaHint_glsl
#define G3D_AlphaHint_glsl

#define AlphaFilter int
// These values must be kept in sync with AlphaFilter in constants.h
// Defined with macros so that they can be used in preprocessor instructions.
#define AlphaHint_ONE             1
#define AlphaHint_BINARY          2
#define AlphaHint_COVERAGE_MASK   3
#define AlphaHint_BLEND           4

/** Computes a coverage value from a raw alpha value. 

   \param alphaHintX Named with a trailing "X" because alphaFilter is a common macro argument name. */
float computeCoverage(AlphaFilter alphaHintX, float alpha) {
   if (alphaHintX == AlphaHint_ONE) {
        return 1.0;
   } else if (alphaHintX == AlphaHint_BINARY) {
        return (alpha >= 0.5) ? 1.0 : 0.0;
   } else if ((alphaHintX == AlphaHint_COVERAGE_MASK) || (alphaHintX == AlphaHint_BLEND)) {
        return alpha;
   } else {
        // Illegal alphaFilter value!
        return -1.0;
   }
}

#endif
