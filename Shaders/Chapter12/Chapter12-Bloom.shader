Shader "Unity Shaders Book/Chapter 12/Bloom" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {} //Graphics.Blit(bufferX...material...)把bufferX传递给material使用的shader中名为_MainTex的属性
        _Bloom("Bloom (RGB)", 2D) = "black" {} //在OnRenderImage中被设置
        _LuminanceThreshold("Luminance Threshold", Float) = 0.5 //在OnRenderImage中被设置
        _BlurSize("Blur Size", Float) = 1.0 //在OnRenderImage中被设置
    }
    SubShader
    {
        //使用CGINCLUDE来组织代码 目的：避免代码重复

		CGINCLUDE

		#include "UnityCG.cginc"

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _Bloom;
		float _LuminanceThreshold;
		float _BlurSize;

		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
		};

		// 提取较亮区域的 顶点着色器
		v2f vertExtractBright(appdata_img v) {
			v2f o;

			o.pos = UnityObjectToClipPos(v.vertex);

			o.uv = v.texcoord;

			return o;
		}

		fixed luminance(fixed4 color) {
			return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
		}

		// 提取较亮区域的 片元着色器
		fixed4 fragExtractBright(v2f i) : SV_Target {
			// 将采样得到的亮度值减去阈值_LuminanceThreshold, 并把结果截取到 0 - 1 范围内（∵HDR，亮度可能超过1）。
			fixed4 c = tex2D(_MainTex, i.uv);
			fixed val = clamp(luminance(c) - _LuminanceThreshold, 0.0, 1.0);

			// 把该值和原像素值相乘，得到提取后的亮部区域
			return c * val;
		}

		struct v2fBloom {
			float4 pos : SV_POSITION;
			half4 uv : TEXCOORD0;
		};

		//混合 经过“提取亮部+高斯模糊”的图像 和原图像 的顶点着色器
		v2fBloom vertBloom(appdata_img v) {
			v2fBloom o;

			o.pos = UnityObjectToClipPos(v.vertex);
			o.uv.xy = v.texcoord; //原图像的纹理坐标
			o.uv.zw = v.texcoord; //经过“提取亮部+高斯模糊”的图像的纹理坐标
            // 其实这2组纹理坐标是一毛一样的

			// 我们需要对这个纹理坐标进行平台差异化处理（详见 5.6.1 节）。
			// 特殊情况下我们需要考虑翻转问题：开启了抗锯齿并使用了渲染到纹理技术且同时处理多张渲染图像
			#if UNITY_UV_STARTS_AT_TOP //判断当前平台是否是DirectX类型的平台
			if (_MainTex_TexelSize.y < 0.0) //此类平台开启抗锯齿后，主纹理的纹素大小在竖直方向上会变成负值，即判断是否开启了抗锯齿
				o.uv.w = 1.0 - o.uv.w; //如果是，我们就需要对除主纹理外的其他纹理的采样坐标进行竖直方向上的翻转
			#endif

			return o;
		}

		//混合 经过“提取亮部+高斯模糊”的图像 和 原图像 的片元着色器
		fixed4 fragBloom(v2fBloom i) : SV_Target {
			//只需要把两张纹理的采样结果相加
			return tex2D(_MainTex, i.uv.xy) + tex2D(_Bloom, i.uv.zw);
		}

		ENDCG



        ZTest Always Cull Off ZWrite Off //屏幕后处理shader的标配
                                         //深度测试的函数：总是通过 关闭剔除 关闭深度写入

        //定义Bloom效果需要的4个Pass:。
        Pass {
                CGPROGRAM

                #pragma vertex vertExtractBright  
                #pragma fragment fragExtractBright  

                ENDCG
        }

        // 第2、3个Pass直接使用高斯模糊里的水平、竖直Pass
        // 之前已经使用NAME语义为两个 Pass 定义了它们的名字。直接通过它们的名字（需要大写）来使用该Pass。
        UsePass "Unity Shaders Book/Chapter 12/Gaussian Blur/GAUSSIAN_BLUR_VERTICAL"

        UsePass "Unity Shaders Book/Chapter 12/Gaussian Blur/GAUSSIAN_BLUR_HORIZONTAL"

        Pass{
            CGPROGRAM

            #pragma vertex vertBloom
            #pragma fragment fragBloom

            ENDCG
        }
    }
    Fallback Off
}
