// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 10/Glass Refraction" {
	Properties{
		_MainTex("Main Tex", 2D) = "white" {} //玻璃的材质纹理
		_BumpMap("Normal Map", 2D) = "bump" {} //玻璃的法线纹理
		_Cubemap("Environment Cubemap", Cube) = "_Skybox" {} //模拟反射的环境纹理
		_Distortion("Distortion", Range(0, 100)) = 10 //控制模拟折射时图像的扭曲程度，为0时没有扭曲
		_RefractAmount("Refract Amount", Range(0.0, 1.0)) = 1.0 //控制折射程度，为0时只包含反射效果 为1时只包括折射效果
	}
	SubShader{
		//分类：不透明 （着色器替换......）
		//渲染队列：透明 （可以确保该物体渲染时，其他所有不透明物体都已经被渲染到屏幕上了，否则就可能无法正确得到“透过玻璃看到的图像”）
		// We must be transparent, so other objects are drawn before this one.
		Tags { "Queue" = "Transparent" "RenderType" = "Opaque" }

		// 通过GrabPass定义了一个抓取屏幕图像的Pass，被抓取得到的屏幕图像将被存入_RefractionTex纹理中
		// This pass grabs the screen behind the object into a texture.
		// We can access the result in the next pass as _RefractionTex
		GrabPass { "_RefractionTex" }

		Pass {
			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _BumpMap;
			float4 _BumpMap_ST;
			samplerCUBE _Cubemap;
			float _Distortion;
			fixed _RefractAmount;
			sampler2D _RefractionTex;
			float4 _RefractionTex_TexelSize; //该纹理的纹素大小

			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 tangent : TANGENT;
				float2 texcoord: TEXCOORD0;
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float4 scrPos : TEXCOORD0;
				float4 uv : TEXCOORD1;
				float4 TtoW0 : TEXCOORD2;
				float4 TtoW1 : TEXCOORD3;
				float4 TtoW2 : TEXCOORD4;
			};

			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

				o.scrPos = ComputeGrabScreenPos(o.pos);
				//在进行了必要的顶点坐标变换后，通过调用内置的 ComputeGrabScreenPos 函数来得到对应被抓取的屏幕图像的采样坐标。

				o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

				float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
				fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz);
				fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w;

				o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
				o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
				o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

				return o;
			}

			fixed4 frag(v2f i) : SV_Target {
				float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);
				fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

				// 切线空间下的法线方向
				// Get the normal in tangent space
				fixed3 bump = UnpackNormal(tex2D(_BumpMap, i.uv.zw));

				// 切线空间下的法线方向和_Distortion属性、_RefractionTex_TexelSize对屏幕图像的采样坐标进行偏移
				// Compute the offset in tangent space
				float2 offset = bump.xy * _Distortion * _RefractionTex_TexelSize.xy;
				i.scrPos.xy = offset * i.scrPos.z + i.scrPos.xy;
				// 对srcPos透视除法得到真正的屏幕坐标，在使用该坐标对抓取的屏幕图像_RefractionTex进行采样，得到模拟的折射颜色
				fixed3 refrCol = tex2D(_RefractionTex, i.scrPos.xy / i.scrPos.w).rgb;

				// 世界空间下的法线方向
				// Convert the normal to world space
				bump = normalize(half3(dot(i.TtoW0.xyz, bump), dot(i.TtoW1.xyz, bump), dot(i.TtoW2.xyz, bump)));
				fixed3 reflDir = reflect(-worldViewDir, bump);
				// 使用反射方向对 Cubemap 进行采样，并把结果和主纹理颜色相乘后得到反射颜色
				//主纹理颜色
				fixed4 texColor = tex2D(_MainTex, i.uv.xy);
				//反射颜色
				fixed3 reflCol = texCUBE(_Cubemap, reflDir).rgb * texColor.rgb;

				//使用_RefractAmount混合反射颜色和折射颜色
				//_RefractAmount控制折射程度，为0时只包含反射效果 为1时只包括折射效果
				fixed3 finalColor = reflCol * (1 - _RefractAmount) + refrCol * _RefractAmount;

				return fixed4(finalColor, 1);
			}

			ENDCG
		}
	}

	FallBack "Diffuse"
}

// 这节没仔细看，基本是CV了一遍