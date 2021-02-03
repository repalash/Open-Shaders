// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// Visualise Spherical Harmonics
// sampled with vertex normal
Shader "Hidden/SH" {
Properties {
    _HandleSize ("HandleSize", Float) = 0.5
    _IsInGammaPipeline("IsInGammaPipeline", Float) = 1.0
    _Exposure ("Exposure", 2D) = "white" {}
}
SubShader {

CGINCLUDE
    #pragma vertex vert
    #pragma fragment frag
    #pragma target 2.0
    #pragma multi_compile __ UNITY_COLORSPACE_GAMMA
    #include "UnityCG.cginc"

    float _HandleSize;
    float _IsInGammaPipeline;
    sampler2D _Exposure;

    struct v2f {
        float4 pos : SV_POSITION;
        float3 color : COLOR0;
    };

    float3 Shade4DirLights (
        float4 toLightX, float4 toLightY, float4 toLightZ,
        float3 lightColor0, float3 lightColor1, float3 lightColor2, float3 lightColor3,
        float4 atten, float3 normal)
    {
        // squared lengths
        float4 lengthSq = 0;
        lengthSq += toLightX * toLightX;
        lengthSq += toLightY * toLightY;
        lengthSq += toLightZ * toLightZ;
        // NdotL
        float4 ndotl = 0;
        ndotl += toLightX * normal.x;
        ndotl += toLightY * normal.y;
        ndotl += toLightZ * normal.z;
        // correct NdotL
        float4 corr = rsqrt(lengthSq);
        ndotl = max (float4(0,0,0,0), ndotl * corr);
        // attenuation
        float4 diff = ndotl * atten;
        // final color
        float3 col = 0;
        col += lightColor0 * diff.x;
        col += lightColor1 * diff.y;
        col += lightColor2 * diff.z;
        col += lightColor3 * diff.w;
        return col;
    }

    v2f vert (appdata_base v)
    {
        v2f o;
        half4 pos = v.vertex;
        pos.xyz *= _HandleSize;
        o.pos = UnityObjectToClipPos(pos);

        // render SH
        // case 862215: We should instead rely on platform defines.
        // however at the moment this shader is compiled only once
        // at editor resources build time.
        // TODO remove workaround when "editor resources" will be built on-demands.
        half4 normal = half4(v.normal, 1);
        o.color = SHEvalLinearL0L1(normal) + SHEvalLinearL2(normal);
        o.color = (_IsInGammaPipeline > 0.0)?LinearToGammaSpace(o.color):o.color;

        // render occluded mixed lights on top of SH
        o.color += Shade4DirLights(
            unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
            unity_LightColor0.rgb, unity_LightColor1.rgb, unity_LightColor2.rgb, unity_LightColor3.rgb,
            unity_4LightAtten0,
            v.normal);

        float exposure = tex2Dlod(_Exposure, float4(0.5, 0.5, 0, 0)).r;
        o.color *= exposure;

        return o;
    }

ENDCG

    Tags { "ForceSupported" = "True" }
    Pass {

        CGPROGRAM
        half4 frag (v2f i) : COLOR
        {
            return half4 (i.color, 1);
        }
        ENDCG
    }

    // Same as the first pass, just with disabled z testing
    Pass {
        ZTest Always
        CGPROGRAM
#pragma target 2.0
        half4 frag (v2f i) : COLOR
        {
            return half4 (i.color, 1);
        }
        ENDCG
    }
}

}
