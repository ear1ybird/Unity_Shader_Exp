Shader "Unity Shaders Book/Chapter-10-GlassRefraction"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
		_BumpMap ("Normal Map", 2D) = "bump" {}
		_Cubemap ("Environment Cubemap", Cube) = "_Skybox" {}
		_Distortion ("Distortion", Range(0, 100)) = 10
		_RefractAmount ("Refract Amount", Range(0.0, 1.0)) = 1.0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Opaque" }

        //使用GrabPas来获取屏幕图像，抓取的图形存入该纹理中
        GrabPass{"_RefractionTex"}

		//GrabPass获取折射纹理，Cubemap获取反射纹理

        Pass
        {
            CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

            sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			samplerCUBE _Cubemap;
			float _Distortion;
			fixed _RefractAmount;
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize;        //用于得到该纹理的文素大小(1/分辨率)

            struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT; 
				float2 texcoord: TEXCOORD0;
			};

            struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;  
			    float4 TtoW1 : TEXCOORD3;  
			    float4 TtoW2 : TEXCOORD4; 
			};

            v2f vert (a2v v){
                v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				//得到对应被抓取的屏幕图像的坐标
				o.scrPos = ComputeGrabScreenPos(o.pos);

				//计算采样坐标，使用_MainTex_ST
				//两个二维纹理坐标存储到一个四维向量中
				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				//把四个3维向量存储到三个四维向量中。得到切线空间到法线空间的变换矩阵（三维空间坐标变换）
				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);  
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);  
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				return o;
            }

			fixed4 frag (v2f i) : SV_Target{
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));

				//使用_Distortion属性使折射采样坐标偏移
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;

				//屏幕坐标除以屏幕分辨率得到视口空间坐标，即采样坐标
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy/i.scrPos.w).rgb;
				
				//使用上述变换矩阵将法线从切线空间变换到世界空间
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				fixed3 reflDir = reflect(-worldViewDir, bump);
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;
				fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;

				return fixed4(finalColor, 1);
			}

			ENDCG
        }
    }
}
