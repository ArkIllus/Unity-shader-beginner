using UnityEngine;
using System.Collections;
using System.Collections.Generic;

[ExecuteInEditMode]
public class ProceduralTextureGeneration : MonoBehaviour {
	//声明一个材质，这个材质将使用该脚本中生成的程序纹理：
	public Material material = null;

	//声明该程序纹理使用的各种参数
	#region Material properties
	[SerializeField, SetProperty("textureWidth")]
	private int m_textureWidth = 512;
	public int textureWidth {
		get {
			return m_textureWidth;
		}
		set {
			m_textureWidth = value;
			_UpdateMaterial();
		}
	}

	[SerializeField, SetProperty("backgroundColor")]
	private Color m_backgroundColor = Color.white;
	public Color backgroundColor {
		get {
			return m_backgroundColor;
		}
		set {
			m_backgroundColor = value;
			_UpdateMaterial();
		}
	}

	[SerializeField, SetProperty("circleColor")]
	private Color m_circleColor = Color.yellow;
	public Color circleColor {
		get {
			return m_circleColor;
		}
		set {
			m_circleColor = value;
			_UpdateMaterial();
		}
	}

	[SerializeField, SetProperty("blurFactor")]
	private float m_blurFactor = 2.0f;
	public float blurFactor {
		get {
			return m_blurFactor;
		}
		set {
			m_blurFactor = value;
			_UpdateMaterial();
		}
	}
	#endregion

	//注意到，对于每个属性我们使用了 get/set 的方法，为了在面板上修改属性时仍可以执行 set 函数，
	//TODO:我们使用了一个开源插件SetProperty https ://github corn/LM SetProperty/blob master Scripts SetPropertyExample.cs 。
	//这使得当我们修改了材质属性时，可以执行 UpdateMaterial 函数来使用新的属性重新生成程序纹理。

	//为了保存生成的程序纹理，我们声明一个 Texture2D 型的纹理变量：
	private Texture2D m_generatedTexture = null;

	// Use this for initialization
	void Start () {
		if (material == null) {
			Renderer renderer = gameObject.GetComponent<Renderer>();
			if (renderer == null) {
				Debug.LogWarning("Cannot find a renderer.");
				return;
			}

			material = renderer.sharedMaterial;
		}

		_UpdateMaterial();
	}
	//在上面的代码里，我们首先检查了 material 量是否为空 ，如果为 空，就尝试从使用该脚本
	//所在的物体上得到相应的材质。完成后 ，调用_UpdateMaterial 函数来为其生成程序纹理

	private void _UpdateMaterial() {
		if (material != null) {
			m_generatedTexture = _GenerateProceduralTexture();
			material.SetTexture("_MainTex", m_generatedTexture);
		}
	}
	//它确保 material 不为空，然后调用_GenerateProceduralTexture 函数来生成一张程序纹理，并赋_ generated Texture 量。
	//完成后 ，利用 Material.SetTexture 函数把生成的纹理赋给材质。
	//材质/material 中需要有一个名为_MainTex 的纹理属性。

	private Color _MixColor(Color color0, Color color1, float mixFactor) {
		Color mixColor = Color.white;
		mixColor.r = Mathf.Lerp(color0.r, color1.r, mixFactor);
		mixColor.g = Mathf.Lerp(color0.g, color1.g, mixFactor);
		mixColor.b = Mathf.Lerp(color0.b, color1.b, mixFactor);
		mixColor.a = Mathf.Lerp(color0.a, color1.a, mixFactor);
		return mixColor;
	}

	private Texture2D _GenerateProceduralTexture() {
		Texture2D proceduralTexture = new Texture2D(textureWidth, textureWidth);

		// The interval between circles
		float circleInterval = textureWidth / 4.0f;
		// The radius of circles
		float radius = textureWidth / 10.0f;
		// The blur factor
		float edgeBlur = 1.0f / blurFactor;

		for (int w = 0; w < textureWidth; w++) {
			for (int h = 0; h < textureWidth; h++) {
				// Initalize the pixel with background color
				Color pixel = backgroundColor;

				// Draw nine circles one by one
				for (int i = 0; i < 3; i++) {
					for (int j = 0; j < 3; j++) {
						// Compute the center of current circle
						Vector2 circleCenter = new Vector2(circleInterval * (i + 1), circleInterval * (j + 1));

						// Compute the distance between the pixel and the center
						float dist = Vector2.Distance(new Vector2(w, h), circleCenter) - radius;

						// Blur the edge of the circle
						Color color = _MixColor(circleColor, new Color(pixel.r, pixel.g, pixel.b, 0.0f), Mathf.SmoothStep(0f, 1.0f, dist * edgeBlur));

						// Mix the current color with the previous color
						pixel = _MixColor(pixel, color, color.a);
					}
				}

				proceduralTexture.SetPixel(w, h, pixel);
			}
		}

		proceduralTexture.Apply();

		return proceduralTexture;
	}
	//代码首先初始化 维纹理，并且提前计算了 些生成纹理时需要的变队。然后，使用了
	//个两层的嵌套循环遍历纹理中的每个像素，并在纹理七依次绘制 个圆形 。最后，调用
	//Texture2D.Apply 函数来强制把像素值写入纹理中，并返回该程序纹理
}

// 这节没仔细看，基本是CV了一遍
