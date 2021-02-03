// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// A two-pass shader that first determines the overlap of the mesh with the scene geometry, and then
// renders just that overlap

Shader "Hidden/ShowOverlap"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _SrcBlend ("SrcBlend", Int) = 5.0 // SrcAlpha
        _DstBlend ("DstBlend", Int) = 10.0 // OneMinusSrcAlpha
        _ZWrite ("ZWrite", Int) = 1.0 // On
        _ZTest ("ZTest", Int) = 4.0 // LEqual
        _Cull ("Cull", Int) = 0.0 // Off
        _ZBias ("ZBias", Float) = 0.0
    }

    SubShader
    {
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }
        //Tags{ "RenderType" = "Opaque" "Queue" = "Geometry" }

        // Stencil pass
        Pass
        {
            Stencil {
                Ref 2
                Comp always
                Pass keep
                ZFail invert
            }
            ColorMask 0
            ZWrite Off
            ZTest[_ZTest]
            Cull Off
            Offset [_ZBias], [_ZBias]

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            struct appdata_t {
                float4 vertex : POSITION;
                float4 color : COLOR;
            };
            struct v2f {
                float4 vertex : SV_POSITION;
            };
            float4 _Color;
            v2f vert (appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                return 1;
            }
            ENDCG
        }

        // Geometry pass
        Pass
        {
            Stencil {
                Ref 2
                ReadMask 2
                Comp equal
                Pass zero
            }

            Blend [_SrcBlend] [_DstBlend]
            ZWrite Off
            ZTest Off
            Cull [_Cull]
            Offset [_ZBias], [_ZBias]

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            struct appdata_t {
                float4 vertex : POSITION;
                float4 color : COLOR;
            };
            struct v2f {
                fixed4 color : COLOR;
                float4 vertex : SV_POSITION;
            };
            float4 _Color;
            v2f vert (appdata_t v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.color = v.color * _Color;
                return o;
            }
            fixed4 frag (v2f i) : SV_Target
            {
                return i.color;
            }
            ENDCG
        }
    }
}
