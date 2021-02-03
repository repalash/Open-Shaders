// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/Preview AudioClip Waveform"
{
    Properties
    {
        _WavTex("Waveform Data Texture", 2D) = "green" {}
        _BacCol("Background Colour", Color) = (0, 0, 0, 1)
        _ForCol("Foreground Colour", Color) = (1, 1, 1, 1)
        _SampCount("Sample Count", Float) = 0
        _ChanCount("Channel Count", Float) = 0
        _RecPixelSize("Reciprocal Pixel Size", Float) = 0.001
        /* -2 = sum all channels to mono, -1 = draw all channels, 0 ... _ChanCount - 1 = draw a specific channel */
        _ChanDrawMode("Channel Drawing Mode", Int) = -2
    }

    SubShader
    {
        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float2 clipUV : TEXCOORD1;
                float4 vertex : SV_POSITION;
            };

            sampler2D _WavTex;
            float4 _WavTex_ST;
            float4 _WavTex_TexelSize;

            fixed4 _BacCol;
            fixed4 _ForCol;

            float _SampCount;

            float _BarWidth;
            float _ChanCount;
            float _RecPixelSize;
            int _ChanDrawMode;

            sampler2D _GUIClipTexture;
            uniform float4x4 unity_GUIClipTextureMatrix;

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _WavTex);
                float3 eyePos = UnityObjectToViewPos(v.vertex);
                o.clipUV = mul(unity_GUIClipTextureMatrix, float4(eyePos.xy, 0, 1.0));
                return o;
            }

            float jclamp(float minval, float maxval, float x)
            {
                return clamp((x - minval) / (maxval - minval), 0, 1.0);
            }

            fixed4 clerp(fixed4 a, fixed4 b, float x)
            {
                return a * x + b * (1 - x);
            }

            fixed4 lookupMinMax(int channel, float x, float sampleOffset)
            {
                // sample the texture at the correct offset
                float texX = (floor(x * (_SampCount - 1.0)) * _ChanCount + sampleOffset * _ChanCount);
                // invert channel selection, otherwise packing causes it to be inversed
                texX += (_ChanCount - 1) - channel;
                float texY = floor(texX / _WavTex_TexelSize.z) + 0.5;
                texX = fmod(texX, _WavTex_TexelSize.z) + 0.5;

                // The data currently should be packed min/max into a single texel
                return tex2D(_WavTex, float2(texX / _WavTex_TexelSize.z, texY / _WavTex_TexelSize.w));
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 mmCurrent;
                fixed4 mmNext;

                float channelCount = 1;
                int channel = 0;
                float channelIndex = 0;

                if (_ChanDrawMode == -2)
                {
                    // resample all available channels
                    mmCurrent = lookupMinMax(0, i.uv.x, 0);
                    mmNext = lookupMinMax(0, i.uv.x, 1);

                    //mmCurrent = lookupMinMax(1, i.uv.x, 0);
                    //mmNext = lookupMinMax(1, i.uv.x, 1);

                    for (int c = 1; c < 8; ++c)
                    {
                        if (c >= _ChanCount)
                            break;

                        fixed4 current = lookupMinMax(c, i.uv.x, 0);
                        fixed4 next = lookupMinMax(c, i.uv.x, 1);

                        mmCurrent.x = min(mmCurrent.x, current.x);
                        mmCurrent.y = max(mmCurrent.y, current.y);

                        mmNext.x = min(mmNext.x, next.x);
                        mmNext.y = max(mmNext.y, next.y);
                    }
                }
                else
                {
                    // default to a specific channel
                    channel = _ChanDrawMode;

                    if (channel == -1)
                    {
                        // override and select one based on height since we're painting all channels
                        // the height of the UV dictates the channel we are rendering
                        channelIndex = channel = round((_ChanCount - 1) * i.uv.y);
                        channelCount = _ChanCount;
                    }

                    mmCurrent = lookupMinMax(channel, i.uv.x, 0);
                    mmNext = lookupMinMax(channel, i.uv.x, 1);
                }




                // We map sample range to UV range here in the shader
                float sampleMin = -1.0;
                float sampleMax = 1.0;
                float uvMin = channelIndex / channelCount;
                float uvMax = (channelIndex + 1.0) / channelCount;

                float sampleRange = (sampleMax - sampleMin);
                float uvRange = (uvMax - uvMin);

                mmCurrent = ((mmCurrent - sampleMin) * uvRange) / sampleRange + uvMin;

                mmNext = ((mmNext - sampleMin) * uvRange) / sampleRange + uvMin;

                float pixelHeight = 0.5 * _RecPixelSize;

                // always draws a line even if there's no magnitude delta difference (meaning silence or straight DC offsets)
                mmCurrent.x -= pixelHeight;
                mmCurrent.y += pixelHeight;
                mmNext.x -= pixelHeight;
                mmNext.y += pixelHeight;

                float
                    a = min(mmCurrent.x, mmNext.x),
                    b = max(mmCurrent.x, mmNext.x),
                    c = min(mmCurrent.y, mmNext.y),
                    d = max(mmCurrent.y, mmNext.y);

                fixed4 col = clerp(_ForCol, _BacCol, jclamp(a, b, i.uv.y) * (1 - jclamp(c, d, i.uv.y)));
                col.a *= tex2D(_GUIClipTexture, i.clipUV).a;
                return col;
            }
            ENDCG
        }
    }
}
