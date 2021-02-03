// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)


#ifdef VT

#include "UnityLegacyTextureStack.cginc"

DECLARE_STACK_CB(Stack);
DECLARE_STACK(Stack, _MainTex);
UNITY_DECLARE_TEX2D(_MainTex);

#else

sampler2D _MainTex;

#endif

uniform float4x4 unity_GUIClipTextureMatrix;
uniform float4 _MainTex_ST;
sampler2D _GUIClipTexture;

uniform bool _ManualTex2SRGB;
uniform bool _ManualTex2Linear;

uniform fixed4 _ColorMask;

struct v2f {
    float4 vertex : SV_POSITION;
    float2 uv : TEXCOORD0;
    float2 clipUV : TEXCOORD1;
};


v2f vert(float4 vertex : POSITION, float2 uv : TEXCOORD0) {
    v2f o;
    o.vertex = UnityObjectToClipPos(vertex);
    float3 screenUV = UnityObjectToViewPos(vertex);
    o.clipUV = mul(unity_GUIClipTextureMatrix, float4(screenUV.xy, 0, 1.0));
    o.uv = TRANSFORM_TEX(uv, _MainTex);
    return o;
}

uniform float _Mip;

fixed4 frag(v2f i) : SV_Target
{
#ifdef VT
    StackInfo info = PrepareStack(i.uv, Stack);
    StackInfo infoLod = PrepareStackLod(i.uv, Stack, _Mip);
    fixed4 c = SampleStack(info, _MainTex) * _ColorMask, cmip = SampleStackLod(infoLod,_MainTex) * _ColorMask;
#else
    fixed4 c = tex2D(_MainTex, i.uv) * _ColorMask, cmip = tex2Dlod(_MainTex, float4(i.uv.x, i.uv.y, 0, _Mip)) * _ColorMask;
#endif

    if (_Mip >= 0.0) c = cmip;
    if (_ManualTex2SRGB) c.rgb = LinearToGammaSpace(c.rgb);

#ifdef PREVIEW_TRANSPARANT
    c.a *= tex2D(_GUIClipTexture, i.clipUV).a;
#else
    c.a = tex2D(_GUIClipTexture, i.clipUV).a;
#endif

    return c;
}

fixed4 fragAlpha(v2f i) : SV_Target
{
#ifdef VT
    StackInfo info = PrepareStack(i.uv, Stack);
    StackInfo infoLod = PrepareStackLod(i.uv, Stack, _Mip);
    fixed4 c = SampleStack(info, _MainTex).aaaa, cmip = SampleStackLod(infoLod,_MainTex).aaaa;
#else
    fixed4 c = tex2D(_MainTex, i.uv).aaaa, cmip = tex2Dlod(_MainTex, float4(i.uv.x, i.uv.y, 0, _Mip)).aaaa;
#endif
    if (_Mip >= 0.0) c = cmip;
    c.a = UNITY_SAMPLE_1CHANNEL(_GUIClipTexture, i.clipUV);
    return c;
}

fixed4 fragNormal(v2f i) : SV_Target
{
#ifdef VT
    StackInfo info = PrepareStack(i.uv, Stack);
    StackInfo infoLod = PrepareStackLod(i.uv, Stack, _Mip);
    fixed4 pn = SampleStack(info, _MainTex), pnmip = SampleStackLod(infoLod,_MainTex);
#else
    fixed4 pn = tex2D(_MainTex, i.uv), pnmip = tex2Dlod(_MainTex, float4(i.uv.x, i.uv.y, 0, _Mip));
#endif
    if (_Mip >= 0.0) pn = pnmip;

    fixed3 normal = 0.5f + 0.5f * UnpackNormal(pn);
    fixed alpha = UNITY_SAMPLE_1CHANNEL(_GUIClipTexture, i.clipUV);
    fixed4 col = fixed4(normal.rgb, alpha);
    if (_ManualTex2Linear) col.rgb = GammaToLinearSpace(col.rgb);
    clip(col.a - 0.001);
    return col;
}
