// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Unlit/Preview3DVolume"
{
    Properties
    {
        _MainTex ("Texture", 3D) = "white" {}
        _ColorRamp("Color Ramp", 2D) = "white" {}
        _VoxelSize("Voxel Size", Vector) = (1, 1, 1, 1)
        _GlobalScale("Global Scale", Vector) = (1, 1, 1, 1)
        _InvScale("Inverse Scale", Vector) = (1, 1, 1, 1)
        _InvChannels("Inverse Channels", Vector) = (1, 1, 1, 1)
        _InvResolution("Inverse Resolution", Float) = 32
        _Alpha("Alpha Multiplier", Float) = 1
        _Ramp("Color Ramp", Float) = 0
        _FilterMode("Filter Mode", Float) = 0
        _Position("Position", Float) = 0
        _Quality("Quality", Float) = 32
        _IsNormalMap ("", Int) = 0
    }
    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend One OneMinusSrcAlpha
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vertMain
            #pragma fragment fragMain
            #pragma target 3.5

            #include "Preview3DBase.cginc"

            float4 _GlobalScale;
            float3 _InvChannels;
            float _Quality;
            float _InvResolution;
            float _Alpha;
            float _Ramp;
            float _FilterMode;

            // Some rendering methods like using `GL` API doesn't set view matrixes
            // therefore we must set those matrixes manually
            float4x4 _CamToW;
            float4x4 _WToCam;
            float4x4 _ObjToW;
            float4x4 _WToObj;

            v2f vertMain(appdata v, uint vertexID : SV_VertexID, uint instanceID : SV_InstanceID)
            {
                v2f o;
                if (vertexID == 0)
                {
                    v.vertex = float4(-1, -1, 0, 1);
                }
                else if (vertexID == 1)
                {
                    v.vertex = float4(-1, 1, 0, 1);
                }
                else if (vertexID == 2)
                {
                    v.vertex = float4(1, 1, 0, 1);
                }
                else if (vertexID == 3)
                {
                    v.vertex = float4(1, -1, 0, 1);
                }

                v.vertex.z = ((instanceID * _Quality) * 2 - 1);
                v.vertex.xyz *= length(_VoxelSize) * length(_GlobalScale.xyz) / 3;

                v.vertex.xyz = mul((float3x3)_CamToW, v.vertex.xyz);

                float3 objectWorldPos = float3(_ObjToW._m03, _ObjToW._m13, _ObjToW._m23);
                v.vertex.xyz += objectWorldPos;

                o.samplePos = mul(_WToObj, v.vertex).xyz;
                o.vertex = mul(UNITY_MATRIX_P, mul(_WToCam, v.vertex));

                // Cache opacity multiplier with view direction for later use in pixel shader
                o.alphaMul = saturate(_Alpha * 4 * (_Quality / _InvResolution));

                return o;
            }

            half4 fragMain(v2f i) : SV_Target
            {
                i.samplePos += (Noisy3D(uint3(i.vertex.xy, i.vertex.w * 2579)) - float3(0.5, 0.5, 0.5)) * _Quality;

                if (any(i.samplePos < -_VoxelSize / 2))
                    discard;
                if (any(i.samplePos > _VoxelSize / 2))
                    discard;

                float3 uv = i.samplePos * _InvScale + 0.5;

                float4 color = 0;
                if (_FilterMode == 0)
                {
                    color = _MainTex.Sample(custom_point_clamp_sampler, uv);
                }
                else if (_FilterMode == 1)
                {
                    color = _MainTex.Sample(custom_linear_clamp_sampler, uv);
                }
                else if (_FilterMode == 2)
                {
                    color = _MainTex.Sample(custom_trilinear_clamp_sampler, uv);
                }
                if (_IsNormalMap)
                {
                    color.rgb = 0.5f + 0.5f * UnpackNormal(color);
                    color.a = 1;
                }

                color.a *= i.alphaMul;

                if (_Ramp == 1)
                {
                    float prevAlpha = color.a;
                    color = SampleColorRamp(dot(color.rgb, _InvChannels));
                    color.a *= prevAlpha;
                }

                color.rgb *= color.a;

                return color;
            }
            ENDCG
        }
    }
}
