//漫反射光照模型 (逐片元)（relection项代替specular项） + 光照衰减&阴影

// 环境映射的应用：反射

Shader "Unity Shaders Book/Chapter 10/Reflection"
{
    Properties
    {
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        _ReflectColor("Reflection Color",Color) = (1, 1, 1, 1) //用于控制反射颜色
        _ReflectAmount("Reflection Amount",Range(0,1)) = 1 //用于控制这个材质的反射程度
        _Cubemap ("Reflection Cubemap", Cube) = "_Skybox" {} //用于模拟反射的环境映射纹理
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
            fixed4 _ReflectColor;
            fixed _ReflectAmount;
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

				// Compute the reflect dir in world space //注意负号（不必须归一化）
				o.worldRefl = reflect(-o.worldViewDir, o.worldNormal);

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

				// Use the reflect dir in world space to access the cubemap
				//对立方体纹理的采样需要使用 CG 的 texCUBE 函数     （乘_ReflectColor用于控制反射颜色）
				fixed3 reflection = texCUBE(_Cubemap, i.worldRefl).rgb * _ReflectColor.rgb;

                //将光照衰减和阴影值相乘后的结果存储到第一参数中。
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				// Mix the diffuse color with the reflected color
				//我们使用_ReflectAmount来混合(lerp函数)漫反射颜色和反射颜色（乘atten光源的光照衰减），并和环境光照相加后返回（relection代替specular）
				fixed3 color = ambient + lerp(diffuse, reflection, _ReflectAmount) * atten;

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

//不知道为啥 我做的Cubemap有点糊。。。。。。。？？？？？？？？