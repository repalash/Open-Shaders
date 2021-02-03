// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Physics/DebugVisWire" {
    SubShader {
        Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
        Lighting Off
        Color [_Color] Blend SrcAlpha OneMinusSrcAlpha
            ZTest LEqual ZWrite Off
            Offset -1, -20
            Pass { Cull Back }
    }
}
