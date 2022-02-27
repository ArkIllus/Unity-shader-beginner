using UnityEngine;
using System.Collections;

public class EdgeDetectNormalsAndDepth : PostEffectsBase {

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

	public float sampleDistance = 1.0f; //用于控制对深度＋法线纹理采样时 ，使用的采样距离。从视觉上来看，sampleDistance 值越大，描边越宽。

	public float sensitivityDepth = 1.0f; //会影响当邻域的深度值相差多少时，会被认为存在一条边界

	public float sensitivityNormals = 1.0f; //会影响当邻域的法线值相差多少时，会被认为存在一条边界

	//这里省略了摄像机的Camera组件，所以后面直接GetComponent<Camera>()了

	void OnEnable() {
		GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals; //生成深度+法线纹理
	}

	[ImageEffectOpaque] //在不透明的Pass执行完毕后立即调用该函数。因为这里我们只希望对不透明物体描边，对透明物体不描边。
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			//材质可用，把参数传递给材质，再调用Graphics.Blit进行处理
			material.SetFloat("_EdgeOnly", edgesOnly);
			material.SetColor("_EdgeColor", edgeColor);
			material.SetColor("_BackgroundColor", backgroundColor);
			material.SetFloat("_SampleDistance", sampleDistance);
			material.SetVector("_Sensitivity", new Vector4(sensitivityNormals, sensitivityDepth, 0.0f, 0.0f)); //把2个float合并到一个Vector4的前2个分量中

			Graphics.Blit(src, dest, material);
		} else {
			//材质不可用，直接把原图像显示到屏幕上，不做任何处理
			Graphics.Blit(src, dest);
		}
	}
}
