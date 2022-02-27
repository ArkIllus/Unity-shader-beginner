using UnityEngine;
using System.Collections;

//由于 Bloom 效果是建立在高斯模糊的基础上的，因此脚本中提供的参数 12.4 节中几乎完全一样
//只增加了一个新的参数 luminanceThreshold 来控制提取较亮区域时使用的阙值大小

public class Bloom : PostEffectsBase {

	public Shader bloomShader;
	private Material bloomMaterial = null;
	public Material material {  
		get {
			bloomMaterial = CheckShaderAndCreateMaterial(bloomShader, bloomMaterial);
			return bloomMaterial;
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
	[Range(1, 8)]
	public int downSample = 2;

	// 提取较亮区域时使用的阈值大小
	// 一般亮度值不会超过1，但是开启HDR有可能超过，∴这里[0,4]范围
	[Range(0.0f, 4.0f)]
	public float luminanceThreshold = 0.6f;

	//OnRenderImage 在所有渲染完成后调用，以对图片进行额外的渲染
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			material.SetFloat("_LuminanceThreshold", luminanceThreshold);

			int rtW = src.width/downSample;
			int rtH = src.height/downSample;

			// 定义了第一个缓存 buffer0 （小于原屏幕分辨率）
			RenderTexture buffer0 = RenderTexture.GetTemporary(rtW, rtH, 0);
			// 并将该临时渲染纹理的滤波模式设置为双线性！
			buffer0.filterMode = FilterMode.Bilinear;

			// 首先，调用shader的第一个（数字0）Pass 提取图像中的较亮区域并存到buffer0中
			Graphics.Blit(src, buffer0, material, 0);
			
			// 和12.4节完全一致的高斯模糊迭代处理，只不过使用的是第2、3个Pass
			for (int i = 0; i < iterations; i++) {
				material.SetFloat("_BlurSize", 1.0f + i * blurSpread);
				
				RenderTexture buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
				
				// Render the vertical pass
				Graphics.Blit(buffer0, buffer1, material, 1);
				
				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
				buffer1 = RenderTexture.GetTemporary(rtW, rtH, 0);
				
				// Render the horizontal pass
				Graphics.Blit(buffer0, buffer1, material, 2);
				
				RenderTexture.ReleaseTemporary(buffer0);
				buffer0 = buffer1;
			}

			// 最后，将上面得到的图像和原图像混合，得到最终结果
			material.SetTexture ("_Bloom", buffer0);  
			Graphics.Blit (src, dest, material, 3);  

			RenderTexture.ReleaseTemporary(buffer0);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
