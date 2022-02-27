using UnityEngine;
using System.Collections;

public class BrightnessSaturationAndContrast : PostEffectsBase {

	public Shader briSatConShader; //指定的shader
	private Material briSatConMaterial; //briSatConShader创建的材质
	public Material material {  //属性 get访问briSatConMaterial
		get {
			briSatConMaterial = CheckShaderAndCreateMaterial(briSatConShader, briSatConMaterial);
			return briSatConMaterial;
		}  
	}

    [Range(0.0f, 3.0f)]
    public float brightness = 1.0f;

	[Range(0.0f, 3.0f)]
	public float saturation = 1.0f;

	[Range(0.0f, 3.0f)]
	public float contrast = 1.0f;

	//OnRenderImage 在所有渲染完成后调用，以对图片进行额外的渲染
	//会把当前渲染得到的图像存储在第一个参数src对应的源渲染纹理中 
	//通过函数中的一系列操作后 再把目标渲染纹理 即第二个参数dest对应的渲染纹理显示到屏幕上
	void OnRenderImage(RenderTexture src, RenderTexture dest) {
		//检查材质是否可用
		if (material != null) {
			//材质可用，把参数传递给材质，再调用Graphics.Blit进行处理
			material.SetFloat("_Brightness", brightness);
			material.SetFloat("_Saturation", saturation);
			material.SetFloat("_Contrast", contrast);

			Graphics.Blit(src, dest, material); //src：源纹理	dest：目标渲染纹理	material：这里是briSatConShader创建的材质
												//把src传递给material使用的shader中名为_MainTex的属性
		} else {
			//材质不可用，直接把原图像显示到屏幕上，不做任何处理
			Graphics.Blit(src, dest);
		}
	}
}
