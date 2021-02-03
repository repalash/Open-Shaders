// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Sceneview Alpha Shader" {
    SubShader {
        Tags { "ForceSupported" = "True" }
        Pass {
            ZTest Always
            Blend DstAlpha Zero
            Color (1,1,1,1)
        }
    }
}
