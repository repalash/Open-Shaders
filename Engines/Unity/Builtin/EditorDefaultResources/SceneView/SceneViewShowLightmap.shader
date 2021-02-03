// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Show Lightmap Resolution" {
    Properties {
        _Checkerboard ("", 2D) = "white" {}
    }
    SubShader {
        Pass{
            Tags { "ForceSupported" = "True" }
            LOD 200
            Cull Off

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "UnityCG.cginc"

            sampler2D _Checkerboard;
            float4 _Checkerboard_ST;

            struct appdata_vert
            {
                float4 vertex       : POSITION;
                float4 texcoord0    : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos  : POSITION;
                float2 uv   : TEXCOORD0;
            };

            v2f vert (appdata_vert v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord0.xy * _Checkerboard_ST.xy + _Checkerboard_ST.zw;
                return o;
            }

            float4 frag (v2f i) : COLOR
            {
                return tex2D (_Checkerboard, i.uv.xy);
            }

            ENDCG
        }
        Pass{
            Tags { "ForceSupported" = "True" }
            LOD 200
            Cull Off

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "UnityCG.cginc"

            sampler2D _Checkerboard;
            float4 _Checkerboard_ST;

            struct appdata_vert
            {
                float4 vertex       : POSITION;
                float4 texcoord1    : TEXCOORD1;
            };

            struct v2f
            {
                float4 pos  : POSITION;
                float2 uv   : TEXCOORD0;
            };

            v2f vert (appdata_vert v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord1.xy * _Checkerboard_ST.xy + _Checkerboard_ST.zw;
                return o;
            }

            float4 frag (v2f i) : COLOR
            {
                return tex2D (_Checkerboard, i.uv.xy);
            }

            ENDCG
        }
        Pass{
            Tags { "ForceSupported" = "True" }
            LOD 200
            Cull Off

            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "UnityCG.cginc"

            sampler2D _Checkerboard;
            float4 _Checkerboard_ST;

            struct appdata_vert
            {
                float4 vertex       : POSITION;
                float4 texcoord2    : TEXCOORD2;
            };

            struct v2f
            {
                float4 pos  : POSITION;
                float2 uv   : TEXCOORD0;
            };

            v2f vert (appdata_vert v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord2.xy * _Checkerboard_ST.xy + _Checkerboard_ST.zw;
                return o;
            }

            float4 frag (v2f i) : COLOR
            {
                return tex2D (_Checkerboard, i.uv.xy);
            }

            ENDCG
        }
    }
}
