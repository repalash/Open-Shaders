// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Preview Encoded Lightmap RGBM"
{
    Properties {
        _MainTex ("Texture", Any) = "white" { }
        _Mip ("Mip", Float) = -1.0 // mip level to display; negative does regular sample
        _ColorMask ("Color Mask", Color) = (1, 1, 1, 1)
        _Exposure ("Exposure", Float) = 0.0
    }
    Subshader
    {
        Tags { "ForceSupported" = "True" "RenderType" = "Opaque" }
        Cull Off ZWrite Off ZTest Always
        Pass
        {
            CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma require sampleLOD

                #if defined(UNITY_COLORSPACE_GAMMA)
                    // The editor always supports linear color space
                    #undef UNITY_COLORSPACE_GAMMA
                #endif

                #include "UnityCG.cginc"

                struct v2f {
                    float4 vertex : SV_POSITION;
                    float2 _uv0 : TEXCOORD0;
                    float2 _uv1 : TEXCOORD1;
                    fixed4 color : COLOR;
                };
                struct appdata_t {
                    float4 vertex : POSITION;
                    fixed4 color : COLOR;
                    float2 texcoord : TEXCOORD0;
                };

                uniform float4 _MainTex_ST;
                uniform float4 _MainTex_HDR;
                uniform float4x4 unity_GUIClipTextureMatrix;

                v2f vert (appdata_t v)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(v.vertex);
                    float3 texgen = UnityObjectToViewPos(v.vertex);
                    o._uv1 = mul(unity_GUIClipTextureMatrix, float4(texgen.xy, 0, 1.0)).xy;
                    o.color = v.color;
                    o._uv0 = TRANSFORM_TEX(v.texcoord,_MainTex);
                    return o;
                }
                sampler2D _MainTex;
                sampler2D _GUIClipTexture;
                uniform float _Mip;
                uniform fixed4 _ColorMask;
                float _Exposure;

                fixed4 frag( v2f i ) : COLOR
                {
                    fixed4 lmc = tex2D(_MainTex, i._uv0) * _ColorMask, lmcmip = tex2Dlod(_MainTex, float4(i._uv0.x, i._uv0.y, 0, _Mip)) * _ColorMask;
                    if (_Mip >= 0.0) lmc = lmcmip;
                    half3 lightmap = DecodeLightmapRGBM(lmc, _MainTex_HDR);
                    half alpha = UNITY_SAMPLE_1CHANNEL(_GUIClipTexture, i._uv1);

                    fixed4 col = i.color;
                    col.rgb *= lightmap;
                    col.rgb *= exp2(_Exposure);
                    col.a   *= alpha;
                    clip (col.a - 0.001);
                    return col;
                }
            ENDCG
        }
    }
}
