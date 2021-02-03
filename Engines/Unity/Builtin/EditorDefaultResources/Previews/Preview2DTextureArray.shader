// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Preview 2D Texture Array"
{
    Properties
    {
        _MainTex ("Texture", 2DArray) = "" {}
        _SliceIndex ("Slice", Int) = 0
        _Mip ("Mip level", Int) = 0
        _ToSRGB ("", Int) = 0
        _IsNormalMap ("", Int) = 0
        _Exposure("Exposure", Float) = 0.0
    }
    Subshader {
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma target 3.5
            #include "UnityCG.cginc"
            struct v2f {
                float4 vertex : SV_POSITION;
                float3 uv : TEXCOORD0;
            };
            int _SliceIndex;
            int _Mip;
            int _ColorMaskBits; //Keep the name different from _ColorMask as EditorGUI.DrawPreviewTexture will otherwise set it to a value that might not match the logic in this file
            int _IsNormalMap;
            float _Exposure;

            v2f vert (float4 v : POSITION, float2 t : TEXCOORD0)
            {
                v2f o;
                o.uv = float3(t, _SliceIndex);
                o.vertex = UnityObjectToClipPos(v);
                return o;
            }
            int _ToSRGB;
            UNITY_DECLARE_TEX2DARRAY(_MainTex);
            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = UNITY_SAMPLE_TEX2DARRAY_LOD(_MainTex, i.uv, _Mip);
                if (_IsNormalMap)
                {
                    col.rgb = 0.5f + 0.5f * UnpackNormal(col);
                    col.a = 1;
                }

                col.rgb *= exp2(_Exposure);

                if (_ToSRGB)
                    col.rgb = LinearToGammaSpace(col.rgb);

                if (_ColorMaskBits == 1) { col.gb = 0; col.a = 1; }
                if (_ColorMaskBits == 2) { col.rb = 0; col.a = 1; }
                if (_ColorMaskBits == 4) { col.rg = 0; col.a = 1; }
                if (_ColorMaskBits == 8) { col.rgb = col.a; col.a = 1; }
                return col;
            }
            ENDCG
        }
    }
}
