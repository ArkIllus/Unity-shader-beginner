Shader "Unity Shaders Book/Chapter 13/Edge Detection Normals And Depth" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_EdgeOnly("Edge Only", Float) = 1.0
		_EdgeColor("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor("Background Color", Color) = (1, 1, 1, 1)
		_SampleDistance("Sample Distance", Float) = 1.0
		_Sensitivity("Sensitivity", Vector) = (1, 1, 1, 1) //x,y分量分别对应深度值、法线值的Sensitivity。z,w分量=0无用
		//在OnRenderImage中被设置
	}
	SubShader {
		//使用CGINCLUDE来组织代码
		CGINCLUDE
		
		#include "UnityCG.cginc"

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		fixed _EdgeOnly;
		fixed4 _EdgeColor;
		fixed4 _BackgroundColor;
		float _SampleDistance;
		half4 _Sensitivity;

		sampler2D _CameraDepthNormalsTexture; //Unity传递给我们的深度纹理（没有在 Properties 中声明）

		struct v2f {
			float4 pos : SV_POSITION;
			//half2 uv : TEXCOORD0;
			//half2 uv_depth : TEXCOORD1; //专门用于对深度纹理采样的纹理坐标
			half2 uv[5] : TEXCOORD0;
		};

		//通过把计算采样纹理坐标的代码从片元着色器中转移到顶点着色器中，可以减少运算，提高性能。
		//由于从顶点着色器到片元着色器的插值是线性的，因此这样的转移并不会影响纹理坐标的计算结果。
		v2f vert(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);

			half2 uv = v.texcoord;
			o.uv[0] = uv;

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				uv.y = 1 - uv.y;
			#endif

			o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1, 1) * _SampleDistance; //右下
			o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1, -1) * _SampleDistance; //左上
			o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 1) * _SampleDistance; //左下
			o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1, -1) * _SampleDistance; //右上

			return o;
		}

		half CheckSame(half4 center, half4 sample) {
			//值得注意的是，【【这里我们并没有解码得到真正的法线值】】，而是直接使用了xy分量。
			//这是因为我们只需要比较两个采样值之间的差异度，而并不需要知道它们真正的法线值。（？？？）
			half2 centerNormal = center.xy; //并没有用DecodeViewNormalStereo解码法线信息
			float centerDepth = DecodeFloatRG(center.zw); //DecodeFloatRG 解码深度法线纹理中的深度信息
			half2 sampleNormal = sample.xy;
			float sampleDepth = DecodeFloatRG(sample.zw);

			half2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x; //使用sensitivityNormals（默认=1）修正
			int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1; //法线的x分量和y分量的差异值相加<阈值1，认为2个像素足够相似 //阈值1取0.1
			float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y; //使用sensitivityDepth（默认=1）修正
			int isSameDepth = diffDepth < 0.1 * centerDepth; //深度的差异值<阈值2*中心(center)像素的深度值，认为2个像素足够相似 //阈值2取0.1

			// return:
			// 1 - if normals and depth are similar enough
			// 0 - otherwise
			return isSameNormal * isSameDepth ? 1.0 : 0.0;
		}

		fixed4 fragRobertsCrossDepthAndNormal(v2f i) : SV_Target{
			half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]); //右下
			half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]); //左上
			half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]); //左下
			half4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4]); //右上

			half edge = 1.0;

			//CheckSame函数返回值： 0-两点之间存在一条边界 1-不存在边界
			//所以下面的edge就是：只要 “左上、右下” or “左下、右上”2个检测结果中有1个检测结果是存在边界，那么就存在边界（edge=0），否则不存在（edge=1）
			edge *= CheckSame(sample1, sample2);
			edge *= CheckSame(sample3, sample4);

			fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[0]), edge);
			fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);

			return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
		}
		
		ENDCG
		
		Pass {      
			ZTest Always Cull Off ZWrite Off //屏幕后处理shader的标配 //深度测试的函数：总是通过 关闭剔除 关闭深度写入
			    	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment fragRobertsCrossDepthAndNormal
			  
			ENDCG  
		}
	} 
	FallBack Off
}

//本节实现的描边效果是基于整个屏幕空间进行的，也就是说，场景内的所有物体都会被添加描边效果。 
//但有时，我们希望只对特定的物体进行描边，例如当玩家选中场景中的某个物体后，我们想要在该物体周围添加一层描边效果。 
//这时，我们可以使用Unity提供的 Graphics.DrawMesh 或Graphics.DrawMeshNow函数把需要描边的物体再次渲染一遍（在所有不透明物体渲染完毕之后），（？？？？？？？？？？？？）
//然后再使用本节提到的边缘检测算法计算深度或法线纹理中每个像素的梯度值，判断它们是否小于某个阈值，
//如果是，就在Shader中使用clip()函数将该像素剔除掉，从而显示出原来的物体颜色。
