Shader "Unity Shaders Book/Chapter 14/Toon Shading"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1) // white
        _MainTex ("Main Texture", 2D) = "white" {}
        _Ramp ("Ramp Texture", 2D) = "white" {}
        _Outline ("Outline", Range(0, 1)) = 0.1 //控制轮廓线宽度
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1) //轮廓线颜色 black
        _Specular ("Specular Color", Color) = (1, 1, 1, 1) // white
        _SpecularScale ("Specular Scale", Range(0, 0.1)) = 0.01 //控制高光大小（后面的threshold=1-_SpecularScale，所以该参数越小，高光越小）
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        //LOD 100

        //第1个Pass：渲染背面的面片（即渲染轮廓线的Pass）
        Pass
        {
            Name "OUTLINE" //渲染轮廓线的Pass是NPR中常用的Pass

            Cull Front //剔除正面的三角形面片

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _Outline;
            fixed4 _OutlineColor;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert (a2v v)
            {
                v2f o;

                //视角（相机、观察、View）空间下的顶点和法线（MV变换）
                float4 pos = mul(UNITY_MATRIX_MV, v.vertex); //Unity建议我们改用UnityObjectToViewPos
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal); //UNITY_MATRIX_IT_MV：UNITY_MATRIX_MV的逆转置矩阵，
                                                                             //通常用于把法线从模型空间转换到视角（相机）空间

                //为了尽可能避免背面扩张后的顶点挡住正面的面片，
                //先设置法线的z分量=-0.5（？？？？？），再对其归一化后
                //再将顶点沿法线方向扩张/延伸，得到扩张/延伸后的顶点坐标。
                normal.z = -0.5;
                pos = pos + float4(normalize(normal), 0) * _Outline; //_Outline控制顶点沿法线方向扩张/延伸的程度

                //最后，再把顶点从视角（相机、观察、View）空间变换到裁剪空间（投影P变换）
                o.pos = mul(UNITY_MATRIX_P, pos);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //只需要用轮廓线颜色渲染整个背面即可
                //如果没有第2个Pass，你会看到正面是一片_OutlineColor的，_OutlineColor颜色的轮廓线已经描出来了
                return float4(_OutlineColor.rgb, 1);
            }

            ENDCG
        }

        //第2个Pass：渲染正面的面片（正常渲染）
        Pass 
        {
            Tags { "LightMode"="ForwardBase"}

            Cull Back //剔除背面

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityShaderVariables.cginc"

            //设置LightMode，#pragma指令 都是为了让Shader中的光照变量可以被正确赋值

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
            fixed4 _Specular;
            fixed _SpecularScale;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct v2f {
                float4 pos : POSITION;
                float2 uv: TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3) //这个宏将声明一个名为_ShadowCoord的阴影纹理坐标，用于阴影纹理采样
            };

            v2f vert(a2v v) {
                v2f o;

                //o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex);
                //o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                //顶点着色器中，计算世界空间下的法线方向、顶点位置
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                TRANSFER_SHADOW(o); //这个宏用于在顶点着色器中计算阴影纹理坐标_ShadowCoord。
                                    //会把顶点坐标从模型空间变换到光源空间后存储到 _ShadowCoord中

                return o;
            }

            // ambient + diffuse + specular
            fixed4 frag(v2f i) : SV_Target{ //fixed4 float4 ???
                //计算各种需要的方向矢量，记得归一化
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                fixed4 c = tex2D(_MainTex, i.uv);
                //材质的反射率albedo(用主纹理采样结果和颜色属性_Color 的乘积来作为albedo)
                fixed3 albedo = c.rgb * _Color.rgb;

                // ambient
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //将光照衰减和阴影值相乘后的结果存储到第一参数中。
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // diffuse
                // 半兰伯特(Half Lambert)光照模型
                // 把dot(n,l)的结果范围从[-1,-1]映射到[0,1]，也就是说对于模型的背光面也会有明暗变化
                fixed halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
                fixed diff = halfLambert * atten; //【这里把halfLambert和atten相乘作为最终的漫反射系数】，和之前的做法不一样（？？？）
                fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff, diff)).rgb;

                // specular（卡通风格的高光是模型上一块块分界明细的纯色区域）
                fixed spec = dot(worldNormal, worldHalfDir);
                //smoothstep + fwidth对高光区域的边界进行抗锯齿处理 
                fixed w = fwidth(spec) * 2.0; //fwidth可以把w设为邻域像素之间的近似导数值
                fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(0.0001, _SpecularScale);
                //smoothstep函数：w是一个很小的值，这里threshold=1-_SpecularScale，
                //当第三项spec-threshold<-w时，返回0，大于w时，返回1，否则在0~1之间进行插值。从而实现抗锯齿。
                //step(0.0001, _SpecularScale)是为了在_SpecularScale=0时，完全消除高光反射的光照，
                //step的第二个参数>=第一个参数则返回1，否则返回0。

                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse" //这对产生正确的阴影投射效果很重要
}
