//漫反射光照模型 (逐片元)（有relection项+fresnel项，无specular项） + 光照衰减&阴影

// 环境映射的应用：菲涅尔反射（使用Schlick菲涅尔近似等式）

Shader "Unity Shaders Book/Chapter 10/Fresnel"
{
    Properties
    {
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        //_ReflectColor("Reflection Color",Color) = (1, 1, 1, 1) //用于控制反射颜色
        //_ReflectAmount("Reflection Amount",Range(0,1)) = 1 //用于控制这个材质的反射程度
        //_RefractColor("Refraction Color",Color) = (1, 1, 1, 1) //用于控制散射颜色
        //_RefractAmount("Refraction Amount",Range(0,1)) = 1 //用于控制这个材质的散射程度
        //_RefractRatio("Refraction Ratio",Range(0.1, 1)) = 0.5 //入射光线所在介质的折射率和折射光线所在介质的折射率之间的比值
        //                                                      //如果是1，那么看起来光线就像没有发生折射，按原来的方向穿过了这个物体一样
        _FresnelScale("Fresnel Scale", Range(0,1)) = 0.5 //用于调整菲涅耳反射的属性
                                                         //。当我们把_FresnelScale 调节到1时，物体将完全反射 Cubemap中的图像；
                                                         //当_FresnelScale = 0 时，则是一个具有边缘光照效果的漫反射物体。
        _Cubemap ("Reflection Cubemap", Cube) = "_Skybox" {} //用于模拟散射的环境映射纹理
    }
    SubShader
    {
        //分类：不透明    渲染队列：默认（2000）（大多数物体。不透明物体。）
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry"}

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed _FresnelScale;
            samplerCUBE _Cubemap; // samplerCUBE ?????????

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                fixed3 worldViewDir : TEXCOORD2;
                fixed3 worldRefl : TEXCOORD3;
                SHADOW_COORDS(4) //这个宏 声明一个用于对阴影纹理采样的坐标。
                                 //实际上就是声明了 一个名为_ShadowCoord 的阴影纹理坐标变量
                                 //阴影纹理/坐标将占用第四个插值寄存器 TEXCOORD
            };

            // 在顶点着色器中计算了该顶点处的反射方向，这是通过使用 reflect 函数来实现的
			v2f vert(a2v v) {
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

				// Compute the refract dir in world space //注意负号（不必须归一化）
                o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);
                //o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);

				TRANSFER_SHADOW(o); //这个宏用于在顶点着色器中计算v2f中声明的阴影纹理坐标。
                                    //会把顶点坐标从模型空间变换到光源空间后存储到 _ShadowCoord中

				return o;
			}

            // 在片元着色器中，利用反射方向来对立方体纹理采样：
			fixed4 frag(v2f i) : SV_Target{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(i.worldViewDir);

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

				//// Use the refract dir in world space to access the cubemap
				////对立方体纹理的采样需要使用 CG 的 texCUBE 函数     （乘_refractColor用于控制反射颜色）
				//fixed3 refraction = texCUBE(_Cubemap, i.worldRefr).rgb * _RefractColor.rgb;
                //// Use the reflect dir in world space to access the cubemap
                ////对立方体纹理的采样需要使用 CG 的 texCUBE 函数     （乘_ReflectColor用于控制反射颜色）
                //fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb * _ReflectColor.rgb;
                // 
                //对立方体纹理的采样需要使用 CG 的 texCUBE 函数     （不再乘_ReflectColor用于控制反射颜色）
                fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb;

                //将光照衰减和阴影值相乘后的结果存储到第一参数中。
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                //计算fresnel（使用Schlick菲涅尔近似等式）
                fixed fresnel = _FresnelScale + (1 - _FresnelScale) * pow(1 - dot(worldViewDir, worldNormal), 5);

                //// Mix the diffuse color with the reflected color
                ////我们使用_ReflectAmount来混合(lerp函数)漫反射颜色和反射颜色（乘atten光源的光照衰减），并和环境光照相加后返回（relection代替specular）
                //fixed3 color = ambient + lerp(diffuse, reflection, _ReflectAmount) * atten;
				//// Mix the diffuse color with the refracted color
				////我们使用_refractAmount来混合(lerp函数)漫反射颜色和反射颜色（乘atten光源的光照衰减），并和环境光照相加后返回（没有高光项）
				//fixed3 color = ambient + lerp(diffuse, refraction, _RefractAmount) * atten;
                // 
                //使用fresnel来混合(lerp函数)漫反射颜色和反射颜色（乘atten光源的光照衰减），并和环境光照相加后返回
                //一些实现 会直接把 fresnel 和反射光照相乘后叠加到漫反射光照上模拟 【边缘光照】 效果。
                fixed3 color = ambient + lerp(diffuse, reflection, saturate(fresnel)) * atten;

				return fixed4(color, 1.0);
			}

            ENDCG
	    }
	}
	FallBack "Reflective/VertexLit"
}
//在上面的计算中，我们选择在顶点着色器中计算反射方向。当然，我们也可以选择在片元着
//色器中计算，这样得到的效果更加细腻。但是，对千绝大多数人来说这种差别往往是可以忽略不
//计的，因此出于性能方面的考虑，我们选择在顶点着色器中计算反射方向。