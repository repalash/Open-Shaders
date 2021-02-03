// Copyright Epic Games, Inc. All Rights Reserved.

// handle differences between ES and full GL shaders
#if PLATFORM_USES_GLES
precision highp float;
#else
// #version 120 at the beginning is added in FSlateOpenGLShader::CompileShader()
#extension GL_EXT_gpu_shader4 : enable
#endif

#ifndef USE_709
#define USE_709 0
#endif // USE_709

// Shader types
#define ST_Default			0
#define ST_Border			1
#define ST_GrayscaleFont	2
#define ST_ColorFont		3
#define ST_Line				4

/** Display gamma x:gamma curve adjustment, y:inverse gamma (1/GEngine->DisplayGamma) */
uniform vec2 GammaValues = vec2(1, 1/2.2);

// Draw effects
uniform bool EffectsDisabled;
uniform bool IgnoreTextureAlpha;

uniform vec4 MarginUVs;
uniform int ShaderType;
uniform sampler2D ElementTexture;

varying vec4 Position;
varying vec4 TexCoords;
varying vec4 Color;

vec3 maxWithScalar(float test, vec3 values)
{
	return vec3(max(test, values.x), max(test, values.y), max(test, values.z));
}

vec3 powScalar(vec3 values, float power)
{
	return vec3(pow(values.x, power), pow(values.y, power), pow(values.z, power));
}

vec3 LinearTo709Branchless(vec3 lin)
{
	lin = maxWithScalar(6.10352e-5, lin); // minimum positive non-denormal (fixes black problem on DX11 AMD and NV)
	return min(lin * 4.5, powScalar(maxWithScalar(0.018, lin), 0.45) * 1.099 - 0.099);
}

vec3 LinearToSrgbBranchless(vec3 lin)
{
	lin = maxWithScalar(6.10352e-5, lin); // minimum positive non-denormal (fixes black problem on DX11 AMD and NV)
	return min(lin * 12.92, powScalar(maxWithScalar(0.00313067, lin), 1.0/2.4) * 1.055 - 0.055);
	// Possible that mobile GPUs might have native pow() function?
	//return min(lin * 12.92, exp2(log2(max(lin, 0.00313067)) * (1.0/2.4) + log2(1.055)) - 0.055);
}

float LinearToSrgbBranchingChannel(float lin)
{
	if(lin < 0.00313067) return lin * 12.92;
	return pow(lin, (1.0/2.4)) * 1.055 - 0.055;
}

vec3 LinearToSrgbBranching(vec3 lin)
{
	return vec3(
				LinearToSrgbBranchingChannel(lin.r),
				LinearToSrgbBranchingChannel(lin.g),
				LinearToSrgbBranchingChannel(lin.b));
}

float sRGBToLinearChannel( float ColorChannel )
{
	return ColorChannel > 0.04045 ? pow( ColorChannel * (1.0 / 1.055) + 0.0521327, 2.4 ) : ColorChannel * (1.0 / 12.92);
}

vec3 sRGBToLinear( vec3 Color )
{
	return vec3(sRGBToLinearChannel(Color.r),
				sRGBToLinearChannel(Color.g),
				sRGBToLinearChannel(Color.b));
}

/**
 * @param GammaCurveRatio The curve ratio compared to a 2.2 standard gamma, e.g. 2.2 / DisplayGamma.  So normally the value is 1.
 */
vec3 ApplyGammaCorrection(vec3 LinearColor, float GammaCurveRatio)
{
	// Apply "gamma" curve adjustment.
	vec3 CorrectedColor = powScalar(LinearColor, GammaCurveRatio);

#if PLATFORM_MAC
	// Note, MacOSX native output is raw gamma 2.2 not sRGB!
	//CorrectedColor = pow(CorrectedColor, 1.0/2.2);
	CorrectedColor = LinearToSrgbBranching(CorrectedColor);
#else
#if USE_709
	// Didn't profile yet if the branching version would be faster (different linear segment).
	CorrectedColor = LinearTo709Branchless(CorrectedColor);
#else
	CorrectedColor = LinearToSrgbBranching(CorrectedColor);
#endif
	
#endif
	
	return CorrectedColor;
}

vec3 GammaCorrect(vec3 InColor)
{
	vec3 CorrectedColor = InColor;
	
	// gamma correct
	//#if PLATFORM_USES_GLES
	//	OutColor.rgb = sqrt( OutColor.rgb );
	//#else
	//	OutColor.rgb = pow(OutColor.rgb, vec3(1.0/2.2));
	//#endif
	
#if !PLATFORM_USES_GLES
	if( GammaValues.y != 1.0f )
	{
		CorrectedColor = ApplyGammaCorrection(CorrectedColor, GammaValues.x);
	}
#endif
	
	return CorrectedColor;
}

