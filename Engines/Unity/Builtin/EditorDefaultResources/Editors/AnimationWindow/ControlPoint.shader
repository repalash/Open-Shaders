// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)


Shader "Hidden/AnimationWindowControlPoint" {
    Properties { _MainTex ("Texture", Any) = "white" {} }
    SubShader {
        Tags { "ForceSupported" = "True" }

        Lighting Off
        Blend SrcAlpha OneMinusSrcAlpha
        Cull Off
        ZWrite Off
        ZTest Always

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct v2f {
                float4 vertex : SV_POSITION;
                fixed4 color : COLOR;
                float2 uv : TEXCOORD0;
                float2 clipUV : TEXCOORD1;
            };

            uniform float4 _MainTex_ST;
            uniform float4x4 unity_GUIClipTextureMatrix;

            v2f vert (float4 vertex : POSITION, float2 uv : TEXCOORD0, float4 color : COLOR0)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(vertex);
                float3 screenUV = UnityObjectToViewPos(vertex);
                o.clipUV = mul(unity_GUIClipTextureMatrix, float4(screenUV.xy, 0, 1.0));
                o.color = color;
                o.uv = TRANSFORM_TEX(uv,_MainTex);
                return o;
            }

            sampler2D _MainTex;
            sampler2D _GUIClipTexture;

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv) * i.color;
                col.a *= tex2D(_GUIClipTexture, i.clipUV).a;
                return col;
            }
            ENDCG
        }
    }
}
