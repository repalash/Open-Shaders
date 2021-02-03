// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// Shader used for picking of gizmos/icons in the scene view.
// Just outputs vertex color, using gizmo-like depth testing passes.
Shader "Hidden/Editor Gizmo Icon Picking"
{
    SubShader
    {
        Fog { Mode Off }

        Pass // regular pass
        {
            ZTest LEqual
            ZWrite On
        }
        Pass // occluded pass
        {
            ZTest Greater
            ZWrite Off
        }
    }
}
