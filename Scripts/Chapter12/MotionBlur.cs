using UnityEngine;
using System.Collections;

public class MotionBlur : PostEffectsBase {

	public Shader motionBlurShader;
	private Material motionBlurMaterial = null;

	public Material material {  
		get {
			motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
			return motionBlurMaterial;
		}  
	}

	//运动模糊在混合图像时使用的模糊参数：
	//值越大，运动拖尾的效果就越明显
	//为了防止拖尾效果完全替代当前帧的渲染结果，我们把它的值截取在 0.0~0.9 范围内。
	[Range(0.0f, 0.9f)]
	public float blurAmount = 0.5f;

	//保存之前图像叠加的结果
	private RenderTexture accumulationTexture;

	//我们在该脚本不运行时，即调用 OnDisable 函数时，立即销毁 accumulationTexture
	//这是因为，我们希望在下一次开始应用运动模糊时重新叠加图像。
	void OnDisable() {
		DestroyImmediate(accumulationTexture);
	}

	//OnRenderImage 在所有渲染完成后调用，以对图片进行额外的渲染
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null)
		{
			//不仅判断它是否为空，还判断它是否与当前的屏幕分辨率相等，
			//如果不满足，就说明我们需要重建一个适合于当前分辨率的accumulationTexture变量
			// Create the accumulation texture
			if (accumulationTexture == null || accumulationTexture.width != src.width || accumulationTexture.height != src.height) {
				DestroyImmediate(accumulationTexture);
				accumulationTexture = new RenderTexture(src.width, src.height, 0);
				//由于我们会自己控制该变量的销毁，∴把它的 hideFlags 设置为 HideFlags.HideAndDontSave,
				//这意味着这个变量不会显示在 Hierarchy 也不会保存到场景中。（？？？）
				accumulationTexture.hideFlags = HideFlags.HideAndDontSave;
				//我们使用当前的帧图像初始化 accumulationTexture
				Graphics.Blit(src, accumulationTexture);
			}

			// 我们调用了 accumulationTexture.MarkRestoreExpected 函数来表明我们需要进行一个渲染纹理的恢复操作。
			// 恢复操作(restore operation)发生在渲染到纹理而该纹理又没有被提前清空或销毁的情况下。
			// 在本例中，每次调用OnRenderlrnage 都需要 当前的帧图像和 accumulationTexture 中的图像混合，
			// accumulationTexture纹理不需要提前清空 因为它保存了我们之前的混合结果。
			// 大概这样可以防止Unity的warning？？？
			// We are accumulating motion over frames without clear/discard
			// by design, so silence any performance warnings from Unity
			accumulationTexture.MarkRestoreExpected();

			//将参数传递给材质
			material.SetFloat("_BlurAmount", 1.0f - blurAmount);

			//把当前的屏幕图像src 叠加到 accumulationTexture中
			Graphics.Blit (src, accumulationTexture, material); //没有指定Pass，依次调用material的shader（motionBlurShader）的所有Pass
			Graphics.Blit (accumulationTexture, dest); //把结果显示到屏幕上
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
