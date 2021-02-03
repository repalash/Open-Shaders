// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Unlit/Preview3DSDF"
{
    Properties
    {
        _MainTex("Texture", 3D) = "white" {}
        _ColorRamp("Color Ramp", 2D) = "white" {}
        _VoxelSize("Voxel Size", Vector) = (1, 1, 1, 1)
        _InvScale("Inverse Scale", Vector) = (1, 1, 1, 1)
        _GlobalScale("Global Scale", Vector) = (1, 1, 1, 1)
        _InvResolution("Inverse Resolution", Float) = 1
        _Scale("Scale", Float) = 1
        _Offset("Offset", Float) = 0
        _IsNormalMap ("", Int) = 0
    }

    SubShader
    {
        Tags { "Queue" = "Transparent" "RenderType" = "Transparent" }
        Blend SrcAlpha OneMinusSrcAlpha
        LOD 100

        Pass
        {
            Cull Front

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Preview3DBase.cginc"

            float4 _GlobalScale;
            float _InvResolution;
            float _Scale;
            float _Offset;

            float sampleSurface(float3 pos)
            {
                return (_MainTex.Sample(sampler_MainTex, pos).x + _Offset * _InvResolution) * _Scale * _InvResolution;
            }

            f2s raymarch(f2s fragOut, float3 origin, float3 direction, float2 minmaxt, float minSurfaceDist)
            {
                float t = minmaxt.x;
                UNITY_LOOP for (int it = 0; it < 2048 && t < minmaxt.y; it++)
                {
                    float3 position = origin + direction * t;
                    float3 scaledPosition = position * _InvScale;
                    float sampleDistance = sampleSurface(scaledPosition + float3(0.5, 0.5, 0.5));
                    t += sampleDistance;

                    if (sampleDistance < minSurfaceDist)
                    {
                        float3 deltaShift = 2 * _InvScale * _InvResolution;

                        float3 delta = float3(sampleSurface(scaledPosition + float3(0.5 + deltaShift.x, 0.5, 0.5)),
                            sampleSurface(scaledPosition + float3(0.5, 0.5 + deltaShift.y, 0.5)),
                            sampleSurface(scaledPosition + float3(0.5, 0.5, 0.5 + deltaShift.z))) - sampleDistance;

                        float3 normal = normalize(float3(delta.x / deltaShift.x, delta.y / deltaShift.y, delta.z / deltaShift.z));

                        float3 eyeNormal = normalize(mul((float3x3)UNITY_MATRIX_IT_MV, normal).xyz);

                        float3 farPoint = -direction * length(_GlobalScale) / 2;
                        float3 nearPoint = -farPoint;
                        float ratio = length(position - nearPoint) / length(farPoint - nearPoint);
                        fragOut.color.rgb = SampleColorRamp(1 - ratio);

                        float rim = clamp(pow(1 - abs(eyeNormal.z), 3), 0, 1);
                        fragOut.color.rgb = lerp(fragOut.color.rgb, float3(0.1, 0.1, 0.1), rim);

                        float4 clipPos = UnityObjectToClipPos(origin + direction * max(t, 0.1f));
                        fragOut.depth = clipPos.z / clipPos.w;
                        fragOut.color.a = 1;
                        break;
                    }
                }

                return fragOut;
            }

            f2s frag(v2f i)
            {
                f2s fragOut;
                fragOut.color = float4(0, 0, 0, 0);
                fragOut.depth = 0;

                float3 rayOrigin = _WorldSpaceCameraPos;
                float3 rayDirection = normalize(i.samplePos.xyz - rayOrigin);

                rayOrigin = mul(unity_WorldToObject, float4(rayOrigin, 1)).xyz;
                rayDirection = mul(unity_WorldToObject, float4(rayDirection, 0)).xyz;

                float minSurfaceDist = pow(_InvResolution, 2);

                float2 isect = RayBoxIntersection(rayOrigin, rayDirection, 0.5 * _VoxelSize);
                if (isect.y < 0.0)
                {
                    fragOut.color = 1 - fragOut.color;
                }
                else
                {
                    isect.x = max(isect.x, 0.0);
                    fragOut = raymarch(fragOut, rayOrigin, rayDirection, isect, minSurfaceDist);
                }

                return fragOut;
            }
            ENDCG
        }
    }
}
