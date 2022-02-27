using UnityEngine;
using System.Collections;

public class GaussianBlur : PostEffectsBase {

	public Shader gaussianBlurShader;
	private Material gaussianBlurMaterial = null;

	public Material material {  
		get {
			gaussianBlurMaterial = CheckShaderAndCreateMaterial(gaussianBlurShader, gaussianBlurMaterial);
			return gaussianBlurMaterial;
		}  
	}

	// 模糊迭代次数（次数越多，越模糊）
	// Blur iterations - larger number means more blur.
	[Range(0, 4)]
	public int iterations = 3;
	
	// 调节模糊范围的参数（迭代次数越多，模糊范围越大）
	// Blur spread for each iteration - larger value means more blur
	[Range(0.2f, 3.0f)]
	public float blurSpread = 0.6f;

	// 缩放系数（中间渲染纹理相比屏幕纹理缩小）
	// downSample 越大，需要处理的像素数越少，同时也能进一步提高模糊程度，但过大的downSample可能会使图像像素化
	[Range(1, 8)]
	public int downSample = 2;

	/// 1st edition: just apply blur 仅仅是高斯模糊
//	void OnRenderImage(RenderTexture src, RenderTexture dest) {
//		if (material != null) {
//			int rtW = src.width;
//			int rtH = src.height;
//			// 利用 RenderTexture GetTemporary 函数分配了一块与屏幕图像大小相同的中间缓冲区
//			// 存储第一个Pass执行完毕后得到的模糊结果
//			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
//
//			// 调用shader的第一个（数字0）Pass，即使用竖直方向的一维高斯核进行滤波，
//			// 对src进行处理，并将结果存储在buffer中
//			// Render the vertical pass
//			Graphics.Blit(src, buffer, material, 0);
//			// 调用shader的第二个（数字1）Pass，即使用水平方向的一维高斯核进行滤波，
//			// 对buffer进行处理，并将结果存储在目标渲染纹理dest中，然后显示到屏幕上
//			// Render the horizontal pass
//			Graphics.Blit(buffer, dest, material, 1);
//
//			// 最后还需要释放之前分配的缓存
//			RenderTexture.ReleaseTemporary(buffer);
//		} else {
//			Graphics.Blit(src, dest);
//		}
//	} 

	/// 2nd edition: scale the render texture 利用缩放对图像进行降采样，从而减少需要处理的像素个数
//	void OnRenderImage (RenderTexture src, RenderTexture dest) {
//		if (material != null) {
//			int rtW = src.width/downSample;
//			int rtH = src.height/downSample;
//			// 使用了小于原屏幕分辨率的中间缓冲区
//			RenderTexture buffer = RenderTexture.GetTemporary(rtW, rtH, 0);
//			// 并将该临时渲染纹理的滤波模式设置为双线性！！！
//			// 这样，在调用第一个 Pass 时，我们需要处理的像素个数就是原来的几分之一。（？）
//			buffer.filterMode = FilterMode.Bilinear;
//
//			// Render the vertical pass
//			Graphics.Blit(src, buffer, material, 0);
//			// Render the horizontal pass
//			Graphics.Blit(buffer, dest, material, 1);
//
//			RenderTexture.ReleaseTemporary(buffer);
//		} else {
//			Graphics.Blit(src, dest);
//		}
//	}

	//OnRenderImage 在所有渲染完成后调用，以对图片进行额外的渲染
	/// 3rd edition: use iterations for larger blur 利用缩放+迭代次数
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			int rtW = src.width/downSample;
			int rtH = src.height/downSample;

			// 定义了第一个缓存 buffer0 （小于原屏幕分辨率）
			RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			// 并将该临时渲染纹理的滤波模式设置为双线性！！！
			buffer0.filterMode = FilterMode.Bilinear;

			// 把 src 中的图像缩放后存储到 bufferO 中
			Graphics.Blit(src, buffer0);

			for (int i = 0; i < iterations; i++) {
				material.SetFloat("_BlurSize", 1.0f + i * blurSpread); // 每次迭代，模糊范围逐渐增大

				// 初次定义（i=0）或重新分配（i>=1）第二个缓存 buffer1 （小于原屏幕分辨率）
				RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

				// 调用shader的第一个（数字0）Pass，即使用竖直方向的一维高斯核进行滤波
				// 输入=buffer0 输出=buffer1
				// Render the vertical pass
				Graphics.Blit(buffer0, buffer1, material, 0);

				// 释放buffer0，把buffer1结果存到buffer0中，重新分配buffer1
				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
				buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);

				// 调用shader的第二个（数字1）Pass，即使用水平方向的一维高斯核进行滤波
				// 输入=buffer0 输出=buffer1
				// Render the horizontal pass
				Graphics.Blit(buffer0, buffer1, material, 1);

				// 释放buffer0，把buffer1结果存到buffer0中
				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
			}

			// 最后，buffer0将存储最终的图像，把buffer0结果存储在目标渲染纹理dest中，然后显示到屏幕上
			Graphics.Blit(buffer0, dest);
			// 释放buffer0
			RenderTexture.ReleaseTemporary(buffer0);
			// Q：那咋不释放buffer1呢？？？ A：答案是buffer1是for循环中的局部变量，出了作用域自动释放
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
