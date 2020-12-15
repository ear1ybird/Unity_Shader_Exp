Shader "Unity Shaders Book/Chapter13-EdgeDetecNormalAndDetpth"
{
    Properties
    {
        _MainTex ("Base (RGB)", 2D) = "white" {}
		_EdgeOnly ("Edge Only", Float) = 1.0
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
		_SampleDistance ("Sample Distance", Float) = 1.0
		_Sensitivity ("Sensitivity", Vector) = (1, 1, 1, 1)
    }
    SubShader
    {
        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize;
        fixed _EdgeOnly;
        fixed4 _EdgeColor;
        fixed4 _BackgroundColor;
        float _SampleDistance;
        half4 _Sensitivity;

        sampler2D _CameraDepthNormalsTexture;

        struct v2f {
            float4 pos:SV_POSITION;
            half2 uv[5]:TEXCOORD0;
        };

        v2f vert(appdata_img v){
            v2f o;
            o.pos=UnityObjectToClipPos(v.vertex);

            half2 uv=v.texcoord;
            o.uv[0]=uv;

            #if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				uv.y = 1 - uv.y;
			#endif

            o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1,1) * _SampleDistance;
			o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1,-1) * _SampleDistance;
			o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,1) * _SampleDistance;
			o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1,-1) * _SampleDistance;
            
            return o;
        }

        half CheckSame(half4 center,half4 sample){
            half2 centerNormal = center.xy;   //只需要计算法线之间的差异度，而不需要真正的法线
            float centerDepth=DecodeFloatRG(center.zw);
            half2 sampleNormal=sample.xy;
            float sampleDepth=DecodeFloatRG(sample.zw);

            half2 diffNormal=abs(centerNormal-sampleNormal)*_Sensitivity.x;
            int isSameNormal=(diffNormal.x+diffNormal.y)<0.1;   //小于该阈值则差异不明显，返回1

            float diffDepth=abs(centerDepth-sampleDepth)*_Sensitivity.y;
            int isSameDepth=diffDepth<0.1*centerDepth;         //用深度作为阈值，深度越大，阈值越高

            return isSameNormal*isSameDepth?1.0:0.0;            //两项都为1时，不存在边缘（1真，0非）
        }

        fixed4 fragRobertsCrossDepthAndNormal(v2f i):SV_TARGET{
            half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]);
			half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);
			half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);
			half4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4]);

            half edge=1.0;

            edge *= CheckSame(sample1, sample2);
			edge *= CheckSame(sample3, sample4);
            //edge为0 代表是边缘
            fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[0]), edge);
			fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);
			
			return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
        }
        ENDCG

        Pass{
            ZTest Always Cull Off ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragRobertsCrossDepthAndNormal

            ENDCG
        }
    }
}
