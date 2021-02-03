// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Scene View Show Overdraw" {
Properties {
    _MainTex ("Base", 2D) = "white" {}
    _Cutoff ("Cutoff", float) = 0.5
}
Category {
ZWrite Off ZTest Always Blend One One
Color (0.1, 0.04, 0.02, 0)

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="Opaque" }
    Pass { }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="Transparent" }
    Pass {
        Cull Off
        SetTexture[_MainTex] { constantColor(0.1, 0.04, 0.02, 0) combine constant, texture }
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="TransparentCutout" }
    Pass {
        SetTexture[_MainTex] { constantColor(0.1, 0.04, 0.02, 0) combine constant, texture }
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="TreeBark" }
    Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#include "UnityCG.cginc"
#include "UnityBuiltin3xTreeLibrary.cginc"
struct v2f {
    float4 pos : POSITION;
    fixed4 color : COLOR;
};
v2f vert (appdata_full v) {
    v2f o;
    TreeVertBark(v);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.color = float4(0.1, 0.04, 0.02, 0);
    return o;
}
fixed4 frag (v2f i) : SV_Target { return i.color; }
ENDCG
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="TreeLeaf" }
    Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#include "UnityCG.cginc"
#include "UnityBuiltin3xTreeLibrary.cginc"
struct v2f {
    float4 pos : POSITION;
    fixed4 color : COLOR;
    float4 uv : TEXCOORD0;
};
v2f vert (appdata_full v) {
    v2f o;
    TreeVertLeaf (v);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    o.color = float4(0.1, 0.04, 0.02, 0);
    return o;
}
sampler2D _MainTex;
fixed4 frag (v2f i) : SV_Target
{
    fixed4 c = tex2D(_MainTex, i.uv.xy);
    i.color.a = c.a;
    return i.color;
}
ENDCG
        //AlphaTest GEqual [_Cutoff]
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="TreeOpaque" }
    Pass {
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"
struct v2f {
    float4 pos : POSITION;
    fixed4 color : COLOR;
};
struct appdata {
    float4 vertex : POSITION;
    fixed4 color : COLOR;
};
v2f vert( appdata v ) {
    v2f o;
    TerrainAnimateTree(v.vertex, v.color.w);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.color = float4(0.1, 0.04, 0.02, 0);
    return o;
}
fixed4 frag (v2f i) : SV_Target { return i.color; }
ENDCG
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="TreeTransparentCutout" }
    Pass {
        Cull Off
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"
struct v2f {
    float4 pos : POSITION;
    fixed4 color : COLOR;
    float4 uv : TEXCOORD0;
};
struct appdata {
    float4 vertex : POSITION;
    fixed4 color : COLOR;
    float4 texcoord : TEXCOORD0;
};
v2f vert( appdata v ) {
    v2f o;
    TerrainAnimateTree(v.vertex, v.color.w);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    o.color = float4(0.1, 0.04, 0.02, 0);
    return o;
}
sampler2D _MainTex;
fixed4 frag (v2f i) : SV_Target
{
    fixed4 c = tex2D(_MainTex, i.uv.xy);
    i.color.a = c.a;
    return i.color;
}
ENDCG
        //AlphaTest GEqual [_Cutoff]
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="TreeBillboard" }
    Pass {
        Cull Off
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"
struct v2f {
    float4 pos : POSITION;
    fixed4 color : COLOR;
    float2 uv : TEXCOORD0;
};
v2f vert (appdata_tree_billboard v) {
    v2f o;
    TerrainBillboardTree(v.vertex, v.texcoord1.xy, v.texcoord.y);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv.x = v.texcoord.x;
    o.uv.y = v.texcoord.y > 0;
    o.color = float4(0.1, 0.04, 0.02, 0);
    return o;
}
sampler2D _MainTex;
fixed4 frag (v2f i) : SV_Target
{
    fixed4 c = tex2D(_MainTex, i.uv.xy);
    i.color.a = c.a;
    return i.color;
}
ENDCG
        //AlphaTest Greater 0
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="GrassBillboard" }
    Pass {
        Cull Off
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"
struct v2f {
    float4 pos : POSITION;
    fixed4 color : COLOR;
    float2 uv : TEXCOORD0;
};
v2f vert (appdata_full v) {
    v2f o;
    WavingGrassBillboardVert (v);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    o.color = float4(0.1, 0.04, 0.02, 0);
    return o;
}
sampler2D _MainTex;
fixed4 frag (v2f i) : SV_Target
{
    fixed4 c = tex2D(_MainTex, i.uv.xy);
    i.color.a = c.a;
    return i.color;
}
ENDCG
        //AlphaTest Greater [_Cutoff]
    }
}

SubShader {
    Tags { "ForceSupported" = "True" "RenderType"="Grass" }
    Pass {
        Cull Off
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#include "UnityCG.cginc"
#include "TerrainEngine.cginc"
struct v2f {
    float4 pos : POSITION;
    fixed4 color : COLOR;
    float2 uv : TEXCOORD0;
};
v2f vert (appdata_full v) {
    v2f o;
    WavingGrassVert (v);
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    o.color = float4(0.1, 0.04, 0.02, 1);
    return o;
}
sampler2D _MainTex;
fixed4 frag (v2f i) : SV_Target
{
    fixed4 c = tex2D(_MainTex, i.uv.xy);
    i.color.a = c.a;
    return i.color;
}
ENDCG
        //AlphaTest Greater [_Cutoff]
    }
}

}
}
