// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Preview Encoded Normals"
{
    Properties {
        _MainTex ("Texture", Any) = "white" { }
        _Mip ("Mip", Float) = -1.0 // mip level to display; negative does regular sample
    }
    Subshader
    {
        Tags { "ForceSupported" = "True" "RenderType" = "Opaque" }
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment fragNormal
                #pragma require sampleLOD
                #include "UnityCG.cginc"

                #include "Preview.cginc"

            ENDCG
        }
    }
}
