// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/SeparableBlur"
{
    Properties
    {
        _MainTex("Main Texture", 2D) = "white" {}

    }
    SubShader
    {
        Pass
        {
            Tags { "RenderType" = "Opaque" }

            CGPROGRAM
            #pragma vertex vertex
            #pragma fragment fragment
            #pragma target 3.0
            #include "UnityCG.cginc"

            float2 _BlurDirection;
            sampler2D _MainTex;
            float4 _MainTex_TexelSize;

            struct Input
            {
                float4 position : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct Varying
            {
                float4 position : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            static float kCurveWeights[9] =
            {
                0.0204001988,
                0.0577929595,
                0.1215916882,
                0.1899858519,
                0.2204586031,
                0.1899858519,
                0.1215916882,
                0.0577929595,
                0.0204001988
            };

            Varying vertex(Input input)
            {
                Varying output;
                output.position = UnityObjectToClipPos(input.position);
                output.uv = input.uv;
                return output;
            }

            half4 fragment(Varying i) : SV_Target
            {
                float2 step = _MainTex_TexelSize.xy * _BlurDirection;
                float2 uv = i.uv - step * 4;
                half4 col = 0;
                for (int tap = 0; tap < 9; ++tap)
                {
                    col += tex2D(_MainTex, uv) * kCurveWeights[tap];
                    uv += step;
                }

                // Do not allow transparent textures for splash.
                col.a = 1;

                return col;
            }
            ENDCG
        }
    }
}
