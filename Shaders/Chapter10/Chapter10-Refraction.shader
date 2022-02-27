//漫反射光照模型 (逐片元)（不含高光反射，含refraction项） + 统—管理光照衰减和阴影（使用宏） + 前向渲染（处理不同类型的光源，不再只是平行光）

//为前向渲染定义了 Base Pass 和 AdditionalPass 来处理多个光源

// 环境映射的应用：折射

Shader "Unity Shaders Book/Chapter 10/Refraction"
{
    Properties
    {
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        _RefractColor("Refraction Color",Color) = (1, 1, 1, 1) //用于控制散射颜色
        _RefractAmount("Refraction Amount",Range(0,1)) = 1 //用于控制这个材质的散射程度
        _RefractRatio("Refraction Ratio",Range(0.1, 1)) = 0.5 //入射光线所在介质的折射率和折射光线所在介质的折射率之间的比值
                                                              //如果是1，那么看起来光线就像没有发生折射，按原来的方向穿过了这个物体一样
        _Cubemap ("Refraction Cubemap", Cube) = "_Skybox" {} //用于模拟散射的环境映射纹理
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
            fixed4 _RefractColor;
            float _RefractAmount;
            fixed _RefractRatio;
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
                fixed3 worldRefr : TEXCOORD3;
                SHADOW_COORDS(4) //这个宏 声明一个用于对阴影纹理采样的坐标。
                                 //实际上就是声明了 一个名为_ShadowCoord 的阴影纹理坐标变量
                                 //阴影纹理/坐标将占用第四个插值寄存器 TEXCOORD
            };

            // 在顶点着色器中计算了该顶点处的散射方向，这是通过使用 refract 函数来实现的
			v2f vert(a2v v) {
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

				// Compute the refract dir in world space //注意负号（必须归一化）
                // refract 函数的第三个参数是 入射光线所在介质的折射率和折射光线所在介质的折射率之间的比值
				o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);

				TRANSFER_SHADOW(o); //这个宏用于在顶点着色器中计算v2f中声明的阴影纹理坐标。
                                    //会把顶点坐标从模型空间变换到光源空间后存储到 _ShadowCoord中

				return o;
			}

            // 在片元着色器中，利用散射方向来对立方体纹理采样：
			fixed4 frag(v2f i) : SV_Target{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(i.worldViewDir);

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

				// Use the refract dir in world space to access the cubemap
				//对立方体纹理的采样需要使用 CG 的 texCUBE 函数     （乘_refractColor用于控制反射颜色）
				fixed3 refraction = texCUBE(_Cubemap, i.worldRefr).rgb * _RefractColor.rgb;

                //将光照衰减和阴影值相乘后的结果存储到第一参数中。
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				// Mix the diffuse color with the refracted color
				//我们使用_refractAmount来混合(lerp函数)漫反射颜色和反射颜色（乘atten光源的光照衰减），并和环境光照相加后返回（没有高光项）
				fixed3 color = ambient + lerp(diffuse, refraction, _RefractAmount) * atten;

				return fixed4(color, 1.0);
			}

            ENDCG
	    }
	}
	FallBack "Reflective/VertexLit"
}
//在上面的计算中，我们选择在顶点着色器中计算散射方向。当然，我们也可以选择在片元着
//色器中计算，这样得到的效果更加细腻。但是，对千绝大多数人来说这种差别往往是可以忽略不
//计的，因此出于性能方面的考虑，我们选择在顶点着色器中计算散射方向。

//的。对一个透明物体来说，一种更准确的模拟方法需要计算两次折射。
//－次是当光线进入它的内部时，而另一次则是从它内部射出时。
//但是，想要在实时渲染中模拟出第二次折射方向是比较复杂的，而且仅仅模拟一次得到的效果从视觉上看起来”也挺像那么回事的”。
//正如我们之前提到的一图形学第一准则“如果它看起来是对的，那么它就是对的”。
//因此，在实时渲染中我们通常仅模拟第一次折射