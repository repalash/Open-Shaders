// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// Draw a quad close to far plane,
// this will produce white color everywhere where
// anything was rendered.
Shader "Hidden/Preview Shadow Mask" {
    SubShader {
        Tags { "ForceSupported" = "True" }
        Pass {
            ZTest GEqual
            ZWrite Off
            Cull Off
            SetTexture[_Dummy] { constantColor(1,1,1,1) combine constant }
        }
    }
}
