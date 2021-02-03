// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Unlit/Preview3DSliced"
{
    Properties
    {
        _MainTex("Texture", 3D) = "white" {}
        _ColorRamp("Color Ramp", 2D) = "white" {}
        _VoxelSize("Voxel Size", Vector) = (1, 1, 1, 1)
        _InvScale("Inverse Scale", Vector) = (1, 1, 1, 1)
        _Positions("Positions", Vector) = (0, 0, 0, 0)
        _InvChannels("Inverse Channels", Vector) = (1, 1, 1, 1)
        _Ramp("Color Ramp", Float) = 0
        _FilterMode("FilterMode", Float) = 0
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

                float3 _Positions;
                float3 _InvChannels;
                float _Ramp;

                float _FilterMode;

                float DistanceToBox(float3 position)
                {
                    float3 q = abs(position) - 0.50001f * _VoxelSize;
                    return length(max(q,0)) + min(max(q.x, max(q.y,q.z)), 0);
                }

                float4 AdjustColor(float4 color, float3 pos)
                {
                    // clamp possibly HDR colors into displayable range
                    color = saturate(color);

                    // make each slice plane at least partially visible
                    color.a = max(color.a, 0.1);

                    float dist = DistanceToBox(pos);
                    if (dist > 0)
                    {
                        // Fully transparent outside the volume
                        color.a = 0;
                    }
                    else
                    {
                        // Small outline near edges of volume
                        float outline = (1-saturate(abs(dist)*100)) * 0.2;
                        color = lerp(color, float4(0,0,0,1), outline);
                    }
                    return color;
                }

                f2s raymarch(f2s fragOut, float3 position, float3 direction)
                {
                    float distance1 = RayDistToPlane(direction, position, float3(0, 0, -1), float3(0, 0, _Positions.z));
                    float distance2 = RayDistToPlane(direction, position, float3(1, 0, 0), float3(_Positions.x, 0, 0));
                    float distance3 = RayDistToPlane(direction, position, float3(0, 1, 0), float3(0, _Positions.y, 0));

                    float3 samplePos1 = (position + direction * distance1) * _InvScale;
                    float3 samplePos2 = (position + direction * distance2) * _InvScale;
                    float3 samplePos3 = (position + direction * distance3) * _InvScale;

                    float2 intersection1 = RayBoxIntersection(samplePos1, direction, 0.501);
                    float2 intersection2 = RayBoxIntersection(samplePos2, direction, 0.501);
                    float2 intersection3 = RayBoxIntersection(samplePos3, direction, 0.501);

                    if (intersection1.x < 0 && intersection1.y < 0 &&
                        intersection2.x < 0 && intersection2.y < 0 &&
                        intersection3.x < 0 && intersection3.y < 0)
                    {
                        discard;
                    }

                    float4 color1;
                    float4 color2;
                    float4 color3;

                    if (_FilterMode == 0)
                    {
                        color1 = _MainTex.Sample(custom_point_clamp_sampler, samplePos1 + float3(0.500001, 0.500001, 0.500001));
                        color2 = _MainTex.Sample(custom_point_clamp_sampler, samplePos2 + float3(0.500001, 0.500001, 0.500001));
                        color3 = _MainTex.Sample(custom_point_clamp_sampler, samplePos3 + float3(0.500001, 0.500001, 0.500001));
                    }
                    else if (_FilterMode == 1)
                    {
                        color1 = _MainTex.Sample(custom_linear_clamp_sampler, samplePos1 + float3(0.500001, 0.500001, 0.500001));
                        color2 = _MainTex.Sample(custom_linear_clamp_sampler, samplePos2 + float3(0.500001, 0.500001, 0.500001));
                        color3 = _MainTex.Sample(custom_linear_clamp_sampler, samplePos3 + float3(0.500001, 0.500001, 0.500001));
                    }
                    else if (_FilterMode == 2)
                    {
                        color1 = _MainTex.Sample(custom_trilinear_clamp_sampler, samplePos1 + float3(0.500001, 0.500001, 0.500001));
                        color2 = _MainTex.Sample(custom_trilinear_clamp_sampler, samplePos2 + float3(0.500001, 0.500001, 0.500001));
                        color3 = _MainTex.Sample(custom_trilinear_clamp_sampler, samplePos3 + float3(0.500001, 0.500001, 0.500001));
                    }
                    if (_IsNormalMap)
                    {
                        color1.rgb = 0.5f + 0.5f * UnpackNormal(color1);
                        color2.rgb = 0.5f + 0.5f * UnpackNormal(color2);
                        color3.rgb = 0.5f + 0.5f * UnpackNormal(color3);
                        color1.a = 1;
                        color2.a = 1;
                        color3.a = 1;
                    }

                    color1 = AdjustColor(color1, samplePos1 * _VoxelSize);
                    color2 = AdjustColor(color2, samplePos2 * _VoxelSize);
                    color3 = AdjustColor(color3, samplePos3 * _VoxelSize);

                    // sort colors by distance and blend
                    if (distance1 > distance2)
                    {
                        Swap(color1, color2);
                        Swap(distance1, distance2);
                    }
                    if (distance1 > distance3)
                    {
                        Swap(color1, color3);
                        Swap(distance1, distance3);
                    }
                    if (distance2 > distance3)
                    {
                        Swap(color2, color3);
                        Swap(distance2, distance3);
                    }

                    fragOut.color = BlendUnder(fragOut.color, color1);
                    fragOut.color = BlendUnder(fragOut.color, color2);
                    fragOut.color = BlendUnder(fragOut.color, color3);
                    fragOut.color.a = max(fragOut.color.a, 0.05);

                    if (_Ramp == 1)
                    {
                        fragOut.color = SampleColorRamp(saturate(dot(fragOut.color.rgb, _InvChannels)));
                    }

                    float4 clipPos1 = UnityObjectToClipPos(samplePos1);
                    float4 clipPos2 = UnityObjectToClipPos(samplePos2);
                    float4 clipPos3 = UnityObjectToClipPos(samplePos3);

                    float z1 = clipPos1.z / clipPos1.w;
                    float z2 = clipPos2.z / clipPos2.w;
                    float z3 = clipPos3.z / clipPos3.w;

                    fragOut.depth = max(max(z1, z2), z3);

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

                    float2 isect = RayBoxIntersection(rayOrigin, rayDirection, 0.5 * _VoxelSize);
                    if (isect.y < 0.0)
                        return fragOut;
                    isect.x = max(isect.x, 0.0);

                    return raymarch(fragOut, rayOrigin + rayDirection * isect.x, rayDirection);
                }
                ENDCG
            }
        }
}
