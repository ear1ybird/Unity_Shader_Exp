Shader "Unity Shaders Book/Chapter9-AttenuationAndShadowUseBuildInFunctions"
{
    Properties {
		_Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
		_Specular ("Specular", Color) = (1, 1, 1, 1)
		_Gloss ("Gloss", Range(8.0, 256)) = 20
	}
    SubShader
    {
        Tags { "RenderType"="Opaque" }
    
        //第一个Base Pass处理平行光
        Pass{
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM

            //保证光照衰减等光照变量可以被正确赋值
            #pragma multi_compile_fwdbase

            #pragma vertex vert
		    #pragma fragment frag
		
		    #include "Lighting.cginc"
            #include "AutoLight.cginc"

		    fixed4 _Diffuse;
		    fixed4 _Specular;
		    float _Gloss;

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL; 
            };

            struct v2f{
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                //声明用于对阴影纹理采样的坐标
                SHADOW_COORDS(2)
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex);
                //计算上一步声明的阴影纹理坐标
                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i):SV_TARGET{
                fixed3 worldNormal=normalize(i.worldNormal);
                fixed3 worldLightDir=normalize(_WorldSpaceLightPos0.xyz);
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz;

                fixed3 diffuse=_LightColor0.rgb*_Diffuse.rgb*max(0,dot(worldNormal,worldLightDir));
                fixed3 viewDir=normalize(_WorldSpaceCameraPos.xyz-i.worldPos.xyz);
                fixed3 halfDir=normalize(worldLightDir+viewDir);
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(worldNormal,halfDir)),_Gloss);
                
                //平行光衰减值为1
                //fixed atten=1.0;
                
                //同时计算光照衰减和阴影
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                //计算阴影值
                return fixed4(ambient+(diffuse+specular)*atten,1.0);
            }
            ENDCG
        }

        //第二个Additional Pass处理其他光源
        Pass{
            Tags { "LightMode"="ForwardAdd" }
            
            //让Additional Pass计算得到的结果与Base Pass的结果叠加
            Blend One One

            CGPROGRAM
            #pragma multi_compile_fwdadd

            #pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			
			fixed4 _Diffuse;
			fixed4 _Specular;
			float _Gloss;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
			};
			
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				
				o.worldNormal = UnityObjectToWorldNormal(v.normal);
				
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				
				return o;
			}

            fixed4 frag(v2f i) : SV_Target{
                fixed3 worldNormal = normalize(i.worldNormal);
				
                //该Pass仍有可能计算平行光，判断是否定义了平行光
                #ifdef USING_DIRECTIONAL_LIGHT
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
				#else
					fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
				#endif
				
				fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
				
				fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
				fixed3 halfDir = normalize(worldLightDir + viewDir);
				fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);
            
                #ifdef USINT_DIRECTIONAL_LIGHT
                    fixed atten=1.0;
                #else
                    #if defined (POINT)
                        //通过查找表纹理处理光源衰减
                        //得到光源空间下的坐标
                        float3 lightCoord=mul(unity_WorldToLight,float4(i.worldPos,1)).xyz;
                        //使用该坐标对衰减纹理采样获取衰减值
                        fixed atten =tex2D(_LightTexture0,dot(lightCoord,lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #elif defined (SOPT)
                        float4 lightCoord=mul(unity_WorldToLight,float4(i.worldPos,1));
                        fixed atten=(lightCoord.z>0)*tex2D(_LightTexture0,lightCoord.xy/lightCoord.w+0.5).w*tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #else
				        fixed atten = 1.0;
                        #endif
				#endif

                return fixed4((diffuse+specular)*atten,1.0); 
            }
        
            ENDCG
        }
    }
    Fallback "Specular"
}
