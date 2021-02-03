// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Preview Shadow Plane Clip" {
    SubShader {
        Tags { "ForceSupported" = "True" }
        Pass {
            ZWrite Off
            Cull Off
            SetTexture[_Dummy] { constantColor(0,0,0,0) combine constant }
        }
    }
}
