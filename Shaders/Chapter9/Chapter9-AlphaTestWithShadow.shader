//漫反射光照模型 (逐片元)（不含高光反射） + 主纹理 + 透明度测试 

Shader "Unity Shaders Book/Chapter 9/Alpha Test With Shadow"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1) //配合主纹理 控制漫反射、环境光
        _MainTex("Main Tex", 2D) = "white"{}
        _Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5 //用于决定我们调用 clip 进行透明度测试时使用的判断条件
    }
    SubShader
    {
        Tags {"Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout"}
        //AlphaTest:Unity定义的渲染队列，需要透明度测试的物体使用该队列
        //IgnoreProjector 设置为 True, 这意味着这个 Shader 不会受到投影器 (Projectors) 的影响
        //RenderType标签可以让Unity把这个Shader归入到提前定义的组（TransparentCutout组）中，
        //以指明该shader是一个使用了透明度测试的shader。RenderType标签通常被用于着色器替换功能。

        Pass
        {
            Tags { "LightMode" = "ForwardBase" } //前向渲染

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc" // for _LightColor0
            #include "AutoLight.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; //不用在Properties声明
            fixed _Cutoff;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
                SHADOW_COORDS(3) // 于我们已经占用了3个插值寄存器（使用 TEXCOORDO TEXCOORDl
                    //TEXCOORD2 修饰的变量），因此 SHADOW_COORDS 中传入的参数是3 这意味着，阴影纹理
                    //坐标将占用第四个插值寄存器 TEXCOORD
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);

                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex, i.uv);

                //Alpha Test
                clip(texColor.a - _Cutoff);
                //Equal to
                //if (texColor.a - _Cutoff < 0.0) {
                //    discard; //剔除该片元
                //}

                // 漫反射系数 / 也叫反射率 (会影响环境光、漫反射光)(在漫反射项中代替了_diffuse)
                fixed3 albedo = texColor.rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                return fixed4(ambient + diffuse, 1.0);
            }

            ENDCG
        }
    }

    //FallBack "VertexLit" //将使用内置的 VertexLit 中提供的ShadowCaster 来投射阴影，而这个 Pass 中并没有进行任何透明度测试的计算，

    FallBack "Transparent/Cutout/VertexLit"
    //这不仅能够保证在我们编写的 SubShader 无法在当前显卡上工作时可以有合适的代替 Shader, 
    //还可以保证使用透明度测试的物体可以正确地向其他物体投射阴影
}

//这样的结果仍然有一些问题，例如出现一些不应该透过光的部分。 出现这种情况的
//原因是，默认情况下把物体渲染到深度图和阴影映射纹理中仅考虑物体的正面 。但对于本例的正
//方体来说，由一些面完全背对光源 ，因此这些面的深度信息没有加入到阴映射纹理的计算中。
//为了得到正确结果，我们可以将正方体的 Mesh Renderer 组件中的 Cast Shadows 属性设置为 【Two Sided】,
// 强制 Unity 在计算阴影映射纹理时计算所有面的深度信息。