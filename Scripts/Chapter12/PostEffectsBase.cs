//在进行屏幕后处理之前 ，我们需要检查一系列条件是否满足，例如当前平台是否支持
//渲染纹理和屏幕特效，是否支持当前使用的 Unity Shader 等。为此，我们创建了一个用于屏幕后处理效果的基类，
//在实现各种屏幕特效时，我们只需要继承自该基类，再实现派生类中不同的操作即可。

using UnityEngine;
using System.Collections;

[ExecuteInEditMode] //使脚本的实例可以在编辑模式下执行
[RequireComponent(typeof(Camera))] //所有屏幕后处理的效果都需要绑定在某个摄像机上
public class PostEffectsBase : MonoBehaviour {

    // Called when start
    [System.Obsolete]
    protected void CheckResources() {
		bool isSupported = CheckSupport();
		// CheckSupport中使用了已过时的函数，所以要添加[System.Obsolete]

		if (isSupported == false) {
			NotSupported();
		}
	}

	// 检查当前平台是否支持 渲染纹理 和 屏幕特效
    // Called in CheckResources to check support on this platform
    [System.Obsolete]
    protected bool CheckSupport() {
		if (SystemInfo.supportsImageEffects == false || SystemInfo.supportsRenderTextures == false) {
			//SystemInfo.supportsImageEffects 和 SystemInfo.supportsRenderTextures 总是返回true，已过时，所以要添加[System.Obsolete]
			Debug.LogWarning("This platform does not support image effects or render textures.");
			return false;
		}
		
		return true;
	}

	// Called when the platform doesn't support this effect
	protected void NotSupported() {
		enabled = false;
	}

    [System.Obsolete]
    protected void Start() {
		CheckResources();
		// CheckResources中使用了已过时的函数，所以要添加[System.Obsolete]
	}

	//每个屏幕后处理效果通常都需要制定一个shader来创建一个用于处理渲染纹理的材质
	//首先检查shader的可用性，检查通过后返回一个使用该shader的材质
	// Called when need to create the material used by this effect
	protected Material CheckShaderAndCreateMaterial(Shader shader, Material material) {
		if (shader == null) {
			return null;
		}
		
		if (shader.isSupported && material && material.shader == shader)
			return material;
		
		if (!shader.isSupported) {
			return null;
		}
		else {
			material = new Material(shader);
			material.hideFlags = HideFlags.DontSave;
			if (material)
				return material;
			else 
				return null;
		}
	}
}

//一些屏幕特效可能需要更多的设置 如设置一些默认值等，可以重载 Start、CheckResources 或 CheckSupport 函数。
