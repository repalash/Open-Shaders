// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Preview/CubemapArray" {
Properties {
    _MainTex ("CubemapArray", CubeArray) = "" {}
    _Mip ("Mip", Float) = 0.0 // mip level to display; negative does regular sample
    _Intensity ("Intensity", Float) = 1.0 // lighting probe's intensity
    _SliceIndex ("Slice", Int) = 0
    _Exposure ("Exposure", Float) = 0.0
}

SubShader {
    Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "ForceSupported" = "True"}

    Pass {

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma require sampleLOD
        #pragma require cubearray
        #include "UnityCG.cginc"



        struct appdata {
            float4 pos : POSITION;
            float3 nor : NORMAL;
        };

        struct v2f {
            float3 uv : TEXCOORD0;
            float4 pos : SV_POSITION;
        };

        uniform int _SliceIndex;
        float _Mip;
        half _Alpha;
        half _Intensity;
        float _Exposure;

       v2f vert (appdata v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.pos);
            float3 viewDir = -normalize(ObjSpaceViewDir(v.pos));
            o.uv = reflect(viewDir, v.nor);
            return o;
        }

        half4 _MainTex_HDR;
        UNITY_DECLARE_TEXCUBEARRAY(_MainTex);
        fixed4 frag (v2f i) : COLOR0
        {
            fixed4 c = UNITY_SAMPLE_TEXCUBEARRAY(_MainTex, float4(i.uv, _SliceIndex));
            fixed4 cmip = UNITY_SAMPLE_TEXCUBEARRAY_LOD(_MainTex, float4(i.uv, _SliceIndex), _Mip);
            if (_Mip >= 0.0)
                c = cmip;
            c.rgb = DecodeHDR (c, _MainTex_HDR) * _Intensity;
            c.rgb *= exp2(_Exposure);
            c = lerp (c, c.aaaa, _Alpha);
            return c;
        }
        ENDCG
    }
}
    Fallback Off
}
