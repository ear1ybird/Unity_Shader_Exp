// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unity Shaders Book/Chapter7-NormalMapWorldSpace"
{
    Properties
    {
        _Color("Color",color)=(1,1,1,1)
        _MainTex("MainTex",2D)="white"{}
        _BumpMap("BumpMat",2D)="bump"{}
        _BumpScale("Bump Scale",float)=1.0
        _Specular("Specular",color)=(1,1,1,1)
        _Gloss("Gloss",Range(8.0,256))=20
    }
    SubShader
    {

        pass
        {
            Tags
            {
                "LightMode"="ForwardBase"
            }

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v{
                float4 vertex:POSITION;
                float3 normal:NORMAL;
                float4 tangent:TANGENT;
                float4 texcoord:TEXCOORD0;
            };

            struct v2f{
                float4 pos:POSITION;
                float4 uv:TEXCOORD0;
                float4 TtoW0:TEXCOORD1;
                float4 TtoW1:TEXCOORD2;
                float4 TtoW2:TEXCOORD3;
            };

            v2f vert(a2v v){
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex);
                o.uv.xy=v.texcoord.xy*_MainTex_ST.xy+_MainTex_ST.zw;
                o.uv.zw=v.texcoord.xy*_BumpMap_ST.xy+_BumpMap_ST.zw;

                //计算切线坐标到世界坐标的变换矩阵
                float3 worldPos=mul(unity_ObjectToWorld,v.vertex);
                float3 worldNormal=UnityObjectToWorldNormal(v.normal);
                float3 worldTangent=UnityObjectToWorldDir(v.tangent.xyz);
                float3 worldBinormal=cross(worldNormal,worldTangent)*v.tangent.w;       //v.tangent.w值为-1或者1,由DCC软件中的切线自动生成,和顶点的环绕顺序有关。
                                                                                        //法线纹理中只有两个分量是真正必不可少的，因此可以被压缩
                //为了充分利用存储空间，把世界坐标下的顶点存在w分量中
                o.TtoW0=float4(worldTangent.x,worldBinormal.x,worldNormal.x,worldPos.x);
                o.TtoW1=float4(worldTangent.y,worldBinormal.y,worldNormal.y,worldPos.y);
                o.TtoW2=float4(worldTangent.z,worldBinormal.z,worldNormal.z,worldPos.z);
                return o;
            }

            fixed4 frag(v2f i):SV_TARGET{
                float3 worldPos=float3(i.TtoW0.w,i.TtoW1.w,i.TtoW2.w);
                float3 lightDir=normalize(UnityWorldSpaceLightDir(worldPos));
                float3 viewDir=normalize(UnityWorldSpaceViewDir(worldPos));
                
                fixed3 bump=UnpackNormal(tex2D(_BumpMap,i.uv.zw));
                bump.xy*=_BumpScale;
                bump.z=sqrt(1.0-saturate(dot(bump.xy,bump.xy)));
                //将法线纹理从切线坐标转换到世界坐标
                bump =normalize(half3(dot(i.TtoW0.xyz,bump),dot(i.TtoW1.xyz,bump),dot(i.TtoW2.xyz,bump)));

                fixed3 albedo=tex2D(_MainTex,i.uv.xy).rgb*_Color.rgb;
                fixed3 ambient=UNITY_LIGHTMODEL_AMBIENT*albedo;
                fixed3 diffuse=_LightColor0.rgb*albedo*max(0,dot(bump,lightDir));
                fixed3 halfDir=normalize(lightDir+viewDir);
                fixed3 specular=_LightColor0.rgb*_Specular.rgb*pow(max(0,dot(bump,halfDir)),_Gloss);

                return fixed4(ambient+diffuse+specular,1.0);
            }
            ENDCG
        }
    }
}