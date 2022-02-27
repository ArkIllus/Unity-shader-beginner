Shader "Unity Shaders Book/Chapter 13/Motion Blur With Depth Texture" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_BlurSize("Blur Size", Float) = 1.0  //在OnRenderImage中被设置
		//我们注意到，虽然在脚本里设置了材质的_PreviousViewProjectionMatrix 和_CurrentViewProjectioInverseMatrix属性，
		//但并没有在 Properties 块中声明它们。这是因为 Unity 没有提供矩阵类型的属性，但我们仍然
		//可以在 CG 代码块中定义这些矩阵，并从脚本中设置它们。
	}
	SubShader {
		//使用CGINCLUDE来组织代码 目的：避免代码重复
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture; //Unity传递给我们的深度纹理
		float4x4 _CurrentViewProjectionInverseMatrix; //脚本传递来的矩阵
		float4x4 _PreviousViewProjectionMatrix; //脚本传递来的矩阵
		half _BlurSize;
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1; //专门用于对深度纹理采样的纹理坐标
		};
		
		v2f vert(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);

			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;

			//同时处理多张渲染纹理 + 抗锯齿，此时需要对DirectX这样的平台处理翻转问题（称作平台差异化处理）
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif

			return o;
		}

		fixed4 frag(v2f i) : SV_Target {
			// 使用内置的 SAMPLE_DEPTH_TEXTURE 宏 和纹理坐标对深度纹理进行采样 ，得到了深度值d
			// Get the depth buffer value at this pixel.
			float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
			// 深度值d是由NDC下的坐标映射而来的。把深度值d重新映射回NDC即d * 2 - 1
			// 同样，NDC的xy分量可以由像素的纹理坐标映射而来，得到NDC坐标H（xyz分量范围均为[-1, 1]）（又称视口位置？）
			// H is the viewport position at this pixel in the range -1 to 1.
			float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);
			// 使用当前帧的视角*投影矩阵的逆矩阵对H进行变换，并把结果值除以它的w分量来得到世界空间下的坐标worldPos
			// Transform by the view-projection inverse.
			float4 D = mul(_CurrentViewProjectionInverseMatrix, H);
			// Divide by w to get the world position. 
			float4 worldPos = D / D.w;
			
			// 当前帧的NDC下的坐标
			// Current viewport position 
			float4 currentPos = H;
			// 前一帧的视角*投影矩阵 * 世界空间下的坐标 = 前一帧的NDC下的坐标previousPos（也是还要除以它的w分量）
			// Use the world position, and transform by the previous view-projection matrix.  
			float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
			// Convert to nonhomogeneous points [-1,1] by dividing by w.
			previousPos /= previousPos.w;
			
			// 计算前一帧和当前帧在屏幕空间（NDC坐标）下的位置差，得到该像素（片元）的速度
			// Use this frame's position and last frame's to compute the pixel velocity.
			float2 velocity = (currentPos.xy - previousPos.xy)/2.0f;
			
			// 使用速度值对该像素（片元）的邻域像素进行采样，相加后取平均得到模糊的效果
			float2 uv = i.uv;
			float4 c = tex2D(_MainTex, uv);
			uv += velocity * _BlurSize; //这里还用_BlurSize控制了采样距离
			for (int it = 1; it < 3; it++, uv += velocity * _BlurSize) {
				float4 currentColor = tex2D(_MainTex, uv);
				c += currentColor;
			}
			c /= 3;
			
			return fixed4(c.rgb, 1.0);
		}
		
		ENDCG
		
		Pass {      
			ZTest Always Cull Off ZWrite Off //屏幕后处理shader的标配 //深度测试的函数：总是通过 关闭剔除 关闭深度写入
			    	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG  
		}
	} 
	FallBack Off
}

//本节实现的运动模糊适用于场景静止、摄像机快速运动的情况，这是因为我们在计算时只考虑了摄像机的运动。
//因此，如果读者把本节中的代码应用到一个物体快速运动而摄像机静止的场景，会发现不会产生任何运动模糊效果。
//如果我们想要对快速移动的物体产生运动模糊的效果，就需要生成更加精确的速度映射图。
//读者可以在 Unity 自带的 Image Effect 包中找到更多的运动模糊的实现方法。
//
//本节选择在片元着色器中使用逆矩阵来重建每个像素在世界空间下的位置。但是，这种做法往往会影响性能，
//在 13.3 节中，我们会介绍一种更快速的由深度纹理重建世界坐标的方法。

//我：另外，感觉效果不太对劲，①有迷之抖动，②并且如果暂停的话会发现是画面没有模糊（为啥呢？）。