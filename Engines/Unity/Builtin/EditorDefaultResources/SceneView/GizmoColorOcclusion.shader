// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// colors from vertex data, one pass with regular depth testing
Shader "Hidden/Editor Gizmo Color Occlusion"
{
    SubShader
    {
        Tags { "ForceSupported" = "True" "Queue" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off Cull Off Fog { Mode Off }
        Pass // regular pass
        {
            ZTest LEqual
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            struct v2f
            {
                half4 color : COLOR0;
                float4 pos : SV_POSITION;
            };
            v2f vert (float3 pos : POSITION, float4 color : COLOR)
            {
                v2f o;
                o.color = color;
                o.pos = UnityObjectToClipPos(pos);
                return o;
            }
            half4 frag (v2f IN) : SV_Target { return IN.color; }
            ENDCG
        }
        // just one pass: "occluded" pass is never used for this mode
    }
}
