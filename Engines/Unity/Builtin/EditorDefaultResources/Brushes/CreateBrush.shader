// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/CreateBrush"
{
    Properties
    {
        _MainTex("Texture", 2D) = "white" {}
    }

    SubShader
    {
        // No culling or depth
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _MainTex;
            sampler2D _BrushFalloff;
            uniform float4 _BrushParams;

            #define kBrushRadiusScale _BrushParams[0]
            #define kBrushDataInRedChannel _BrushParams[1]
            #define kBrushBlackWhiteRemapMin _BrushParams[2]
            #define kBrushBlackWhiteRemapMax _BrushParams[3]

            float4 frag(v2f i) : SV_Target
            {
                float2 center = float2(0.5f, 0.5f);
                float dist = length(center - i.uv);
                float circleFalloff = 1.0f - smoothstep(kBrushRadiusScale - 0.05f, kBrushRadiusScale, dist);
                float4 brushData = tex2D(_MainTex, i.uv) * tex2D(_BrushFalloff, float2(dist / kBrushRadiusScale, 0.0f)).r;
                float brush = lerp(brushData.a, brushData.r, kBrushDataInRedChannel);
                float remap = saturate((brush - kBrushBlackWhiteRemapMin) / (kBrushBlackWhiteRemapMax- kBrushBlackWhiteRemapMin)).r;
                return circleFalloff * remap;
            }

            ENDCG
        }
    }
}
