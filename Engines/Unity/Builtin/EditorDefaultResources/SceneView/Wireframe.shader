// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/SceneViewWireframe" {
    CGINCLUDE
        float4 vert (float4 pos : POSITION) : SV_POSITION
        {
            return mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, pos));
        }

        CBUFFER_START(UnitySceneViewColor)
            fixed4 unity_SceneViewWireColor;
        CBUFFER_END

        fixed4 frag () : COLOR
        {
            return unity_SceneViewWireColor;
        }
    ENDCG

    SubShader {
        Blend SrcAlpha OneMinusSrcAlpha
        ZTest LEqual ZWrite Off
        Offset -1, -1

        Pass {
            // SM2.0 (need different modes for SM2.0/SM3.0 due to how we hijack wireframe fragment shader; SM2 needs to come first)
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            ENDCG
        }

        Pass {
            // SM3.0
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.0
            ENDCG
        }
    }

    SubShader {
        Tags { "ForceSupported" = "True" }

        Blend SrcAlpha OneMinusSrcAlpha
        ZTest LEqual ZWrite Off
        Offset -1, -1

        Pass {
            // default
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            ENDCG
        }
    }
}
