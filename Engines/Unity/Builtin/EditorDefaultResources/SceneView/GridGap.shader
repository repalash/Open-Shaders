// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/SceneView/GridGap" {

    Properties {
        _Gap("Gap", Vector) = (0, 0, 0, 0)
        _Stride("Stride", Vector) = (0, 0, 0, 0)
    }

    SubShader {
        Tags { "ForceSupported" = "True" "Queue" = "Transparent" "IgnoreProjector" = "True" "RenderType" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off Cull Off Fog { Mode Off }
        Pass {
            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag
            #pragma target 4.0
            #include "UnityCG.cginc"

            struct vertexInput {
                float4 vertex       : POSITION;     // current point position
                float4 otherVertex  : NORMAL;       // other point position
                float2 texcoord0    : TEXCOORD0;
                float2 value        : TEXCOORD1;    // current point value
                float2 otherValue   : TEXCOORD2;    // other point value
                fixed4 color        : COLOR;
            };

            struct fragmentInput {
                float4 position                     : SV_POSITION;
                float2 texcoord0                    : TEXCOORD0;
                nointerpolation float2 value        : TEXCOORD1;    // current point value
                nointerpolation float2 otherValue   : TEXCOORD2;    // other point value
                nointerpolation float4 clipPos      : TEXCOORD3;    // current point clip position
                nointerpolation float4 otherClipPos : TEXCOORD4;    // other point clip position
                float3 screenPos                    : TEXCOORD5;
                fixed4 color                        : COLOR;
            };

            float4 _Gap;
            float4 _Stride;

            fragmentInput vert(vertexInput i) {
                fragmentInput o;
                o.position = UnityObjectToClipPos(i.vertex);
                o.texcoord0 = i.texcoord0;
                o.value = i.value;
                o.otherValue = i.otherValue;
                o.clipPos = o.position;
                o.otherClipPos = UnityObjectToClipPos(i.otherVertex);
                o.screenPos = UnityObjectToViewPos(i.vertex);
                o.color = i.color;
                return o;
            }

            float4 frag(fragmentInput i) : COLOR {

                float3 ndc = float3(i.position.x / _ScreenParams.x, i.position.y / _ScreenParams.y, i.position.z);
                float3 clipPos;

#if defined(SHADER_API_GLCORE)
                clipPos = ndc * 2.0 - 1.0;
#else
                ndc.y = 1.0 - ndc.y;
                clipPos.xy = ndc.xy * 2.0 - 1.0;
                clipPos.z = ndc.z;
#endif

                clipPos *= i.position.w;

                // This is to workaround an interpolator precision issue on some AMD GPUs.
                // Instead of relying on the value produced by the hardware interpolator (which doesn't have sufficient precision for our use case),
                // we do the interpolation manually here in the pixel shader using the clip space positions of the current pixel and the two end points of the line.
                // Note that because we are doing the interpolation ourselves, 'nointerpolation' modifier is used on some vertex attributes.
                float fullDistance = length(i.otherClipPos.xyz - i.clipPos.xyz);
                float distanceToOther = length(i.otherClipPos.xyz - clipPos);
                float2 interpValue = lerp(i.otherValue, i.value, distanceToOther / fullDistance);

                float m = 1.0;
                float2 r = fmod(interpValue, _Stride.xy);
                if (any(r > _Gap.xy))
                    m = 0.0;
                m = m * saturate(i.texcoord0.x / -i.screenPos.z - 0.1);
                return fixed4(i.color.r, i.color.g, i.color.b, m * i.color.a);
            }

            ENDCG
        }
    }
}
