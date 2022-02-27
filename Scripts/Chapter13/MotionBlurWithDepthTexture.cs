using UnityEngine;
using System.Collections;

public class MotionBlurWithDepthTexture : PostEffectsBase {

	public Shader motionBlurShader;
	private Material motionBlurMaterial = null;

	public Material material {  
		get {
			motionBlurMaterial = CheckShaderAndCreateMaterial(motionBlurShader, motionBlurMaterial);
			return motionBlurMaterial;
		}  
	}

	//需要定义一个Camera类型的变量，以获取该脚本所在的摄像机组件
	private Camera myCamera;
	public Camera camera {
		get {
			if (myCamera == null) {
				myCamera = GetComponent<Camera>();
			}
			return myCamera;
		}
	}

	//定义运动模糊时模糊图像使用的大小
	[Range(0.0f, 1.0f)]
	public float blurSize = 0.5f;

	//定义一个变量来保存上一帧摄像机的视角*投影矩阵
	private Matrix4x4 previousViewProjectionMatrix;

	//由于本例需要获取摄像机的深度纹理，在脚本的 OnEnable 函数中设置摄像机的状态
	void OnEnable() {
		camera.depthTextureMode |= DepthTextureMode.Depth; //设置摄像机的深度纹理模式（How and if camera generates a depth texture）：产生一张深度纹理
														   //这里的DepthTextureMode是一个enum

		previousViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix; //VP = P * V //调用OnEnable时初始化该变量
	}
	
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			material.SetFloat("_BlurSize", blurSize);

			//camera.worldToCameraMatrix = 当前摄像的视角矩阵（V）。
			//camera.projectionMatrix = 当前摄像的投影矩阵（P）。
			//对它们相乘后取逆，得到当前帧的视角*投影矩阵的逆矩阵，传递给材质。
			//然后我们把取逆前的结果存储在 previousViewProjectionMatrix 变量中 ，
			//以便在下一帧时传递给材质的 PreviousViewProjectionMatrix 属性
			// ....................还是不太懂？？？？？？？？？？？？？？？？？？？
			material.SetMatrix("_PreviousViewProjectionMatrix", previousViewProjectionMatrix);
			Matrix4x4 currentViewProjectionMatrix = camera.projectionMatrix * camera.worldToCameraMatrix; //VP = P * V
			Matrix4x4 currentViewProjectionInverseMatrix = currentViewProjectionMatrix.inverse;  //(VP)^-1 = (P * V)^-1
			material.SetMatrix("_CurrentViewProjectionInverseMatrix", currentViewProjectionInverseMatrix);
			previousViewProjectionMatrix = currentViewProjectionMatrix;

			Graphics.Blit (src, dest, material); //没有指定Pass，依次调用material的shader（motionBlurShader）的所有Pass，结果存到dest中
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
