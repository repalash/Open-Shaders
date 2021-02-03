// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// textured (used by icons)
Shader "Hidden/Editor Gizmo Textured"
{
    Properties
    {
        _MainTex ("", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "ForceSupported" = "True" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off Cull Off Fog { Mode Off }
        Offset -1, -1

CGINCLUDE
struct appdata
{
    float3 pos : POSITION;
    half4 color : COLOR;
    float2 uv : TEXCOORD0;
};
struct v2f
{
    half4 color : COLOR0;
    float2 uv : TEXCOORD0;
    float4 pos : SV_POSITION;
};
float4 _MainTex_ST;
v2f vert(appdata v)
{
    v2f o;
    o.color = saturate(v.color);
    o.uv = v.uv.xy * _MainTex_ST.xy + _MainTex_ST.zw;
    o.pos = UnityObjectToClipPos(v.pos);
    return o;
}

sampler2D _MainTex;

half4 frag (v2f v) : SV_Target
{
    float2 dx = ddx(v.uv);
    float2 dy = ddy(v.uv);
    // rotated grid uv offsets
    float2 uvOffsets = float2(0.125, 0.375);
    float4 offsetUV = float4(0.0, 0.0, 0.0, -1.0);
    // supersampled using 2x2 rotated grid
    half4 col = 0;
    offsetUV.xy = v.uv + uvOffsets.x * dx + uvOffsets.y * dy;
    col += tex2Dbias(_MainTex, offsetUV);
    offsetUV.xy = v.uv - uvOffsets.x * dx - uvOffsets.y * dy;
    col += tex2Dbias(_MainTex, offsetUV);
    offsetUV.xy = v.uv + uvOffsets.y * dx - uvOffsets.x * dy;
    col += tex2Dbias(_MainTex, offsetUV);
    offsetUV.xy = v.uv - uvOffsets.y * dx + uvOffsets.x * dy;
    col += tex2Dbias(_MainTex, offsetUV);
    col *= 0.25;

    col *= v.color;
    return col;
}
ENDCG
        Pass // regular pass
        {
            ZTest LEqual
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
        Pass // occluded pass
        {
            ZTest Greater
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            ENDCG
        }
    }
}
