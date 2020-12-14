using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FogWithDepthTexture : PostEffectsBase
{
    public Shader fogShader;
    private Material fogMaterial = null;

    public Material material
    {
        get
        {
            fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
            return fogMaterial;
        }
    }

    private Camera myCamera;
    public Camera camera
    {
        get
        {
            if (myCamera == null)
            {
                myCamera = GetComponent<Camera>();
            }
            return myCamera;
        }
    }

    private Transform myCameraTransform;

    public Transform cameraTransform
    {
        get
        {
            if (myCameraTransform == null)
            {
                myCameraTransform = camera.transform;
            }
            return myCameraTransform;
        }
    }

    [Range(0.0f, 3.0f)] public float fogDensity = 1.0f;
    public Color fogColor=Color.white;
    public float fogStart = 0.0f;
    public float fogEnd = 2.0f;

    private void OnEnable()
    {
        camera.depthTextureMode |= DepthTextureMode.Depth;
    }

    private void OnRenderImage(RenderTexture src, RenderTexture dest)
    {
        Matrix4x4 frustumCorners=Matrix4x4.identity;
        if (material != null)
        {
            float fov = camera.fieldOfView;
            float near = camera.nearClipPlane;
            float aspect = camera.aspect;

            float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);    //角度转换为弧度传入Tan()
            Vector3 toTop = cameraTransform.up * halfHeight;
            Vector3 toRight = cameraTransform.right * halfHeight * aspect;

            Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
            float scale = topLeft.magnitude / near;
            
            topLeft.Normalize();
            topLeft *= scale;        //scale作为四个角向量的长度，根据三角形相似: dist=scale*depth

            Vector3 topRight = cameraTransform.forward * near + toTop + toRight;
            topRight.Normalize();
            topRight *= scale;

            Vector3 bottonLeft = cameraTransform.forward * near - toTop - toRight;
            bottonLeft.Normalize();
            bottonLeft *= scale;

            Vector3 bottonRight = cameraTransform.forward * near - toTop + toRight;
            bottonRight.Normalize();
            bottonRight *= scale;
            
            //赋值视锥角向量矩阵
            frustumCorners.SetRow(0,bottonLeft);
            frustumCorners.SetRow(1,bottonRight);
            frustumCorners.SetRow(2,topRight);
            frustumCorners.SetRow(3,topLeft);
            
            material.SetMatrix("_FrustumCornersRay",frustumCorners);
            material.SetMatrix("_ViewProjectionInverseMatrix",(camera.projectionMatrix*camera.worldToCameraMatrix).inverse);
            
            material.SetFloat("_FogDensity",fogDensity);
            material.SetColor("_FogColor",fogColor);
            material.SetFloat("_FogStart",fogStart);
            material.SetFloat("_FogEnd",fogEnd);
            
            Graphics.Blit(src,dest,material);
        }
        else
        {
            Graphics.Blit(src,dest);
        }
    }
}
