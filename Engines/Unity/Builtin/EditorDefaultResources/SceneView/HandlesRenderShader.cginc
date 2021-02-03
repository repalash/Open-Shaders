// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#include "UnityCG.cginc"

struct v2f {
    float4 pos : SV_POSITION;
    fixed4 color : COLOR0;
};

uniform float4 _MainTex_ST;
uniform float4 _GroundColor, _SkyColor, _Color, _HandleColor;
uniform float _HandleSize;
uniform float4x4 _ObjectToWorld;

struct appdata_color {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
    fixed4 color : COLOR0;
    UNITY_VERTEX_INPUT_INSTANCE_ID
};

#if defined(INSTANCING_ON)
// Link this define to POINT_CLOUD_BATCH_SIZE from LightProbeVisualization.cpp
    #define MAX_INSTANCED_HANDLES 1000
    CBUFFER_START (InstancingData)
        uniform float4 PositionArray[MAX_INSTANCED_HANDLES];
    CBUFFER_END
#endif

v2f vert (appdata_color v)
{
    v2f o;

    UNITY_SETUP_INSTANCE_ID (v);

    fixed4 color = v.color * _HandleColor;

#if defined(INSTANCING_ON)
    //Only the position is instance based
    float4 vertexWorld = v.vertex * float4 (_HandleSize, _HandleSize,_HandleSize, 1) + float4(PositionArray[unity_InstanceID].xyz, 0);
    o.pos = mul( UNITY_MATRIX_VP, vertexWorld );

    float3 worldSpaceNormal = v.normal;

    // base (forward) light - 1.6 & 2.0 style
    o.color.rgb = mul ((float3x3)UNITY_MATRIX_V, v.normal).z * _Color.rgb;
#else
    o.pos = UnityObjectToClipPos (v.vertex * float4 (_HandleSize, _HandleSize,_HandleSize, 1));
    float3 worldSpaceNormal = normalize (mul((float3x3)_ObjectToWorld, v.normal));

    // base (forward) light - 1.6 & 2.0 style
    o.color.rgb = mul ((float3x3)UNITY_MATRIX_MV, v.normal).z * _Color.rgb;
#endif


    // hemisphere lighting - 2.5 style
    float3 hemisphere = lerp (_GroundColor, _SkyColor, worldSpaceNormal.y * .5 + .5) * color;

    // soft-add it
    o.color.rgb += hemisphere;
    o.color.rgb *= color.rgb;

    o.color.a = color.a * 2;

    if (color.a < .5)
        o.color.rgb = color.rgb * 2;
    else
        o.color.a -= 1;

    return o;
}

fixed4 frag_handles (v2f i) : SV_Target
{
    return i.color;
}
