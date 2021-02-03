// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Light Probe Wire" {
    SubShader
    {
        Tags { "ForceSupported" = "True" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off Cull Off Fog { Mode Off }
        Offset -1, -1
        BindChannels {
            Bind "Vertex", vertex
            Bind "Color", color
        }
        Color [color]
        Pass {
            ZTest LEqual
        }
        Pass {
            ZTest Greater
        }
    }
}
