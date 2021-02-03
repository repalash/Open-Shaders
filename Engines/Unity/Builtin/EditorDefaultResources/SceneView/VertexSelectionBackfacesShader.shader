// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/VertexSelectionBackfaces" {
   Properties {
       _MainTex ("Texture", 2D) = "white"{}
       _Color ("Color", Color) = (0,1,1,1)
   }
   SubShader {
       Tags { "ForceSupported" = "True" }
       Pass {
           ZTest Always
CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 2.0
            #pragma exclude_renderers gles
            #include "UnityCG.cginc"
            fixed4 _Color;
            struct appdata {
                float4 vertex : POSITION;
                float4 tangent : TANGENT;
                float3 normal : NORMAL;
                fixed4 color : COLOR0;
            };
            struct v2f {
                float4 pos : SV_POSITION;
                fixed4 color : COLOR0;
            };
            v2f vert (appdata v)
            {
                v2f o;
                float3 center = UnityObjectToViewPos(v.vertex);
                v.tangent *= center.z;
                o.pos = UnityObjectToClipPos(v.vertex + v.tangent);
                o.color = 0.75 * v.color * _Color + 0.25 * dot(v.normal, float3(0.7, 0.3, 0.64));
                o.color.a = v.color.a * _Color.a;
                return o;
            }
            fixed4 frag(v2f i) : COLOR
            {
                return half4(i.color);
            }
ENDCG
       }
   }
}
