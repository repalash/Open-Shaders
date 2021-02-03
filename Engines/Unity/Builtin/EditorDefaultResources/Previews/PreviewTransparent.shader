// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Preview Transparent"
{
    Properties {
        _MainTex ("Texture", 2D) = "white" {}
        _Mip ("Mip", Float) = -1.0 // mip level to display; negative does regular sample
    }

    Subshader {
        Tags { "ForceSupported" = "True" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        Lighting Off Cull Off ZWrite Off ZTest Always Blend SrcAlpha OneMinusSrcAlpha
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma require sampleLOD

            #include "UnityCG.cginc"

            #define PREVIEW_TRANSPARANT
            #include "Preview.cginc"

            ENDCG
        }
    }
}
