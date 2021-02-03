#ifndef GIMode_glsl
#define GIMode_glsl

// DEBUG_VISUALIZATION_MODE values. Keep in sync with GIMode.h
#define DebugVisualizationMode_IRRADIANCE_PROBE_CONTRIBUTIONS    0
#define DebugVisualizationMode_NONE                              1
#define DebugVisualizationMode_IRRADIANCE                        2
#define DebugVisualizationMode_DEPTH                             3

#ifndef DEBUG_VISUALIZATION_MODE
#define DEBUG_VISUALIZATION_MODE DebugVisualizationMode_NONE
#endif

#endif