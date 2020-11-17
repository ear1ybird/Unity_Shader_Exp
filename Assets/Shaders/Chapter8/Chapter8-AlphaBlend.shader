Shader "Unity Shaders Book/Chapter8-AlphaBlend"
{
    Properties{
        _Color("Main Tint",Color)=(1,1,1,1)
        _MainTex("Main Tex",2D)="white" {}
        _AlphaScale("Alpha Scale",Range(0,1))=1
    }

    SubShader{
        Tags{"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}

        pass{
            Tags { "LightMode"="ForwardBase" }

            //关闭深度写入
            ZWrite off

            //将源颜色的混合因子设为SrcAlpha，将目标颜色混合因子设为OneMinusSecAlpha
            Blend SrcAlpha oneMinusSrcAlpha


            CGPROGRAM
            #pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            float _AlphaScale;

            struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float3 worldNormal : TEXCOORD0;
				float3 worldPos : TEXCOORD1;
				float2 uv : TEXCOORD2;
			};

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }

            fixed4 frag(v2f i):SV_TARGET{
                fixed3 worldNormal=normalize(i.worldNormal);
                fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor=tex2D(_MainTex,i.uv);
                fixed3 albedo=texColor.rgb*_Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*albedo;
                fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(worldNormal,worldLightDir));
                
                //设置该片元着色器返回值中的透明通道，他是纹理像素透明通道和材质参数_AlphaScale的乘积
                //只有用Blend命令打开混合后，这里设置透明通道才有意义
                return fixed4(ambient+diffuse,texColor.a*_AlphaScale);
            }
            ENDCG
        }
    }
}
