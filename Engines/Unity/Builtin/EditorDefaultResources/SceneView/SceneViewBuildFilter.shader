// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/SceneViewBuildFilter"
{
    Properties
    {
        _MainTex("Base (RGB)", 2D) = "white" {}
    }
        SubShader
    {
        Tags{
        "RenderType" = "Transparent"
        "ForceSupported" = "True"
    }
        Pass
    {
        Cull Back
        ZWrite Off
        ZTest LEqual
        Offset -1, -1

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma target 2.0
        #include "UnityCG.cginc"

        struct appdata
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
        };

        struct v2f
        {
            float4 pos : POSITION;
            fixed4 color : COLOR;
        };

        v2f vert(appdata v)
        {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.color = fixed4(1, 0, 0, 1);
            return o;
        }

        fixed4 frag(v2f i) : SV_Target
        {
            return i.color;
        }
        ENDCG
        }
    }
    FallBack off
}
