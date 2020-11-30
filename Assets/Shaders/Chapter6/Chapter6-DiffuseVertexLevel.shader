// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter6-DiffuseVertexLevel"
{
    Properties
    {
        _Diffuse("Diffuse",Color)=(1,1,1,1)
    }

    SubShader
    {
        Pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }

        CGPROGRAM

		#pragma vertex vert
		#pragma fragment frag

		#include "Lighting.cginc"

		fixed4 _Diffuse;

		struct a2v{
			float4 vertex:POSITION;
			float3 normal:NORMAL;
		};

		struct v2f{
			float4 pos:SV_POSITION;
			fixed3 color:COLOR;
		};

		v2f vert(a2v v){
			v2f o;
			o.pos=UnityObjectToClipPos(v.vertex);

			//获取环境光变量
			fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;
			
			//将法线和光源方向都转换到世界坐标系
			fixed3 worldNormal=normalize(mul(v.normal,(float3x3)unity_WorldToObject));				//调换mul函数中两个矩阵的位置，得到和装转置矩阵相同的矩阵乘法
			fixed3 worldLight=normalize(_WorldSpaceLightPos0.xyz);									//仅适用于只有一个光源的情况
			
			//标准光照模型的漫反射
			fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLight));		//saturate函数把参数截取为(0,1)

			o.color=ambient+diffuse;
			return o;
		}

		fixed4 frag(v2f i):SV_TARGET{
			return fixed4(i.color,1.0);
		}

		ENDCG
        }
    }
    FallBack "Diffuse"
}