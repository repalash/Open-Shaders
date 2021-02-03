// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

#include "UnityCG.cginc"

Texture3D _MainTex;
SamplerState sampler_MainTex;
float4 _MainTex_ST;

// Should be kept in sync with UnityEngine.FilterMode enum.
SamplerState custom_point_clamp_sampler;
SamplerState custom_linear_clamp_sampler;
SamplerState custom_trilinear_clamp_sampler;

sampler2D _ColorRamp;

float3 _VoxelSize;
float4 _InvScale;
int _IsNormalMap;


struct appdata
{
    float4 vertex : POSITION;
};

struct v2f
{
    float4 vertex : SV_POSITION;
    float3 samplePos : TEXCOORD1;
    float alphaMul : TEXCOORD2;
};

struct f2s
{
    float4 color : SV_Target;
    float depth : SV_Depth;
};

v2f vert(appdata v)
{
    v2f o;
    v.vertex.xyz *= _VoxelSize;
    o.vertex = UnityObjectToClipPos(v.vertex);
    o.samplePos = mul(unity_ObjectToWorld, v.vertex).xyz;
    return o;
}

float RayDistToPlane(float3 rayDirection, float3 rayOrigin, float3 planeNormal, float3 planePoint)
{
    float3 prod1 = dot(rayOrigin - planePoint, planeNormal);
    float3 prod2 = dot(rayDirection, planeNormal);
    float3 result = -prod1 / prod2;
    return result > -0.00001f ? result : 100000;
}

// Ray origin is "ro", ray direction is "rd"
// Returns "t" along the ray of min,max intersection, or (-1,-1) if no intersections are found.
// https://iquilezles.org/www/articles/intersectors/intersectors.htm
float2 RayBoxIntersection(float3 ro, float3 rd, float3 boxSize)
{
    float3 m = 1.0/rd;
    float3 n = m*ro;
    float3 k = abs(m)*boxSize;
    float3 t1 = -n - k;
    float3 t2 = -n + k;
    float tN = max(max(t1.x, t1.y), t1.z);
    float tF = min(min(t2.x, t2.y), t2.z);
    if (tN > tF || tF < 0.0) return -1; // no intersection
    return float2(tN, tF);
}

float Noise(float2 uv)
{
    return frac(sin(uv.x * uv.y * 71.31339) * 43758.5453);
}

// https://www.shadertoy.com/view/4lXyWN
float3 Noisy3D(uint3 x)
{
    uint k = 1103515245U;
    x *= k;
    x = ((x >> 2u) ^ (x.yzx >> 1u) ^ x.zxy)* k;

    return float3(x) * (1.0 / float(0xffffffffU));
}

float4 BlendUnder(float4 color, float4 newColor)
{
    color.rgb += (1.0 - color.a) * newColor.a * newColor.rgb;
    color.a += (1.0 - color.a) * newColor.a;
    return color;
}

void Swap(inout float4 a, inout float4 b)
{
    float4 t = a;
    a = b;
    b = t;
}
void Swap(inout float a, inout float b)
{
    float t = a;
    a = b;
    b = t;
}

float4 SampleColorRamp(float time)
{
    return tex2D(_ColorRamp, float2(time, 0));
}
