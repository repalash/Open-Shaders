// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/BlitCopyHDRTonemap" {
    Properties
    {
        _MainTex ("Texture", any) = "" {}
        _NitsForPaperWhite("NitsForPaperWhite", Float) = 160.0
        _ColorGamut("ColorGamut", Int) = 0
    }
    SubShader {
        Pass {
            ZTest Always Cull Off ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);
            uniform float4 _MainTex_ST;
            uniform float _NitsForPaperWhite;
            uniform int _ColorGamut;

            struct appdata_t {
                float4 vertex : POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 texcoord : TEXCOORD0;
                UNITY_VERTEX_OUTPUT_STEREO
            };

            v2f vert (appdata_t v)
            {
                v2f o;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.texcoord = TRANSFORM_TEX(v.texcoord.xy, _MainTex);
                return o;
            }

            // These values must match the ColorGamut enum in ColorGamut.h
            #define kColorGamutSRGB         0
            #define kColorGamutRec709       1
            #define kColorGamutRec2020      2
            #define kColorGamutDisplayP3    3
            #define kColorGamutHDR10        4
            #define kColorGamutDolbyHDR     5

            float3 LinearToSRGB(float3 color)
            {
                // Approximately pow(color, 1.0 / 2.2)
                return color < 0.0031308 ? 12.92 * color : 1.055 * pow(abs(color), 1.0 / 2.4) - 0.055;
            }

            float3 SRGBToLinear(float3 color)
            {
                // Approximately pow(color, 2.2)
                return color < 0.04045 ? color / 12.92 : pow(abs(color + 0.055) / 1.055, 2.4);
            }

            static const float3x3 Rec709ToRec2020 =
            {
                0.627402, 0.329292, 0.043306,
                0.069095, 0.919544, 0.011360,
                0.016394, 0.088028, 0.895578
            };

            static const float3x3 Rec2020ToRec709 =
            {
                1.660496, -0.587656, -0.072840,
                -0.124547, 1.132895, -0.008348,
                -0.018154, -0.100597, 1.118751
            };

            float3 LinearToST2084(float3 color)
            {
                float m1 = 2610.0 / 4096.0 / 4;
                float m2 = 2523.0 / 4096.0 * 128;
                float c1 = 3424.0 / 4096.0;
                float c2 = 2413.0 / 4096.0 * 32;
                float c3 = 2392.0 / 4096.0 * 32;
                float3 cp = pow(abs(color), m1);
                return pow((c1 + c2 * cp) / (1 + c3 * cp), m2);
            }

            float4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
                // The scene is rendered with linear gamma and Rec.709 primaries. (DXGI_COLOR_SPACE_RGB_FULL_G10_NONE_P709)
                float4 scene = UNITY_SAMPLE_SCREENSPACE_TEXTURE(_MainTex, i.texcoord);
                float3 result = IsGammaSpace() ? float3(GammaToLinearSpaceExact(scene.r), GammaToLinearSpaceExact(scene.g), GammaToLinearSpaceExact(scene.b)) : scene.rgb;

                if (_ColorGamut == kColorGamutSRGB)
                {
                    result = LinearToSRGB(result);
                }
                else if (_ColorGamut == kColorGamutHDR10)
                {
                    const float st2084max = 10000.0;
                    const float hdrScalar = _NitsForPaperWhite / st2084max;
                    // The HDR scene is in Rec.709, but the display is Rec.2020
                    result = mul(Rec709ToRec2020, result);
                    // Apply the ST.2084 curve to the scene.
                    result = LinearToST2084(result * hdrScalar);
                }
                else // _ColorGamut == kColorGamutRec709
                {
                    // Just pass through
                }

                return float4(result.rgb, scene.a);
            }
            ENDCG

        }
    }
    Fallback Off
}
