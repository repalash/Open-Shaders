// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// simple hardcoded lighting
Shader "Hidden/Editor Gizmo Lit"
{
    SubShader
    {
        Tags { "ForceSupported" = "True" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off Fog { Mode Off }

        CGINCLUDE
        #pragma vertex vert
        #pragma fragment frag
        #include "UnityCG.cginc"

        struct appdata
        {
            float3 pos : POSITION;
            float3 normal : NORMAL;
            float4 color : COLOR;
        };
        struct v2f
        {
            half4 color : COLOR0;
            float4 pos : SV_POSITION;
        };

        float4 _GizmoBatchColor;

        v2f vert (appdata IN)
        {
            v2f o;
            if (_GizmoBatchColor.a >= 0)
                IN.color = _GizmoBatchColor;
            float3 eyeNormal = normalize (mul ((float3x3)UNITY_MATRIX_IT_MV, IN.normal).xyz);
            float nl = saturate(eyeNormal.z);
            float lighting = 0.333 + nl * 0.667 * 0.5;
            float4 color;
            color.rgb = lighting * IN.color.rgb;
            color.a = IN.color.a;
            o.color = saturate(color);
            o.pos = UnityObjectToClipPos(IN.pos);
            return o;
        }
        ENDCG

        Pass // regular pass
        {
            ZTest LEqual
            CGPROGRAM
            half4 frag (v2f IN) : SV_Target { return IN.color; }
            ENDCG
        }
        Pass // occluded pass
        {
            ZTest Greater
            CGPROGRAM
            half4 frag (v2f IN) : SV_Target { return IN.color * half4(1,1,1,0.1); }
            ENDCG
        }
    }
}
