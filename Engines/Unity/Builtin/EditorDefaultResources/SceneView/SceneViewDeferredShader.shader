// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/SceneViewDeferredBuffers" {
    Properties {
        _MainTex ("", 2D) = "white" {}
    }
    SubShader {
        Tags { "ForceSupported"="True" }
        Cull Off ZWrite Off ZTest Always

        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(appdata v) {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            sampler2D _CameraGBufferTexture0;
            sampler2D _CameraGBufferTexture1;
            sampler2D _CameraGBufferTexture2;

            int _DisplayMode;

            fixed4 frag (v2f i) : SV_Target
            {
                half4 gbuf0 = tex2D (_CameraGBufferTexture0, i.uv);
                half4 gbuf1 = tex2D (_CameraGBufferTexture1, i.uv);
                half4 gbuf2 = tex2D (_CameraGBufferTexture2, i.uv);
                half4 col = half4(1,0,0,1);
                if (_DisplayMode == 0)
                    col = gbuf0;
                if (_DisplayMode == 1)
                    col = gbuf1;
                if (_DisplayMode == 2)
                    col = gbuf1.a;
                if (_DisplayMode == 3)
                    col = gbuf2;
                return col;
            }
            ENDCG
        }

    }
    FallBack off
}
