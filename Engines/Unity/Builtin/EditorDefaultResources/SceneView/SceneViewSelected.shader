// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/SceneViewSelected"
{
    Properties
    {
        _MainTex ("Main Texture", 2D) = "white" {}
        _Cutoff ("Alpha cutoff", Range(0,1)) = 0.01
    }

    SubShader
    {
        CGINCLUDE
        #pragma multi_compile _ UNITY_SINGLE_PASS_STEREO
        #include "UnityCG.cginc"
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

        Varying vertex(Input input)
        {
            Varying output;

            output.position = UnityObjectToClipPos(input.position);
            output.uv = UnityStereoTransformScreenSpaceTex(input.uv);
            return output;
        }
        ENDCG

        Tags { "RenderType"="Opaque" }

        // #0: things that are visible (pass depth). 1 in alpha, 1 in red (SM2.0)
        Pass
        {
            Blend One Zero
            ZTest LEqual
            Cull Off
            ZWrite Off
            // push towards camera a bit, so that coord mismatch due to dynamic batching is not affecting us
            Offset -0.02, 0

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            float _ObjectId;

            #define DRAW_COLOR float4(_ObjectId, 1, 1, 1)
            #include "SceneViewSelected.cginc"
            ENDCG
        }
        // #1: things that are visible (pass depth). 1 in alpha, 1 in red (SM3.0)
        Pass
        {
            Blend One Zero
            ZTest LEqual
            Cull Off
            ZWrite Off
            // push towards camera a bit, so that coord mismatch due to dynamic batching is not affecting us
            Offset -0.02, 0

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            float _ObjectId;

            #define DRAW_COLOR float4(_ObjectId, 1, 1, 1)
            #include "SceneViewSelected.cginc"
            ENDCG
        }

        // #2: all the things, including the ones that fail the depth test. Additive blend, 1 in green, 1 in alpha (SM2.0)
        Pass
        {
            Blend One One
            BlendOp Max
            ZTest Always
            ZWrite Off
            Cull Off
            ColorMask GBA
            // push towards camera a bit, so that coord mismatch due to dynamic batching is not affecting us
            Offset -0.02, 0

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            float _ObjectId;

            #define DRAW_COLOR float4(0, 0, 1, 1)
            #include "SceneViewSelected.cginc"
            ENDCG
        }

        // #3: all the things, including the ones that fail the depth test. Additive blend, 1 in green, 1 in alpha
        Pass
        {
            Blend One One
            BlendOp Max
            ZTest Always
            ZWrite Off
            Cull Off
            ColorMask GBA
            // push towards camera a bit, so that coord mismatch due to dynamic batching is not affecting us
            Offset -0.02, 0

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0

            float _ObjectId;

            #define DRAW_COLOR float4(0, 0, 1, 1)
            #include "SceneViewSelected.cginc"
            ENDCG
        }

        // #4: final postprocessing pass
        Pass
        {
            ZTest Always
            Cull Off
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vertex
            #pragma fragment fragment
            #pragma target 3.0
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;
            half4 _OutlineColor;

            half4 fragment(Varying i) : SV_Target
            {
                half4 col = tex2D(_MainTex, i.uv);

                bool isSelected = col.a > 0.9;
                float alpha = saturate(col.b * 10);
                if (isSelected)
                {
                    // outline color alpha controls how much tint the whole object gets
                    alpha = _OutlineColor.a;
                    if (any(i.uv - _MainTex_TexelSize.xy*2 < 0) || any(i.uv + _MainTex_TexelSize.xy*2 > 1))
                        alpha = 1;
                }
                bool inFront = col.g > 0.0;
                if (!inFront)
                {
                    alpha *= 0.3;
                    if (isSelected) // no tinting at all for occluded selection
                        alpha = 0;
                }
                float4 outlineColor = float4(_OutlineColor.rgb,alpha);
                return outlineColor;
            }
            ENDCG
        }

        // #5: separable blur pass, either horizontal or vertical
        Pass
        {
            ZTest Always
            Cull Off
            ZWrite Off

            CGPROGRAM
            #pragma vertex vertex
            #pragma fragment fragment
            #pragma target 3.0
            #include "UnityCG.cginc"

            float2 _BlurDirection;
            sampler2D _MainTex;
            float4 _MainTex_TexelSize;

            // 9-tap Gaussian kernel, that blurs green & blue channels,
            // keeps red & alpha intact.
            static const half4 kCurveWeights[9] = {
                half4(0,0.0204001988,0.0204001988,0),
                half4(0,0.0577929595,0.0577929595,0),
                half4(0,0.1215916882,0.1215916882,0),
                half4(0,0.1899858519,0.1899858519,0),
                half4(1,0.2204586031,0.2204586031,1),
                half4(0,0.1899858519,0.1899858519,0),
                half4(0,0.1215916882,0.1215916882,0),
                half4(0,0.0577929595,0.0577929595,0),
                half4(0,0.0204001988,0.0204001988,0)
            };

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
                return col;
            }
            ENDCG
        }

        // #6: Compare object ids
        Pass
        {
            ZTest Always
            Cull Off
            ZWrite Off

            CGPROGRAM
            #pragma vertex vertex
            #pragma fragment fragment
            #pragma target 3.0
            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_TexelSize;

            // 8 tap search around the current pixel to
            // see if it borders with an object that has a
            // different object id
            static const half2 kOffsets[8] = {
                half2(-1,-1),
                half2(0,-1),
                half2(1,-1),
                half2(-1,0),
                half2(1,0),
                half2(-1,1),
                half2(0,1),
                half2(1,1)
            };

            half4 fragment(Varying i) : SV_Target
            {
                float4 currentTexel = tex2D(_MainTex, i.uv);
                if (currentTexel.r == 0)
                    return currentTexel;

                // if the current texel borders with a
                // texel that has a differnt object id
                // set the alpha to 0. This implies an
                // edge.
                for (int tap = 0; tap < 8; ++tap)
                {
                    float id = tex2D(_MainTex, i.uv + (kOffsets[tap] * _MainTex_TexelSize.xy)).r;
                    if (id != 0 && id - currentTexel.r != 0)
                    {
                        currentTexel.a = 0;
                    }
                }
                return currentTexel;
            }
            ENDCG
        }
    }
}
