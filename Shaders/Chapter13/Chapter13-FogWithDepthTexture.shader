Shader "Unity Shaders Book/Chapter 13/Fog With Depth Texture" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_FogDensity("Fog Density", Float) = 1.0 //在OnRenderImage中被设置
		_FogColor("Fog Color", Color) = (1, 1, 1, 1) //在OnRenderImage中被设置
		_FogStart("Fog Start", Float) = 0.0 //在OnRenderImage中被设置
		_FogEnd("Fog End", Float) = 1.0 //在OnRenderImage中被设置
	}
	SubShader {
		//使用CGINCLUDE来组织代码 目的：避免代码重复
		CGINCLUDE
		
		#include "UnityCG.cginc"

		float4x4 _FrustumCornersRay; //脚本传递来的矩阵（没有在 Properties 中声明）

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture; //Unity传递给我们的深度纹理（没有在 Properties 中声明）
		half _FogDensity;
		fixed4 _FogColor;
		float _FogStart;
		float _FogEnd;
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1; //专门用于对深度纹理采样的纹理坐标
			float4 interpolatedRay : TEXCOORD2; //存储插值后的像素向量
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

			// Unity 中，纹理坐标的(0, 0) 点对应了左下角，而(1, 1) 点对应了右上角。
			//我们据此来判断该顶点对应的索引，这个对应关系和我们在脚本中对 frustumCorners赋值顺序是一致的
			int index = 0;
			if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
				index = 0;
			}
			else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
				index = 1;
			}
			else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
				index = 2;
			}
			else {
				index = 3;
			}

			//例如 DirectX、Metal 这样的平台，左上角对应了(0, 0) 点
			//同时处理多张渲染纹理 + 抗锯齿，此时需要对DirectX这样的平台处理翻转问题（称作平台差异化处理）
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				index = 3 - index;
			#endif

			//最后，使用索引值获取_FrustumCornersRay中对应的行作为该顶点的interpolatedRay值
			o.interpolatedRay = _FrustumCornersRay[index];

			return o;
		}
		//尽管我们这里使用了很多判断语句，但由于屏幕后处理所用的模型是一个四边形网格，只包含
		//4个顶点，因此这些操作不会对性能造成很大影响

		fixed4 frag(v2f i) : SV_Target{
			//视角空间下的线性深度值（SAMPLE_DEPTH_TEXTURE+ LinearEyeDepth）
			float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
			//世界空间下的位置 = 世界空间下的摄像机的位置 + 视角空间下的线性深度值 * 该像素的interpolatedRay值（顶点着色器输出并插值后得到的射线，包含该像素到摄像机的方向、距离信息）
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;

			//以下是 基于高度的雾效模拟
			float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);
			fogDensity = saturate(fogDensity * _FogDensity);

			fixed4 finalColor = tex2D(_MainTex, i.uv);
			finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);

			return finalColor;
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

//本节介绍的使用深度纹理重建像素的世界坐标的方法是非常有用的。但需要注意的是，这里
//的实现是基于摄像机的投影类型是透视投影的前提下。如果需要在正交投影的情况下重建世界坐
//标，需要使用不同的公式