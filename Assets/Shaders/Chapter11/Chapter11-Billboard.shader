Shader "Unity Shaders Book/Chapter11-Billboard"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {}
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_VerticalBillboarding ("Vertical Restraints", Range(0, 1)) = 1 
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}

        Pass
        {
            Tags { "LightMode"="ForwardBase" }

            ZWrite Off
			Blend SrcAlpha OneMinusSrcAlpha
			Cull Off

            CGPROGRAM
            #pragma vertex vert
			#pragma fragment frag
			
			#include "Lighting.cginc"
			
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _Color;
			fixed _VerticalBillboarding;

            struct a2v {
				float4 vertex : POSITION;
				float4 texcoord : TEXCOORD0;
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
			};


            v2f vert(a2v v){
                v2f o;
                float3 center = float3(0, 0, 0);
                float3 viewer = mul(unity_WorldToObject,float4(_WorldSpaceCameraPos, 1));

                float3 normalDir=viewer-center;

                //用_VerticalBillboarding控制垂直方向上的偏移度
                normalDir.y=normalDir.y*_VerticalBillboarding;
                normalDir=normalize(normalDir);
                //计算三个正交基
                //防止法线和Up平行导致叉积错误
                float3 upDir=abs(normalDir.y)>0.999? float3(0,0,1):float3(0,1,0);
                float3 rightDir=normalize(cross(upDir,normalDir));
                upDir=normalize(cross(normalDir,rightDir));

                //计算新的顶点位置(从模型空间变换到上述正交基空间)
                float3 centerOffs=v.vertex-center;
                float3 localPos=center+rightDir*centerOffs.x+upDir*centerOffs.y+normalDir*centerOffs.z;
                o.pos=UnityObjectToClipPos(float4(localPos,1));
                o.uv=TRANSFORM_TEX(v.texcoord,_MainTex);
                return o;
            }

            fixed4 frag(v2f i):SV_TARGET{
                    fixed4 c=tex2D(_MainTex,i.uv);
                    c.rgb*=_Color.rgb;
                    return c;
            }

            ENDCG
        }
    }
}
