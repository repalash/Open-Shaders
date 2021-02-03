// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Handles Lines" {
Properties
{
    _MainTex ("Texture", Any) = "white" {}
    [Enum(False,0, Never,1, Less,2, Equal,3, LEqual,4, Greater,5, NotEqual,6, GEqual,7, Always,8)] _HandleZTest("_HandleZTest", Int) = 8
}
SubShader {
    Tags { "ForceSupported" = "True" "Queue" = "Transparent" }
    Blend SrcAlpha OneMinusSrcAlpha
    ZWrite Off Cull Off Fog { Mode Off }
    ZTest [_HandleZTest]
    BindChannels {
        Bind "vertex", vertex
        Bind "color", color
        Bind "TexCoord", texcoord
    }
    Pass {
        SetTexture [_MainTex] { combine primary * texture }
    }
}
}
