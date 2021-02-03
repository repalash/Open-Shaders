// Copyright Epic Games, Inc. All Rights Reserved.

#include "GammaCorrectionCommon.hlsl"

// Shader types
#define ESlateShader::Default		0
#define ESlateShader::Border		1
#define ESlateShader::GrayscaleFont	2
#define ESlateShader::ColorFont		3
#define ESlateShader::LineSegment	4

Texture2D ElementTexture;
SamplerState ElementTextureSampler;

cbuffer PerFramePSConstants
{
	/** Display gamma x:gamma curve adjustment, y:inverse gamma (1/GEngine->DisplayGamma) */
	float2 GammaValues;
};

cbuffer PerElementPSConstants
{
    uint ShaderType;            //  4 bytes
    float4 ShaderParams;        // 16 bytes
    uint IgnoreTextureAlpha;    //	4 byte
    uint DisableEffect;         //  4 byte
    uint UNUSED[1];             //  4 bytes
};

struct VertexOut
{
	float4 Position : SV_POSITION;
	float4 Color : COLOR0;
	float4 TextureCoordinates : TEXCOORD0;
};

float3 Hue( float H )
{
	float R = abs(H * 6 - 3) - 1;
	float G = 2 - abs(H * 6 - 2);
	float B = 2 - abs(H * 6 - 4);
	return saturate( float3(R,G,B) );
}

float3 GammaCorrect(float3 InColor)
{
	float3 CorrectedColor = InColor;

	if ( GammaValues.y != 1.0f )
	{
		CorrectedColor = ApplyGammaCorrection(CorrectedColor, GammaValues.x);
	}

	return CorrectedColor;
}

float4 GetGrayscaleFontElementColor( VertexOut InVertex )
{
	float4 OutColor = InVertex.Color;

	OutColor.a *= ElementTexture.Sample(ElementTextureSampler, InVertex.TextureCoordinates.xy).a;
	
	return OutColor;
}

float4 GetColorFontElementColor(VertexOut InVertex)
{
	float4 OutColor = InVertex.Color;

	OutColor *= ElementTexture.Sample(ElementTextureSampler, InVertex.TextureCoordinates.xy);

	return OutColor;
}

float4 GetColor( VertexOut InVertex, float2 UV )
{
	float4 FinalColor;
	
	float4 BaseColor = ElementTexture.Sample(ElementTextureSampler, UV );
	if( IgnoreTextureAlpha != 0 )
	{
		BaseColor.a = 1.0f;
	}

	FinalColor = BaseColor*InVertex.Color;
	return FinalColor;
}

float4 GetDefaultElementColor( VertexOut InVertex )
{
	return GetColor( InVertex, InVertex.TextureCoordinates.xy*InVertex.TextureCoordinates.zw );
}

float4 GetBorderElementColor( VertexOut InVertex )
{
	float2 NewUV;
	if( InVertex.TextureCoordinates.z == 0.0f && InVertex.TextureCoordinates.w == 0.0f )
	{
		NewUV = InVertex.TextureCoordinates.xy;
	}
	else
	{
		float2 MinUV;
		float2 MaxUV;
	
		if( InVertex.TextureCoordinates.z > 0 )
		{
			MinUV = float2(ShaderParams.x,0);
			MaxUV = float2(ShaderParams.y,1);
			InVertex.TextureCoordinates.w = 1.0f;
		}
		else
		{
			MinUV = float2(0,ShaderParams.z);
			MaxUV = float2(1,ShaderParams.w);
			InVertex.TextureCoordinates.z = 1.0f;
		}

		NewUV = InVertex.TextureCoordinates.xy*InVertex.TextureCoordinates.zw;
		NewUV = frac(NewUV);
		NewUV = lerp(MinUV,MaxUV,NewUV);	
	}

	return GetColor( InVertex, NewUV );
}

float4 GetSplineElementColor( VertexOut InVertex )
{
	const float LineWidth = ShaderParams.x;
	const float FilterWidthScale = ShaderParams.y;

	const float Gradient = InVertex.TextureCoordinates.x;
	const float2 GradientDerivative = float2( abs(ddx(Gradient)), abs(ddy(Gradient)) );
	const float PixelSizeInUV = sqrt(dot(GradientDerivative, GradientDerivative));
	
	const float HalfLineWidthUV = 0.5f * PixelSizeInUV * LineWidth;	
	const float HalfFilterWidthUV = FilterWidthScale * PixelSizeInUV;
	const float DistanceToLineCenter = abs(0.5f - Gradient);
	const float LineCoverage = smoothstep(HalfLineWidthUV + HalfFilterWidthUV, HalfLineWidthUV-HalfFilterWidthUV, DistanceToLineCenter);

	if (LineCoverage <= 0.0f)
	{
		discard;
	}

	float4 Color = InVertex.Color;
	Color.a *= LineCoverage;
	return Color;
}

float4 Main( VertexOut InVertex ) : SV_Target
{
	float4 OutColor;

	if( ShaderType == ESlateShader::Default )
	{
		OutColor = GetDefaultElementColor( InVertex );
	}
	else if( ShaderType == ESlateShader::Border )
	{
		OutColor = GetBorderElementColor( InVertex );
	}
	else if( ShaderType == ESlateShader::GrayscaleFont )
	{
		OutColor = GetGrayscaleFontElementColor( InVertex );
	}
	else if (ShaderType == ESlateShader::ColorFont)
	{
		OutColor = GetColorFontElementColor(InVertex);
	}
	else
	{
		OutColor = GetSplineElementColor( InVertex );
	}

	// gamma correct
	OutColor.rgb = GammaCorrect(OutColor.rgb);

    if (DisableEffect)
	{
		//desaturate
		float3 LumCoeffs = float3( 0.3, 0.59, .11 );
		float Lum = dot( LumCoeffs, OutColor.rgb );
		OutColor.rgb = lerp( OutColor.rgb, float3(Lum,Lum,Lum), .8 );
	
		float3 Grayish = {.4, .4, .4};
		
		// lerp between desaturated color and gray color based on distance from the desaturated color to the gray
		OutColor.rgb = lerp( OutColor.rgb, Grayish, clamp( distance( OutColor.rgb, Grayish ), 0, .8)  );
	}

	return OutColor;
}

