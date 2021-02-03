// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Scene View Show Mips" {
    Properties {
        _MainTex ("", 2D) = "white" {}
        _Control ("Control (RGBA)", 2D) = "red" {}
        _Splat3 ("Layer 3 (A)", 2D) = "white" {}
        _Splat2 ("Layer 2 (B)", 2D) = "white" {}
        _Splat1 ("Layer 1 (G)", 2D) = "white" {}
        _Splat0 ("Layer 0 (R)", 2D) = "white" {}
        _BaseMap ("", 2D) = "white" {}
        _Cutoff ("Cutoff", float) = 0.5
    }


CGINCLUDE
// Common code used by most of the things below
#include "UnityCG.cginc"
struct v2f {
    float4 pos : SV_POSITION;
    float2 uv : TEXCOORD0;
    float2 mipuv : TEXCOORD1;
};
uniform float4 _MainTex_ST;
uniform float4 _MainTex_TexelSize;
uniform float4 _MainTex_MipInfo;

UNITY_DECLARE_TEX2D(_MainTex);
UNITY_DECLARE_TEX2D(_SceneViewMipcolorsTexture);

uint GetMipCount(Texture2D tex)
{
#if defined(SHADER_API_D3D11) || defined(SHADER_API_D3D12) || defined(SHADER_API_D3D11_9X) || defined(SHADER_API_XBOXONE) || defined(SHADER_API_PSSL)
    #define MIP_COUNT_SUPPORTED 1
#endif
#if (defined(SHADER_API_OPENGL) || defined(SHADER_API_VULKAN)) && !defined(SHADER_STAGE_COMPUTE)
    // OpenGL only supports textureSize for width, height, depth
    // textureQueryLevels (GL_ARB_texture_query_levels) needs OpenGL 4.3 or above and doesn't compile in compute shaders
    // tex.GetDimensions converted to textureQueryLevels
    #define MIP_COUNT_SUPPORTED 1
#endif
    // Metal doesn't support high enough OpenGL version

#if defined(MIP_COUNT_SUPPORTED)
    uint mipLevel, width, height, mipCount;
    mipLevel = width = height = mipCount = 0;
    tex.GetDimensions(mipLevel, width, height, mipCount);
    return mipCount;
#else
    return 0;
#endif
}

float2 GetMipTexelSize(Texture2D tex, float2 texelSizeWH, float4 mipInfo)
{
    uint originalTextureMipCount = uint(mipInfo.y);
    if (originalTextureMipCount != 0)
    {
        // mipInfo :
        // x = quality setings minStreamingMipLevel
        // y = original mip count for texture
        // z = desired on screen mip level
        // w = loaded mip level

        // Mip count has been reduced but the texelSize was not updated to take that into account
        uint mipCount = GetMipCount(tex);
        if (mipCount == 0)
        {
            // Can't calculate, use the passed value
            mipCount = originalTextureMipCount - uint(mipInfo.w);
        }
        uint mipReductionLevel = originalTextureMipCount - mipCount;
        uint mipReductionFactor = 1 << mipReductionLevel;
        if (mipReductionFactor)
        {
            float oneOverMipReductionFactor = 1.0 / mipReductionFactor;
            texelSizeWH *= oneOverMipReductionFactor;
        }
    }

    return texelSizeWH;
}

//#define COMPUTE_MIP_UVS(uv)       (uv * _MainTex_TexelSize.zw / 8.0)
#define COMPUTE_MIP_UVS(uv)     (uv * GetMipTexelSize(_MainTex, _MainTex_TexelSize.zw, _MainTex_MipInfo) / 8.0)

v2f vert( appdata_base v ) {
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = TRANSFORM_TEX(v.texcoord,_MainTex);
    o.mipuv = COMPUTE_MIP_UVS(o.uv);

    return o;
}

fixed4 frag(v2f i) : COLOR
{
    fixed4 col = UNITY_SAMPLE_TEX2D(_MainTex, i.uv);
    half4 mip = UNITY_SAMPLE_TEX2D(_SceneViewMipcolorsTexture, i.mipuv);
    half4 res;
    res.rgb = lerp(col.rgb, mip.rgb, mip.a);
    res.a = col.a;
    return res;
}

struct v2fGrass {
    float4 pos : SV_POSITION;
    fixed4 color : COLOR;
    float2 uv : TEXCOORD0;
    float2 mipuv : TEXCOORD1;
};

