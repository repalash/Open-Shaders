// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Mesh-MultiPreview"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _UVChannel ("UV Channel", Int) = 0

        // this goes up to 4
        // 0 - flat UVs
        // 1 - vertex color
        // 2 - normals as color
        // 3 - tangents as color
        // 4 - checkerboard UVs
        _Mode ("Draw mode", Int) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vertShader
            #pragma fragment fragShader

            #include "UnityCG.cginc"

            float _WireThickness;
            int _UVChannel;
            int _Mode;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv0 : TEXCOORD0;
                float2 uv1 : TEXCOORD1;
                float2 uv2 : TEXCOORD2;
                float2 uv3 : TEXCOORD3;
                float2 uv4 : TEXCOORD4;
                float2 uv5 : TEXCOORD5;
                float2 uv6 : TEXCOORD6;
                float2 uv7 : TEXCOORD7;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                fixed4 color : COLOR;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                fixed4 color : COLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;

            float2 GetUV(appdata v)
            {
                if(_UVChannel == 0)
                    return v.uv0.xy;
                if(_UVChannel == 1)
                    return v.uv1.xy;
                if(_UVChannel == 2)
                    return v.uv2.xy;
                if(_UVChannel == 3)
                    return v.uv3.xy;
                if(_UVChannel == 4)
                    return v.uv4.xy;
                if(_UVChannel == 5)
                    return v.uv5.xy;
                if(_UVChannel == 6)
                    return v.uv6.xy;
                if(_UVChannel == 7)
                    return v.uv7.xy;
                return v.uv0.xy;
            }

            v2f vertShader (appdata v)
            {
                v2f o;

                if(_Mode == 0)
                {
                    o.uv = GetUV(v);
                    o.vertex = UnityObjectToClipPos(float4(o.uv.x, o.uv.y, 0, 1));
                    o.color = fixed4(1.0, 0.9, 0.6, 1.0);
                }

                if(_Mode > 0)
                {
                    o.vertex = UnityObjectToClipPos(v.vertex);
                }

                if(_Mode == 1)
                {
                    o.color = v.color;
                }

                if(_Mode == 2)
                {
                    o.color = float4(normalize(v.normal.xyz) * 0.5 + 0.5, 1);
                }

                if(_Mode == 3)
                {
                    o.color = float4(normalize(v.tangent.xyz) * 0.5 + 0.5, 1);
                }

                if(_Mode == 4)
                {
                    o.uv = TRANSFORM_TEX(GetUV(v), _MainTex);
                    // a little bit of shading based on object space normal
                    half3 skyColor = half3(0.212, 0.227, 0.259)*4;
                    half3 groundColor = half3(0.047, 0.043, 0.035)*4;
                    float a = v.normal.y * 0.5 + 0.5;
                    o.color.rgb = lerp(groundColor, skyColor, a);
                    o.color.a = 1;
                }

                return o;
            }

            fixed4 fragShader (v2f i) : SV_Target
            {
                if(_Mode == 4)
                {
                    half4 checker = tex2D(_MainTex, i.uv);
                    i.color *= checker;
                }
                return i.color;
            }
            ENDCG
        }
    }
}
