Shader "Unity Shaders Book/Chapter12-BrightnessSaturationAndContrast"
{
    Properties
    {
       _MainTex ("Base (RGB)", 2D) = "white" {}
		_Brightness ("Brightness", Float) = 1
		_Saturation("Saturation", Float) = 1
		_Contrast("Contrast", Float) = 1
    }
    SubShader
    {
        
        Pass
        {
            ZTest Always Cull off ZWrite off
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _MainTex;  
			half _Brightness;
			half _Saturation;
			half _Contrast;

            struct v2f {
				float4 pos : SV_POSITION;
				half2 uv: TEXCOORD0;
			};

            //appdata_img只包含图像处理必须的顶点坐标和纹理坐标
            v2f vert(appdata_img v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.texcoord;		 
				return o;
			}

            fixed4 frag(v2f i):SV_TARGET{
                fixed4 renderTex = tex2D(_MainTex, i.uv);  
                fixed3 finalColor = renderTex.rgb * _Brightness;

                //亮度值公式
                fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                //使用亮度值公式创建饱和度为0的颜色值
                fixed3 luminanceColor=fixed3(luminance,luminance,luminance);
                finalColor = lerp(luminanceColor, finalColor, _Saturation);
                //对比度
                fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
				finalColor = lerp(avgColor, finalColor, _Contrast);

                return fixed4(finalColor,renderTex.a);
            }

            ENDCG
        }
    }
}
