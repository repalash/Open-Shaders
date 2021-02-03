// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Terrain Brush Preview"
{
    Properties
    {
        _MainTex ("Main", 2D) = "gray" {}
        _CutoutTex ("Cutout", 2D) = "black" {}
    }
    Subshader {
        ZWrite Off
        Offset -1, -1
        ColorMask RGB
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0

            #include "UnityCG.cginc"
            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
            };
            float4x4 unity_Projector;
            v2f vert (float4 v : POSITION)
            {
                v2f o;
                o.uv = mul(unity_Projector, v).xy;
                o.vertex = UnityObjectToClipPos(v);
                return o;
            }
            sampler2D _MainTex;
            sampler2D _CutoutTex;
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 c = fixed4(0.2, 0.7, 1.0, 0.5);
                c.a *= tex2D (_MainTex, i.uv).a;
                c.a *= tex2D (_CutoutTex, i.uv).a;
                return c;
            }
            ENDCG
        }
    }
}
