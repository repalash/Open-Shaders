// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Light Probe Handles Shaded" {
    Properties {
        _Color ("Main Color", Color) = (1,1,1,1)
        _SkyColor ("Sky Color", Color) = (1,1,1,1)
        _GroundColor ("Ground Color", Color) = (1,1,1,1)
        _MainTex ("Base (RGB) Gloss (A)", 2D) = "white" {}
    }
    SubShader {
        Tags { "Queue" = "Transparent" "ForceSupported" = "True" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Pass {
            ZTest LEqual
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_handles
            #pragma multi_compile_instancing
            #include "HandlesRenderShader.cginc"
            ENDCG
        }
        Pass {
            ZTest Greater
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag_handles
            #pragma multi_compile_instancing
            #include "HandlesRenderShader.cginc"
            ENDCG
        }
    }
}
