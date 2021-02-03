// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/TimelineDetail" {
    Properties {
        _Color ("Color", Color) = (1,1,1,1)
        _PixelScaleX ("PixelScaleX", Float) = 1.0
    }
    SubShader {
        Tags { "ForceSupported" = "True" }
        Lighting Off
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite Off
        ZTest Always
        BindChannels {
            Bind "vertex", vertex
            Bind "color", color
        }
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 clipUV : TEXCOORD1;
            };

            uniform fixed4 _Color;
            uniform float _PixelScaleX;
            uniform float4x4 unity_GUIClipTextureMatrix;

            v2f vert (float4 weirdVertex : POSITION, float4 color : COLOR0)
            {
                // NOTE: vertex z value is the signed half width of the block, positive for the right side and negative for the left side.
                //  Calculate the width of the box in screen size and throw away the z value
                float signedLocalHalfWidth = weirdVertex.z;
                float screenHalfWidth = abs(signedLocalHalfWidth * _PixelScaleX);
                float4 vertex = float4(weirdVertex.xy, 0.0f, 1.0f);

                // For boxes so small that they would disappear when rasterizing, extend each size with half the remaining size
                const float leastHalfWidth = 1.0f;
                if (screenHalfWidth <= leastHalfWidth)
                {
                    float remainderRatio = ((leastHalfWidth - screenHalfWidth) / screenHalfWidth);
                    vertex.x += remainderRatio * signedLocalHalfWidth;
                }

                v2f o;
                o.vertex = UnityObjectToClipPos(vertex);
                float3 screenUV = UnityObjectToViewPos(vertex);
                o.clipUV = mul(unity_GUIClipTextureMatrix, float4(screenUV.xy, 0, 1.0));
                o.color = color * _Color;
                return o;
            }

            sampler2D _GUIClipTexture;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = i.color;
                col.a *= tex2D(_GUIClipTexture, i.clipUV).a;
                return col;
            }
            ENDCG
        }
    }
}
