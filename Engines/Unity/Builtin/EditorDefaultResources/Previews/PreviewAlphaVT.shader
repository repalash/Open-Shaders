// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Preview Alpha VT"
{
    Properties {
        [TextureStack.Stack] _MainTex ("Texture", Any) = "white" {}
        _Mip ("Mip", Float) = -1.0 // mip level to display; negative does regular sample
    }
    Subshader {
        Tags { "ForceSupported" = "True" }
        Lighting Off Cull Off ZWrite Off ZTest Always Blend SrcAlpha OneMinusSrcAlpha
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragAlpha
            #pragma require sampleLOD

            #include "UnityCG.cginc"
            #define VT
            #include "Preview.cginc"

            ENDCG
        }
    }
}
