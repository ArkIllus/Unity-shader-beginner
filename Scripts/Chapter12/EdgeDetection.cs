using UnityEngine;
using System.Collections;

public class EdgeDetection : PostEffectsBase {

	public Shader edgeDetectShader;
	private Material edgeDetectMaterial = null;
	public Material material {  
		get {
			edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
			return edgeDetectMaterial;
		}  
	}

	[Range(0.0f, 1.0f)]
	public float edgesOnly = 0.0f; //用于调整边缘线强度 （=0时边缘会叠加在原渲染图像上；=1时只显示边缘，不显示原图像）

	public Color edgeColor = Color.black; //用于指定描边颜色

	public Color backgroundColor = Color.white; //用于指定背景颜色

	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			//材质可用，把参数传递给材质，再调用Graphics.Blit进行处理
			material.SetFloat("_EdgeOnly", edgesOnly);
			material.SetColor("_EdgeColor", edgeColor);
			material.SetColor("_BackgroundColor", backgroundColor);

			Graphics.Blit(src, dest, material);
		} else {
			//材质不可用，直接把原图像显示到屏幕上，不做任何处理
			Graphics.Blit(src, dest);
		}
	}
}
