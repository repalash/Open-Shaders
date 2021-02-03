// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Light Probe Group Tetrahedra" {
    Properties
    {
        _Color ("Line Color", Color) = (1,0,1,1)
        _LineFarDistance ("Line Far Distance", Float) = 1
    }

    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"

        float4 _Color;
        float _LineFarDistance;

        struct appdata
        {
            float3 vertex : POSITION;
        };

        struct v2f
        {
            float4 pos : SV_POSITION;
            float4 color : COLOR0;
        };

        v2f vert (appdata v)
        {
            v2f o;

            half4 pos = half4(v.vertex, 1);
            o.pos = UnityObjectToClipPos(pos);

            float t = length(pos.xyz - _WorldSpaceCameraPos.xyz) / _LineFarDistance;
            o.color.rgb = _Color.rgb;
            o.color.a = clamp(lerp(1.0, 0.0, t), 0.1, 1.0);

            return o;
        }

        half4 frag (v2f i) : COLOR
        {
            return half4(i.color);
        }

        ENDCG

        Tags { "ForceSupported" = "True" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off Cull Off Fog { Mode Off }
        Offset -1, -1

        Pass {
            ZTest LEqual
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
            ENDCG
        }
        Pass {
            ZTest Greater
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
            ENDCG
        }
    }
}