vec4 GetGrayscaleFontElementColor()
{
	vec4 OutColor = Color;
#if PLATFORM_LINUX
	OutColor.a *= texture2D(ElementTexture, TexCoords.xy).r; // OpenGL 3.2+ uses Red for single channel textures
#else
	OutColor.a *= texture2D(ElementTexture, TexCoords.xy).a;
#endif

	return OutColor;
}

vec4 GetColorFontElementColor()
{
	vec4 OutColor = Color;

	OutColor *= texture2D(ElementTexture, TexCoords.xy);

	return OutColor;
}

vec4 GetDefaultElementColor()
{
	vec4 OutColor = Color;

	vec4 TextureColor = texture2D(ElementTexture, TexCoords.xy*TexCoords.zw);
	if( IgnoreTextureAlpha )
	{
		TextureColor.a = 1.0;
	}
	OutColor *= TextureColor;

	return OutColor;
}

vec4 GetBorderElementColor()
{
	vec4 OutColor = Color;
	vec4 InTexCoords = TexCoords;
	vec2 NewUV;
	if( InTexCoords.z == 0.0 && InTexCoords.w == 0.0 )
	{
		NewUV = InTexCoords.xy;
	}
	else
	{
		vec2 MinUV;
		vec2 MaxUV;
	
		if( InTexCoords.z > 0.0 )
		{
			MinUV = vec2(MarginUVs.x,0.0);
			MaxUV = vec2(MarginUVs.y,1.0);
			InTexCoords.w = 1.0;
		}
		else
		{
			MinUV = vec2(0.0,MarginUVs.z);
			MaxUV = vec2(1.0,MarginUVs.w);
			InTexCoords.z = 1.0;
		}

		NewUV = InTexCoords.xy*InTexCoords.zw;
		NewUV = fract(NewUV);
		NewUV = mix(MinUV,MaxUV,NewUV);	

	}

	vec4 TextureColor = texture2D(ElementTexture, NewUV);
	if( IgnoreTextureAlpha )
	{
		TextureColor.a = 1.0;
	}
		
	OutColor *= TextureColor;

	return OutColor;
}

vec4 GetSplineElementColor()
{
	float LineWidth = MarginUVs.x;
	float FilterWidthScale = MarginUVs.y;

	float Gradient = TexCoords.x;
	vec2 GradientDerivative = vec2(abs(dFdx(Gradient)), abs(dFdy(Gradient)));
	float PixelSizeInUV = sqrt(dot(GradientDerivative, GradientDerivative));
	
	float HalfLineWidthUV = 0.5f*PixelSizeInUV * LineWidth;	
	float HalfFilterWidthUV = FilterWidthScale * PixelSizeInUV;
	float DistanceToLineCenter = abs(0.5 - Gradient);
	float LineCoverage = smoothstep(HalfLineWidthUV+HalfFilterWidthUV, HalfLineWidthUV-HalfFilterWidthUV, DistanceToLineCenter);

	if (LineCoverage <= 0.0)
	{
		discard;
	}

	vec4 InColor = Color;
	InColor.a *= LineCoverage;
	return InColor;
}

void main()
{
	vec4 OutColor;

	if( ShaderType == ST_Default )
	{
		OutColor = GetDefaultElementColor();
	}
	else if( ShaderType == ST_Border )
	{
		OutColor = GetBorderElementColor();
	}
	else if( ShaderType == ST_GrayscaleFont )
	{
		OutColor = GetGrayscaleFontElementColor();
	}
	else if( ShaderType == ST_ColorFont )
	{
		OutColor = GetColorFontElementColor();
	}
	else
	{
		OutColor = GetSplineElementColor();
	}
	
	// gamma correct
	OutColor.rgb = GammaCorrect(OutColor.rgb);
	
	if( EffectsDisabled )
	{
		//desaturate
		vec3 LumCoeffs = vec3( 0.3, 0.59, .11 );
		float Lum = dot( LumCoeffs, OutColor.rgb );
		OutColor.rgb = mix( OutColor.rgb, vec3(Lum,Lum,Lum), .8 );
	
		vec3 Grayish = vec3(0.4, 0.4, 0.4);
	
		OutColor.rgb = mix( OutColor.rgb, Grayish, clamp( distance( OutColor.rgb, Grayish ), 0.0, 0.8)  );
	}

	gl_FragColor = OutColor.bgra;
}
