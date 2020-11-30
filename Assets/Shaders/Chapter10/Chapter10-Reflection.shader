Shader "Unity Shaders Book/Chapter10-Reflection"
{
    Properties{
        _Color("Color Tint",Color)=(1,1,1,1)
        _ReflectColor("Reflect Color",Color)=(1,1,1,1)
        _ReflectAmount("Reflect Amount",Range(0,1))=1
        _Cubemap("Reflection Cubemap",Cube)="_Skybox"{}
    }

    SubShader{
        Tags{"RenderType"="Opaque" "Queue"="Geometry"}

        pass{
            Tags{"LightMode"="ForwardBase"}

            CGPROGRAM
            #pragma multi_compile_fwdbase
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed4 _ReflectColor;
            fixed _ReflectAmount;
            samplerCUBE _Cubemap;

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
            };

            struct v2f{
                float4 pos:SV_POSITION;
                float3 worldPos:TEXCOORD0;
                float3 worldNormal:TEXCOORD1;
                float3 worldViewDir:TEXCOORD2;
                float3 worldRefl:TEXCOORD3;
                SHADOW_COORDS(4)
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.worldNormal=UnityObjectToWorldNormal(v.normal);
                o.worldPos=mul(unity_ObjectToWorld,v.vertex).xyz;
                o.worldViewDir=UnityWorldSpaceViewDir(o.worldPos);
                //worldVeiwDir是从该点到视点方向
                //计算视角方向关于顶点法线的反射方向来求得入射光线的方向，用入射光线方向求反来采样
                o.worldRefl=reflect(-o.worldViewDir,o.worldNormal);

                TRANSFER_SHADOW(o);
                return o;
            }

            fixed4 frag(v2f i):SV_TARGET{
                fixed3 worldNormal=normalize(i.worldNormal);
                fixed3 worldLightDir=normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir=normalize(i.worldViewDir);
                fixed3 ambeint=UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse=_LightColor0.rgb*_Color.rgb*max(0,dot(worldLightDir,worldNormal));
                fixed3 reflection=texCUBE(_Cubemap,i.worldRefl).rgb*_ReflectColor.rbg;
                
                UNITY_LIGHT_ATTENUATION(atten,i,i.worldPos);
                fixed3 color=ambeint+lerp(diffuse,reflection,_ReflectAmount);
                return fixed4(color,1.0);
            }
            ENDCG
        }
    }
}
