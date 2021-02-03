// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/ParticleShapeGizmo"
{
    Properties
    {
        _MainTex("Albedo", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)
        [HideInInspector] _Cull("__cull", Float) = 2.0
    }

    Category
    {
        SubShader
        {
            Tags { "Queue" = "Transparent" "RenderType" = "Transparent" "ForceSupported" = "True" }

            Cull [_Cull]
            Lighting Off
            ZWrite Off
            Blend One OneMinusSrcAlpha

            Pass
            {
                CGPROGRAM
                #pragma vertex vert
                #pragma fragment frag
                #pragma target 2.0

                #include "UnityCG.cginc"

                sampler2D _MainTex;
                fixed4 _Color;
                float _ClipChannel;
                float _ClipThreshold;
                float _UVChannel;

                struct v2f
                {
                    float4 vertex : SV_POSITION;
                    float2 uv : TEXCOORD0;
                };

                v2f vert(appdata_full i)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(i.vertex);

                    if (_UVChannel <= 0.5f)
                        o.uv = i.texcoord;
                    else if (_UVChannel <= 1.5f)
                        o.uv = i.texcoord1;
                    else if (_UVChannel <= 2.5f)
                        o.uv = i.texcoord2;
                    else
                        o.uv = i.texcoord3;

                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    float4 c = tex2D(_MainTex, i.uv) * _Color;

                    if (_ClipChannel <= 0.5f)
                        clip(c.r - _ClipThreshold);
                    else if(_ClipChannel <= 1.5f)
                        clip(c.g - _ClipThreshold);
                    else if(_ClipChannel <= 2.5f)
                        clip(c.b - _ClipThreshold);
                    else
                        clip(c.a - _ClipThreshold);

                    c.rgb *= c.a;
                    return c;
                }

                ENDCG
            }
        }
    }
}
