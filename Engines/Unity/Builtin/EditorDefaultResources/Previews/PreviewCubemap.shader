// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Preview Cubemap" {
Properties {
    _MainTex ("", Cube) = "" {}
    _Mip ("Mip", Float) = 0.0 // mip level to display; negative does regular sample
    _Alpha ("Alpha", float) = 0.0 // 1 = show alpha, 0 = show color
    _Intensity ("Intensity", Float) = 1.0 // lighting probe's intensity
    _IsNormalMap ("", Int) = 0
    _Exposure ("Exposure", Float) = 0.0 // exposure controller
}

SubShader {
    Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "ForceSupported" = "True"}

    Pass {

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma require sampleLOD
        #include "UnityCG.cginc"

        struct appdata {
            float4 pos : POSITION;
            float3 nor : NORMAL;
        };

        struct v2f {
            float3 uv : TEXCOORD0;
            float4 pos : SV_POSITION;
        };

        v2f vert (appdata v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.pos);
            float3 viewDir = -normalize(ObjSpaceViewDir(v.pos));
            o.uv = reflect(viewDir, v.nor);

            return o;
        }

        samplerCUBE _MainTex;
        half4 _MainTex_HDR;
        float _Mip;
        half _Alpha;
        half _Intensity;
        int _IsNormalMap;
        float _Exposure;

        fixed4 frag (v2f i) : COLOR0
        {
            fixed4 c = texCUBE(_MainTex, i.uv);
            fixed4 cmip = texCUBElod(_MainTex, float4(i.uv,_Mip));
            if (_Mip >= 0.0)
                c = cmip;
            if (_IsNormalMap)
            {
                c.rgb = 0.5f + 0.5f * UnpackNormal(c);
                c.a = 1;
            }
            c.rgb = DecodeHDR (c, _MainTex_HDR) * _Intensity;
            c.rgb *= exp2(_Exposure);

            c = lerp (c, c.aaaa, _Alpha);
            return c;
        }
        ENDCG
    }
}

}
