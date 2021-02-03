// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/SceneView grid ortho" {
SubShader {
    Tags { "ForceSupported" = "True" "Queue" = "Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
    Blend SrcAlpha OneMinusSrcAlpha
    ZWrite Off Cull Off Fog { Mode Off }
    Pass {
        CGPROGRAM

        #pragma vertex vert
        #pragma fragment frag
        #pragma target 2.0
        #include "UnityCG.cginc"

        struct vertexInput {
            float4 vertex : POSITION;
            float4 texcoord0 : TEXCOORD0;
            fixed4 color : COLOR;
        };

        struct fragmentInput {
            float4 position : SV_POSITION;
            float4 texcoord0 : TEXCOORD0;
            float4 color : COLOR;
        };

        fragmentInput vert (vertexInput i) {
            fragmentInput o;
            o.position = UnityObjectToClipPos(i.vertex);
            o.texcoord0 = i.texcoord0;
            o.color = i.color;
            return o;
        }

        float4 frag (fragmentInput i) : COLOR {
            float r = saturate (i.texcoord0.x - 0.1);
            return float4 (i.color.r, i.color.g, i.color.b, r * i.color.a);
        }

        ENDCG
    }
}
}
