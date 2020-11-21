Shader "Unity Shaders Book/Chapter8-AlphaTestBothSided"
{
    Properties
    {
        _Color ("Color Tint",Color)=(1,1,1,1)
        _MainTex ("Main Tex", 2D) = "white" {}
        _Cutoff("Alpha Cutoff",Range(0,1))=0.5
    }
    SubShader
    {
        Tags{"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        
        Pass{
            Tags{"LightMode"="ForwardBase"}
            
            //关闭剔除，即打开双面渲染
            Cull off

            CGPROGRAM
            #pragma vertex vert
			#pragma fragment frag
            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Cutoff;

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 texcoord:TEXCOORD0;
            };

            struct v2f{
                float4 pos:SV_POSITION;
                float3 worldNormal:TEXCOORD0;
                float3 worldPos:TEXCOORD1;
                float2 uv:TEXCOORD2;
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
                fixed4 texCoord=tex2D(_MainTex,i.uv);

                //剔除透明度小于_Cutoff的像素
                clip(texCoord.a-_Cutoff);
                // if(texCoord.a-_Cutoff<0.0){
                //     discard;
                // }

                fixed3 albedo=texCoord.rgb*_Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT.xyz*_Color;
                fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(worldNormal,worldLightDir));
                return fixed4(ambient+diffuse,1.0);
            }
            
            ENDCG
        }
    }
}
