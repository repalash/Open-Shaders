// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// Texture tinted towards white, multiplied by _Color.
// Used in scene view visualization modes.
Shader "Hidden/SceneColoredTexture"
{
    Properties
    {
        _Color ("", Color) = (1,1,1,1)
        _MainTex ("", 2D) = "gray" {}
    }
    SubShader
    {
        Pass
        {
            Fog { Mode Off }
            SetTexture [_MainTex] { constantColor (1,1,1,0.5) combine constant lerp(constant) texture } // lerp texture towards white
            SetTexture [_MainTex] { constantColor [_Color] combine previous * constant } // multiply by color
        }
    }
}
