// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/GraphView/GraphViewUIE"
{
    Properties
    {
        // Establish sensible default values
        [HideInInspector] _MainTex("Atlas", 2D) = "white" {}
        [HideInInspector] _FontTex("Font", 2D) = "black" {}
        [HideInInspector] _CustomTex("Custom", 2D) = "black" {}
        [HideInInspector] _Color("Tint", Color) = (1,1,1,1)
    }

    CGINCLUDE
    #include "EditorUIE.cginc"

    float _GraphViewScale;
    float _EditorPixelsPerPoint;

    v2f ProcessEdge(appdata_t v, inout float4 clipSpacePos)
    {
        UNITY_SETUP_INSTANCE_ID(v);
        uie_vert_load_payload(v);
        v.vertex.xyz = mul(uie_toWorldMat, v.vertex);
        v.uv.xy = mul(uie_toWorldMat, float3(v.uv.xy,0)).xy;

        static const float k_MinEdgeWidth = 1.75f;
        const float halfWidth = length(v.uv.xy);
        const float edgeWidth = halfWidth + halfWidth;
        const float realWidth = max(edgeWidth, k_MinEdgeWidth / _GraphViewScale);
        const float _ZoomCorrection = realWidth / edgeWidth;
        const float _ZoomFactor = _GraphViewScale * _ZoomCorrection * _EditorPixelsPerPoint;
        const float vertexHalfWidth = halfWidth + 1; // One more pixel is enough for our geometric AA
        const float sideSign = v.vertex.z;
        const float2 normal = v.uv.xy * vertexHalfWidth / halfWidth * sideSign; // Thickness direction relengthed to cover one more pixel to give custom AA space to work

        float2 vertex = v.vertex.xy + normal * _ZoomCorrection;

        v2f o;
        UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
        clipSpacePos = UnityObjectToClipPos(float3(vertex.xy, kUIEMeshZ));
        o.clipPos.xy = clipSpacePos.xy / clipSpacePos.w;
        o.uvXY.xy = float2(vertexHalfWidth*sideSign, halfWidth);
        o.uvXY.zw = vertex.xy;
        o.flags.x = 2.0f; // Marking as an edge
        o.flags.y = _ZoomFactor;
        o.flags.zw = (fixed2)0;
        o.svgFlags = (fixed3)0;

        o.clipRectOpacityUVs = uie_std_vert_shader_info(v, o.color);
#if UIE_SHADER_INFO_IN_VS
        o.clipRect = tex2Dlod(_ShaderInfoTex, float4(o.clipRectOpacityUVs.xy, 0, 0)),
#endif // UIE_SHADER_INFO_IN_VS

        o.color.a *= edgeWidth / realWidth; // make up for bigger edge by fading it.
        return o;
    }

    v2f vert(appdata_t v, out float4 clipSpacePos : SV_POSITION)
    {
        if (v.idsFlags.w*255.0f == kUIEVertexLastFlagValue)
            return ProcessEdge(v, clipSpacePos);
        return uie_std_vert(v, clipSpacePos);
    }

    fixed4 frag(v2f IN) : SV_Target
    {
        uie_fragment_clip(IN);
        if (IN.flags.x == 2.0f) // Is it an edge?
        {
            float distanceSat = saturate((IN.uvXY.y - abs(IN.uvXY.x)) * IN.flags.y + 0.5);
            return fixed4(IN.color.rgb, IN.color.a * distanceSat);
        }

        return uie_editor_frag(IN);
    }
    ENDCG

    Category
    {
        Lighting Off
        Blend SrcAlpha OneMinusSrcAlpha

        // Users pass depth between [Near,Far] = [-1,1]. This gets stored on the depth buffer in [Near,Far] [0,1] regardless of the underlying graphics API.
        Cull Off    // Two sided rendering is crucial for immediate clipping
        ZWrite Off
        Stencil
        {
            Ref         255 // 255 for ease of visualization in RenderDoc, but can be just one bit
            ReadMask    255
            WriteMask   255

            CompFront Always
            PassFront Keep
            ZFailFront Replace
            FailFront Keep

            CompBack Equal
            PassBack Keep
            ZFailBack Zero
            FailBack Keep
        }

        Tags
        {
            "Queue" = "Transparent"
            "IgnoreProjector" = "True"
            "RenderType" = "Transparent"
            "PreviewType" = "Plane"
        }

        // SM3.5 version
        SubShader
        {
            Tags { "UIE_VertexTexturingIsAvailable" = "1" }
            Pass
            {
                CGPROGRAM
                #pragma target 3.5
                #pragma vertex vert
                #pragma fragment frag
                #pragma require samplelod
                ENDCG
            }
        }

        // SM2.0 version
        SubShader
        {
            Pass
            {
                CGPROGRAM
                #pragma target 2.0
                #pragma vertex vert
                #pragma fragment frag
                ENDCG
            }
        }
    } // Category
}
