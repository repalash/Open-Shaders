// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

Shader "Hidden/TreeTextureCombiner Shader" {
    Properties {
        _Color ("Main Color", Color) = (1,1,1,1)
        _RGBSource ("RGB Source", 2D) = "black" {}
        _AlphaSource ("Alpha Source", 2D) = "black" {}
    }

    SubShader {
        Tags { "ForceSupported" = "True" }

        Lighting Off Cull Off ZTest Always ZWrite Off

        // Combine normal + specular
        Pass {
            // Extract the normal and clear the other channels
            SetTexture [_RGBSource] {
                constantColor (0,1,0,1)
                combine constant * texture
            }
            // Add specular to the red channel
            SetTexture [_RGBSource] {
                constantColor [_Color]
                combine constant + previous
            }
            // Add shadow offset to the blue channel
            SetTexture [_AlphaSource] {
                constantColor (0,0,1,0)
                combine constant * texture alpha + previous
            }
        }

        // Combine diffuse
        Pass {
            SetTexture [_RGBSource] {
                constantColor [_Color]
                combine constant * texture, texture alpha
            }
        }

        // Combine translucency + gloss
        Pass {
            // Store translucency mask in the blue channel
            SetTexture [_RGBSource] {
                constantColor (0,0,1,0)
                combine constant * texture alpha
            }
            // Store gloss in the alpha channel
            SetTexture [_AlphaSource] {
                combine previous, texture alpha
            }
        }

        // Combine shadow
        Pass {
            SetTexture [_AlphaSource] {
                combine texture alpha
            }
        }
    }

    Fallback Off
}
