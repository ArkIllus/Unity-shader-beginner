Shader "Unity Shaders Book/Chapter 12/Motion Blur" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BlurAmount ("Blur Amount", Float) = 1.0 //在OnRenderImage中被设置
	}
	SubShader {
		//使用CGINCLUDE来组织代码 目的：避免代码重复
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		fixed _BlurAmount;
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
		};
		
		v2f vert(appdata_img v) {
			v2f o;
			
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = v.texcoord;
					 
			return o;
		}

		//定义了两个片元着色器
		//一个用于更新渲染纹理的 RGB 通道部分 
		fixed4 fragRGB (v2f i) : SV_Target {
			//RGB 通道版本的 Shader 对当前图像进行采样，
			//并将其 A 通道的值设为_BlurAmount, 以便在后面混合时可以使用它的透明通道进行混合
			return fixed4(tex2D(_MainTex, i.uv).rgb, _BlurAmount);
		}

		//一个用于更新渲染纹理的 A 通道部分
		half4 fragA (v2f i) : SV_Target {
			//直接返回采样结果。 
			//实际上， 这个版本只是为了维护渲染纹理的透明通道值， 不让其受到混合时使用的透明度值的影响。？？
			return tex2D(_MainTex, i.uv);
		}
		
		ENDCG
		
		ZTest Always Cull Off ZWrite Off //屏幕后处理shader的标配
                                         //深度测试的函数：总是通过 关闭剔除 关闭深度写入
		
		//需要两个 Pass, 一个用于更新渲染纹理的 RGB 通道， 另一个用于更新 A 通道。 
		//之所以要把 A 通道和 RGB 通道分开， 是因为在
		//更新 RGB 时我们需要设置它的 A 通道来混合图像， 但又不希望 A 通道的值写入渲染纹理中。
		Pass {
			Blend SrcAlpha OneMinusSrcAlpha //（颜色通道的写掩码=RGB） 新的颜色缓存中的颜色=片元颜色×A通道值+颜色缓存中的颜色(1-A通道值)
			ColorMask RGB
			
			CGPROGRAM
			
			#pragma vertex vert  
			#pragma fragment fragRGB  
			
			ENDCG
		}
		
		Pass {   
			Blend One Zero //（颜色通道的写掩码=A）新的颜色缓存中的颜色=片元颜色（？）
			ColorMask A //
			   	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment fragA
			  
			ENDCG
		}
	}
 	FallBack Off
}
//本节是对运动模糊的一种简单实现。我们混合了连续帧之间的图像，这样得到一张具有模糊拖尾的图像。
//然而，当物体运动速度过快时，这种方法可能会造成单独的帧图像变得可见 
//在第13 章中会学习如何利用“深度纹理重建速度”来模拟运动模糊效果