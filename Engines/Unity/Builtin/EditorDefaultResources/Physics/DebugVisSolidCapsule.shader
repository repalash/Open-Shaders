// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Physics/DebugVisSolidCapsule" {

    Properties {
        _Color ("col (RGB)", Color) = (1,0,0,0)
        _radius ("radius", Range (0.005, 10.08)) = 0.5
        _halfHeight ("halfheight", Range (0.005, 10.08)) = 0.5
    }

    SubShader {
        Pass {
            Tags { "RenderType" = "Transparent" "Queue" = "Transparent" }
            Lighting Off
            Blend SrcAlpha OneMinusSrcAlpha
            ZTest LEqual ZWrite On
            Offset -0.2, -1

            CGPROGRAM
            #pragma vertex vert_surf
            #pragma fragment frag_surf
            #include "UnityCG.cginc"

            float4 _Color;
            float _radius;
            float _halfHeight;

            struct a2v_vert
            {
                float4 vertex       : POSITION;
            };

            struct v2f_surf
            {
                float4 pos      : SV_POSITION;
            };

            v2f_surf vert_surf (a2v_vert v)
            {
                v2f_surf o;

                // manually scale capsule height and radius
                float sign = (v.vertex.y >= 0.f) ? 1.f : -1.f;
                v.vertex.y += -sign * 0.5f; // Move to be a sphere. (0.5f: New-Capsule height)
                v.vertex.xyz = v.vertex.xyz * 2.f * _radius; // Scale sphere. (2.f to expand the New-Capsule radius from 0.5 to 1)
                v.vertex.y += sign * _halfHeight; // add height

                o.pos = UnityObjectToClipPos(v.vertex);

                return o;
            }

            float4 frag_surf (v2f_surf IN) : COLOR
            {
                return _Color;
            }
            ENDCG
        }
    }
}
