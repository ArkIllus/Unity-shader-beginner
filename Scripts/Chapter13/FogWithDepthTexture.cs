using UnityEngine;
using System.Collections;

public class FogWithDepthTexture : PostEffectsBase {

	public Shader fogShader;
	private Material fogMaterial = null;

	public Material material {  
		get {
			fogMaterial = CheckShaderAndCreateMaterial(fogShader, fogMaterial);
			return fogMaterial;
		}  
	}

	//摄像机的Camera组件
	private Camera myCamera;
	public Camera camera {
		get {
			if (myCamera == null) {
				myCamera = GetComponent<Camera>();
			}
			return myCamera;
		}
	}

	//摄像机的Tranform组件
	private Transform myCameraTransform;
	public Transform cameraTransform {
		get {
			if (myCameraTransform == null) {
				myCameraTransform = camera.transform;
			}

			return myCameraTransform;
		}
	}

	[Range(0.0f, 3.0f)]
	public float fogDensity = 1.0f; //控制雾的浓度 

	public Color fogColor = Color.white; //控制雾的颜色

	public float fogStart = 0.0f; //控制雾效的起始高度
	public float fogEnd = 2.0f; //控制雾效的终止高度

	//在对象已启用（脚本的enable=true）并处于活跃状态（GameObject的Activity=true）时调用此函数
	void OnEnable() {
		camera.depthTextureMode |= DepthTextureMode.Depth; //设置摄像机的深度纹理模式：产生一张深度纹理
														   //这里的DepthTextureMode是一个enum
	}

	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (material != null) {
			//近裁剪平面的4个角对应的方向和距离的向量（距离上，经过先归一，再×摄像机到该角的距离/near。这是为了之后在shader中×“视角空间下的线性深度值”得到“世界空间下摄像机到该像素的偏移量”）
			Matrix4x4 frustumCorners = Matrix4x4.identity;

			//fov：竖直方向的视角范围
			float fov = camera.fieldOfView;
			//near：摄像机到近裁剪平面的距离（角度形式）
			float near = camera.nearClipPlane;
			//aspect：横纵比
			float aspect = camera.aspect;

			//halfHeight：半高度
			float halfHeight = near * Mathf.Tan(fov * 0.5f * Mathf.Deg2Rad);
			//toRight：起点位于近裁剪平面中心，指向摄像机正右方向的向量（直到近裁剪平面的右边界）
			Vector3 toRight = cameraTransform.right * halfHeight * aspect;
			//toTop：起点位于近裁剪平面中心，指向摄像机正上方向的向量（直到近裁剪平面的上边界）
			Vector3 toTop = cameraTransform.up * halfHeight;

			//计算近裁剪平面的4个角相对于摄像机的方向和距离的向量（距离上，经过先归一，再×摄像机到该角的距离/near。这是为了之后在shader中×“视角空间下的线性深度值”得到“世界空间下摄像机到该像素的偏移量”）
			//左上角
			Vector3 topLeft = cameraTransform.forward * near + toTop - toRight;
			float scale = topLeft.magnitude / near;

			topLeft.Normalize();
			topLeft *= scale;

			//右上角
			Vector3 topRight = cameraTransform.forward * near + toRight + toTop;
			topRight.Normalize();
			topRight *= scale;

			//左下角
			Vector3 bottomLeft = cameraTransform.forward * near - toTop - toRight;
			bottomLeft.Normalize();
			bottomLeft *= scale;

			//右下角
			Vector3 bottomRight = cameraTransform.forward * near + toRight - toTop;
			bottomRight.Normalize();
			bottomRight *= scale;

			frustumCorners.SetRow(0, bottomLeft);
			frustumCorners.SetRow(1, bottomRight);
			frustumCorners.SetRow(2, topRight);
			frustumCorners.SetRow(3, topLeft);

			//传递参数给材质
			material.SetMatrix("_FrustumCornersRay", frustumCorners);

			material.SetFloat("_FogDensity", fogDensity);
			material.SetColor("_FogColor", fogColor);
			material.SetFloat("_FogStart", fogStart);
			material.SetFloat("_FogEnd", fogEnd);

			//渲染结果显示到屏幕
			Graphics.Blit (src, dest, material);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
