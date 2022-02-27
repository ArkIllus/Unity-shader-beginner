//漫反射光照模型 (逐片元)（不含高光反射） + 主纹理 + 透明度混合

Shader "Unity Shaders Book/Chapter 8/Alpha Blend"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1) //配合主纹理 控制漫反射、环境光
        _MainTex("Main Tex", 2D) = "white"{}
        _AlphaScale("Alpha Scale", Range(0, 1)) = 1 //在透明纹理的基础上 手动控制透明程度
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        //Transparent:Unity定义的渲染队列，需要透明度混合的物体使用该队列
        //IgnoreProjector 设置为 True, 这意味着这个 Shader 不会受到投影器 (Projectors) 的影响
        //RenderType标签可以让Unity把这个Shader归入到提前定义的组（Transparent组）中，
        //以指明该shader是一个使用了透明度混合的shader。RenderType标签通常被用于着色器替换功能。

        Pass
        {
            Tags { "LightMode" = "ForwardBase" } //前向渲染

            ZWrite Off //关闭深度写入
            Blend SrcAlpha OneMinusSrcAlpha //【开启】并【设置】该Pass的混合模式
            //将源颜色（该片元着色器产生的颜色）的混合因子设为 SrcAlpha, 
            //把目标颜色（已经存在于颜色缓冲中的颜色）的混合因子设为OneMinusSrcAlpha
            //混合后的新颜色：
            //DstColor_new = SrcAlpha * SrcColor + (1-SrcAlpha) * DstColor_old

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc" // for _LightColor0

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; //不用在Properties声明
            fixed _AlphaScale;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                //float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
                //float3 tangentLightDir : TEXCOORD1;
                //float3 tangentViewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);

                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex, i.uv);
                
                // 漫反射系数 / 也叫反射率 (会影响环境光、漫反射光)(在漫反射项中代替了_diffuse)
                fixed3 albedo = texColor.rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                //return fixed4(ambient + diffuse, 1.0);
                // 使用主纹理的Alpha通道值 和 _AlphaScale 相乘 作为输出的透明度
                return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
            }

            ENDCG
        }
    }
    //FallBack "Transparent/Cutout/VertexLit"
    FallBack "Transparent/VertexLit"
}

//当模型本身有复杂的遮挡关系或是包含了复杂的非凸网格的时候，
//就会有各种各样因为【排序错误】而产生的错误的透明效果。
//这都是由于我们【关闭了深度写入】造成的，因为这样我们就无法对模型进行像素级别的深度排序。
//
//8.1 节中我们提到了一种解决方法是分割网格，从而可以得到 个“质量优等”的网格。
//但是很多情况下这往往是不切实际的。
//
//这时，我们可以想办法重新利用深度写入，让模型可以像半透明物体那样进行淡入淡出。
//这就是我们下面要讲的内容。