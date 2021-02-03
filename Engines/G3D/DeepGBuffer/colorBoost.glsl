#ifndef colorBoost_glsl
#define colorBoost_glsl
float colorBoost(float3 color, float unsaturatedBoost, float saturatedBoost) {
    // Avoid computing the HSV transform in the common case
    if (unsaturatedBoost == saturatedBoost) {
        return unsaturatedBoost;
    }

    float ma = max(color.x, max(color.y, color.z));
    float mi = min(color.x, min(color.y, color.z));
    float saturation = (ma == 0.0f) ? 0.0f : ((ma - mi) / ma);

    return lerp(unsaturatedBoost, saturatedBoost, saturation);
}
#endif