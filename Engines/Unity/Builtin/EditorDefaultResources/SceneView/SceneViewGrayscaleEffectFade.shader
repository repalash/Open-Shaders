// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/SceneViewGrayscaleEffectFade" {
Properties {
    _MainTex ("Base (RGB)", RECT) = "white" {}
}
SubShader {
    Tags {
        "ForceSupported"="True"
    }
    Pass {
        ZTest Always Cull Off ZWrite Off
CGPROGRAM
#pragma vertex vert
#pragma fragment frag
#pragma target 2.0
#include "UnityCG.cginc"
uniform sampler2D _MainTex;
uniform float _Fade;

v2f_img vert (appdata_img v)
{
    v2f_img o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.uv = v.texcoord;
    return o;
}

fixed4 frag (v2f_img i) : COLOR
{
    float4 original = tex2D(_MainTex, i.uv);
    float grayscale = Luminance(original.rgb) * 0.6;
    float addFade = (grayscale + 0.5) * _Fade;
    float4 output = original * (1-_Fade) + float4(addFade,addFade,addFade,addFade);
    output.a = 1.0;
    return output;
}
ENDCG
    }
}
Fallback off
}
