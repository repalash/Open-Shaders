// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/SceneViewAura" {
    Properties {
        _MainTex ("Base (RGB)", 2D) = "white" {}
    }
    SubShader {
        Tags {
            "RenderType"="Transparent"
            "ForceSupported"="True"
        }
        Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#include "UnityCG.cginc"

struct appdata {
    float4 vertex : POSITION;
    float3 normal : NORMAL;
};

struct v2f {
    float4 pos : POSITION;
    fixed4 color : COLOR;
};

v2f vert(appdata v) {
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    float3 norm = normalize(mul ((float3x3)UNITY_MATRIX_IT_MV, v.normal));
    float visibility = (1-(norm.z*norm.z));
    o.color = float4 (0.5,0.5,1,0.4) * visibility * visibility;
    return o;
}
fixed4 frag (v2f i) : SV_Target { return i.color; }
ENDCG
            Cull Back
            ZWrite Off
            ZTest Greater
            ColorMask RGB
            Blend SrcAlpha OneMinusSrcAlpha
        }
    }
    FallBack off
}
