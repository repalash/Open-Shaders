// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// simple wire
Shader "Hidden/Editor Gizmo"
{
    SubShader
    {
        Tags { "ForceSupported" = "True" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off Cull Off Fog { Mode Off }
        Offset -1, -1

        CGINCLUDE
        #pragma vertex vert
        #pragma fragment frag
        #include "UnityCG.cginc"
        float4 _GizmoBatchColor;
        struct v2f
        {
            half4 color : COLOR0;
            float4 pos : SV_POSITION;
        };
        v2f vert (float3 pos : POSITION, float4 color : COLOR)
        {
            v2f o;
            if (_GizmoBatchColor.a >= 0)
                color = _GizmoBatchColor;
            o.color = saturate(color);
            o.pos = UnityObjectToClipPos(pos);
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
