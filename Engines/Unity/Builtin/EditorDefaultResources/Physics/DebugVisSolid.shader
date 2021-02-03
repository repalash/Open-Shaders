// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Physics/DebugVisSolid" {
    SubShader {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        Lighting Off
        Color [_Color] Blend SrcAlpha OneMinusSrcAlpha
            ZTest LEqual ZWrite On
            Offset -0.2, -1
            Pass { Cull Back }
    }
}
