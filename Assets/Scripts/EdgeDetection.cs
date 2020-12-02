using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class EdgeDetection : PostEffectsBase
{
    public Shader edgeDetectShader;
    private Material edgeDetectMaterial = null;

    [Range(0.0f, 1.0f)] public float edgeOnly = 0.0f;
    public Color EdgeColor=Color.black;
    public Color backgroundColor=Color.white;

    public Material material
    {
        get
        {
            edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
            return edgeDetectMaterial;
        }
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        if (material != null)
        {
            material.SetFloat("_EdgeOnly", edgeOnly);
            material.SetColor("_EdgeColor", EdgeColor);
            material.SetColor("_BackgroundColor", backgroundColor);
            Graphics.Blit(src, dest, material);
        }
        else
        {
            Graphics.Blit(src,dest);
        }
    }
}