fixed4 fragGrass(v2fGrass i) : COLOR
{
    fixed4 col = UNITY_SAMPLE_TEX2D(_MainTex, i.uv);
    half4 mip = UNITY_SAMPLE_TEX2D(_SceneViewMipcolorsTexture, i.mipuv);
    half4 res;
    res.rgb = lerp(col.rgb, mip.rgb, mip.a);
    res.a = col.a * i.color.a;
    return res;
}
ENDCG

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="Opaque" }
    Pass {
CGPROGRAM

// As both normal opaque shaders and terrain splat shaders
// have "Opaque" render type, we need to do some voodoo
// to make both work.

#pragma vertex vertWTerrain
#pragma fragment fragWTerrain
#pragma target 2.0
#pragma exclude_renderers gles

struct v2fterr {
    float4 pos : SV_POSITION;
    float2 uvnormal : TEXCOORD0;
    float2 mipnormal : TEXCOORD1;
    float4 uv[3] : TEXCOORD2;
    float nonterrain  : TEXCOORD5;
};

uniform float4 _Splat0_ST,_Splat1_ST,_Splat2_ST,_Splat3_ST,_Splat4_ST;
uniform float4 _Splat0_TexelSize,_Splat1_TexelSize,_Splat2_TexelSize,_Splat3_TexelSize,_Splat4_TexelSize;
uniform float4 _BaseMap_TexelSize;

v2fterr vertWTerrain( appdata_base v ) {
    v2fterr o;
    o.pos = UnityObjectToClipPos(v.vertex);
    // assume it's not a terrain if _Splat0_TexelSize is not set up.
    float nonterrain = _Splat0_TexelSize.z==0.0 ? 1:0;
    // collapse/don't draw terrain's add pass in this mode, since it looks really bad if first pass
    // and add pass blink depending on which gets drawn first with this replacement shader
    // TODO: make it display mips properly even for two-pass terrains.
    o.pos *= _MainTex_TexelSize.z==0.0 && _Splat0_TexelSize.z!=0.0 ? 0 : 1;
    // normal texture UV
    o.uvnormal = TRANSFORM_TEX(v.texcoord,_MainTex);
    // terrain splat UVs
    float2 baseUV = v.texcoord.xy;
    o.uv[0].xy = baseUV;
    o.uv[0].zw = half2(0,0);
    o.uv[1].xy = TRANSFORM_TEX (baseUV, _Splat0);
    o.uv[1].zw = TRANSFORM_TEX (baseUV, _Splat1);
    o.uv[2].xy = TRANSFORM_TEX (baseUV, _Splat2);
    o.uv[2].zw = TRANSFORM_TEX (baseUV, _Splat3);
    o.mipnormal = COMPUTE_MIP_UVS(o.uvnormal);

    o.nonterrain = nonterrain;
    return o;
}
UNITY_DECLARE_TEX2D(_Control);
UNITY_DECLARE_TEX2D(_Splat0);
UNITY_DECLARE_TEX2D(_Splat1);
UNITY_DECLARE_TEX2D(_Splat2);
UNITY_DECLARE_TEX2D(_Splat3);
UNITY_DECLARE_TEX2D(_BaseMap);
fixed4 fragWTerrain(v2fterr i) : COLOR
{
    // sample regular texture
    fixed4 colnormal = UNITY_SAMPLE_TEX2D(_MainTex, i.uvnormal);

    // mip level of normal texture
    half4 mipnormal = UNITY_SAMPLE_TEX2D(_SceneViewMipcolorsTexture, i.mipnormal);

    // sample splatmaps
    half4 splat_control = UNITY_SAMPLE_TEX2D(_Control, i.uv[0].xy);
    half3 splat_color = splat_control.r * UNITY_SAMPLE_TEX2D(_Splat0, i.uv[1].xy).rgb;
    splat_color += splat_control.g * UNITY_SAMPLE_TEX2D(_Splat1, i.uv[1].zw).rgb;
    splat_color += splat_control.b * UNITY_SAMPLE_TEX2D(_Splat2, i.uv[2].xy).rgb;
    splat_color += splat_control.a * UNITY_SAMPLE_TEX2D(_Splat3, i.uv[2].zw).rgb;

    // mip levels for each splatmap
    half4 mipsplat = splat_control.r * UNITY_SAMPLE_TEX2D(_SceneViewMipcolorsTexture, i.uv[1].xy * _Splat0_TexelSize.zw / 8.0);
    mipsplat += splat_control.g * UNITY_SAMPLE_TEX2D(_SceneViewMipcolorsTexture, i.uv[1].zw * _Splat1_TexelSize.zw / 8.0);
    mipsplat += splat_control.b * UNITY_SAMPLE_TEX2D(_SceneViewMipcolorsTexture, i.uv[2].zw * _Splat2_TexelSize.zw / 8.0);
    mipsplat += splat_control.a * UNITY_SAMPLE_TEX2D(_SceneViewMipcolorsTexture, i.uv[2].zw * _Splat3_TexelSize.zw / 8.0);

    // lerp between normal and splatmaps
    half3 col = lerp(splat_color, colnormal.rgb, (half)i.nonterrain);
    half4 mip = lerp(mipsplat, mipnormal, (half)i.nonterrain);

    half4 res;
    res.rgb = lerp(col.rgb, mip.rgb, mip.a);
    res.a = colnormal.a;
    return res;
}
ENDCG
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="Transparent" }
    Pass {
        Cull Off
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#pragma exclude_renderers gles
ENDCG
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="TransparentCutout" }
    Pass {
        AlphaTest Greater [_Cutoff]
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#pragma exclude_renderers gles
ENDCG
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="TreeBark" }
    Pass {
CGPROGRAM
#pragma vertex vertTreeBark
#pragma fragment frag
#pragma target 2.0
#pragma exclude_renderers gles
#include "UnityCG.cginc"
#include "UnityBuiltin3xTreeLibrary.cginc"
v2f vertTreeBark (appdata_full v) {
    v2f o;
    TreeVertBark(v);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    o.mipuv = COMPUTE_MIP_UVS(o.uv);
    return o;
}
ENDCG
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="TreeLeaf" }
    Pass {
CGPROGRAM
#pragma vertex vertTreeLeaf
#pragma fragment frag
#pragma target 2.0
#pragma exclude_renderers gles
#include "UnityCG.cginc"
#include "UnityBuiltin3xTreeLibrary.cginc"
v2f vertTreeLeaf (appdata_full v) {
    v2f o;
    TreeVertLeaf (v);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    o.mipuv = COMPUTE_MIP_UVS(o.uv);
    return o;
}
ENDCG
        AlphaTest GEqual [_Cutoff]
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="TreeOpaque" }
    Pass {
CGPROGRAM
#pragma vertex vertTree
#pragma fragment frag
#pragma target 2.0
#pragma exclude_renderers gles
#include "TerrainEngine.cginc"
struct appdata {
    float4 vertex : POSITION;
    fixed4 color : COLOR;
    float2 texcoord : TEXCOORD0;
};
v2f vertTree( appdata v ) {
    v2f o;
    TerrainAnimateTree(v.vertex, v.color.w);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    o.mipuv = COMPUTE_MIP_UVS(o.uv);
    return o;
}
ENDCG
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="TreeTransparentCutout" }
    Pass {
        Cull Off
CGPROGRAM
#pragma vertex vertTree
#pragma fragment frag
#pragma target 2.0
#pragma exclude_renderers gles
#include "TerrainEngine.cginc"
struct appdata {
    float4 vertex : POSITION;
    fixed4 color : COLOR;
    float4 texcoord : TEXCOORD0;
};
v2f vertTree( appdata v ) {
    v2f o;
    TerrainAnimateTree(v.vertex, v.color.w);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    o.mipuv = COMPUTE_MIP_UVS(o.uv);
    return o;
}
ENDCG
        AlphaTest GEqual [_Cutoff]
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="TreeBillboard" }
    Pass {
        Cull Off
        ZWrite Off
CGPROGRAM
#pragma vertex vertTree
#pragma fragment frag
#pragma target 2.0
#pragma exclude_renderers gles
#include "TerrainEngine.cginc"
v2f vertTree (appdata_tree_billboard v) {
    v2f o;
    TerrainBillboardTree(v.vertex, v.texcoord1.xy, v.texcoord.y);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv.x = v.texcoord.x;
    o.uv.y = v.texcoord.y > 0;
    o.mipuv = COMPUTE_MIP_UVS(o.uv);
    return o;
}
ENDCG

        SetTexture [_MainTex] { combine primary, texture }
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="GrassBillboard" }
    Pass {
        Cull Off
CGPROGRAM
#pragma vertex vertGrass
#pragma fragment fragGrass
#pragma target 2.0
#pragma exclude_renderers gles
#include "TerrainEngine.cginc"
v2fGrass vertGrass (appdata_full v) {
    v2fGrass o;
    WavingGrassBillboardVert (v);
    o.color = v.color;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    o.mipuv = COMPUTE_MIP_UVS(o.uv);
    return o;
}
ENDCG
        AlphaTest Greater [_Cutoff]
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="Grass" }
    Pass {
        Cull Off
CGPROGRAM
#pragma vertex vertGrass
#pragma fragment fragGrass
#pragma target 2.0
#pragma exclude_renderers gles
#include "TerrainEngine.cginc"
v2fGrass vertGrass (appdata_full v) {
    v2fGrass o;
    WavingGrassVert (v);
    o.color = v.color;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    o.mipuv = COMPUTE_MIP_UVS(o.uv);
    return o;
}
ENDCG
        AlphaTest Greater [_Cutoff]
    }
}

Fallback Off
}
