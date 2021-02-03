// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/UIElements/AACurveField"
{
    Properties
    {
        _ZoomFactor("Zoom Factor", float) = 1
        _ZoomCorrection("Zoom correction", float) = 1
    }
    SubShader
    {
        Tags{ "RenderType" = "Transparent" }
        LOD 100

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag

        #include "UnityCG.cginc"
        // must be the same as CurveField.cs
        static const float k_EdgeWidth = 2;
        static const float k_MinEdgeWidth = 1.75;
        static const float k_HalfWidth = k_EdgeWidth * 0.5;
        static const float k_VertexHalfWidth = k_HalfWidth + 1;

        struct appdata
        {
            float4 vertex : POSITION;
            float3 normal : NORMAL;
        };

        struct v2f
        {
            float4 vertex : SV_POSITION;
            float2 clipUV : TEXCOORD1;
            float dist : TEXCOORD2;
        };
        uniform float4x4 unity_GUIClipTextureMatrix;
        float _ZoomCorrection;
        fixed4 _Color;

        v2f vert(appdata v)
        {
            float3 vertex = v.vertex + float3(v.normal.xy,0) * _ZoomCorrection;
            v2f o;
            float3 eyePos = UnityObjectToViewPos(vertex);
            o.vertex = UnityObjectToClipPos(vertex);
            o.dist = v.normal.z;
            o.clipUV = mul(unity_GUIClipTextureMatrix, float4(eyePos.xy, 0, 1.0));
            return o;
        }

        float _ZoomFactor;
        sampler2D _GUIClipTexture;

        fixed4 frag(v2f i) : SV_Target
        {
            float distance = abs(i.dist * _ZoomFactor);

            distance = (k_HalfWidth * _ZoomFactor - distance) + 0.5;

            float clipA = tex2D(_GUIClipTexture, i.clipUV).a;
            return fixed4(_Color.rgb, _Color.a * saturate(distance) * clipA);
        }
            ENDCG
        }
    }
}
