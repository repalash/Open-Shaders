// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// text (used by icons)
Shader "Hidden/Editor Gizmo Text"
{
    Properties
    {
        _MainTex ("", 2D) = "white" {}
    }
    SubShader
    {
        Tags { "ForceSupported" = "True" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off Cull Off Fog { Mode Off }
        Pass // regular pass
        {
            ZTest LEqual
            SetTexture [_MainTex] { combine primary, texture alpha * primary }
        }
        Pass // occluded pass
        {
            ZTest Greater
            SetTexture [_MainTex] { combine primary, texture alpha * primary }
        }
    }
}
