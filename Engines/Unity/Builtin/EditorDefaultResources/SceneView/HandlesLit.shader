// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Handles Shaded" {
    Properties {
        _Color ("Main Color", Color) = (1,1,1,1)
        _SkyColor ("Sky Color", Color) = (1,1,1,1)
        _GroundColor ("Ground Color", Color) = (1,1,1,1)
        _MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
        [Enum(Always,0, Never,1, Less,2, Equal,3, LEqual,4, Greater,5, NotEqual,6, GEqual,7, Always,8)] _HandleZTest ("_HandleZTest", Int) = 8
    }
    Category {
        Fog {Mode Off}
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        ZTest [_HandleZTest]

        SubShader {
            Tags { "Queue" = "Transparent" "ForceSupported" = "True" }
            Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #include "HandlesRenderShader.cginc"
            fixed4 frag (v2f i) : COLOR { return i.color; }
            ENDCG
            }
        }
    }
}
