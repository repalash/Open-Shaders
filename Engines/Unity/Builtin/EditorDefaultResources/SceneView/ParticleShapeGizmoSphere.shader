// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/ParticleShapeGizmoSphere"
{
    Properties
    {
        _MainTex("Albedo", 2D) = "white" {}
        _Color("Tint", Color) = (1,1,1,1)
        [HideInInspector] _Cull("__cull", Float) = 2.0
        [HideInInspector] _Channel("__channel", Float) = 0.0
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

                struct v2f
                {
                    float4 vertex : SV_POSITION;
                    float3 normal : NORMAL;
                };

                v2f vert(appdata_base i)
                {
                    v2f o;
                    o.vertex = UnityObjectToClipPos(i.vertex);
                    o.normal = i.normal;
                    return o;
                }

                fixed4 frag(v2f i) : SV_Target
                {
                    float3 normal = normalize(i.normal);
                    float z = normal.z;

                    float u = 0.5f - (atan2(normal.y, normal.x) / UNITY_TWO_PI);
                    float v = z * 0.5f + 0.5f;

                    float4 c = tex2D(_MainTex, float2(u, v)) * _Color;

                    if (_ClipChannel <= 0.5f)
                        clip(c.r - _ClipThreshold);
                    else if (_ClipChannel <= 1.5f)
                        clip(c.g - _ClipThreshold);
                    else if (_ClipChannel <= 2.5f)
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
