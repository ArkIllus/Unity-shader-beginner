//Blinn-Phong 光照模型 (逐片元) + 主纹理 + 法线纹理(方法一：在切线空间下进行光照计算) + 遮罩纹理

//使用法线纹理normal texture来 实现凹凸映射bump mapping。
//使用遮罩纹理mask texture来 控制高光反射光照的结果。

Shader "Unity Shaders Book/Chapter 7/Mask Texture"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1) //配合主纹理 控制漫反射、环境光
        _MainTex("Main Tex", 2D) = "white"{}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Bump Scale", Float) = 1.0
        _SpecularMask("Specular Mask", 2D) = "white" {}
        _SpecularScale("Specular Scale", Float) = 1.0
        _Specular("Specular", Color) = (1, 1, 1, 1) //配合遮罩纹理 控制高光
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" } //前向渲染

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc" // for _LightColor0

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; // scale（.xy） translation（.zw）//怎么获得?????
                                //为主纹理、法线纹理、遮罩纹理定义了共同使用的缩放和平移变量_MainTex_ST
            sampler2D _BumpMap;
            float _BumpScale;
            sampler2D _SpecularMask;
            float _SpecularScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; //使用tangent.w分量来决定切线空间中的第三个坐标——副切线的方向性。
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                //float4 uv : TEXCOORD0;
                float2 uv : TEXCOORD0; //由于只有一个ST，因此纹理坐标也只有一个
                float3 tangentLightDir : TEXCOORD1; //切线空间下的
                float3 tangentViewDir : TEXCOORD2; //切线空间下的
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                // 以下代码能处理非等比缩放和非等比缩放的情况
                /*
                //计算世界空间to切线空间矩阵的原理
                切线空间为子空间（c），世界空间为父空间（p），套用M_c_to_p的公式即可得到：【按列排列】
                float4x4 tangentToWorld = float4x4(worldTangent.x, worldBinormal.x, worldNormal.x, 0.0,
                                                    worldTangent.y, worldBinormal.y, worldNormal.y, 0.0,
                                                    worldTangent.z, worldBinormal.z, worldNormal.z, 0.0,
                                                    0.0, 0.0, 0.0, 1.0);
                再求个逆
                float3x3 worldToTangent = inverse(tangentToWorld);
                */
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldNormal(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; //v.tanget.w决定方向
                //该变换矩阵是正交矩阵（仅包含平移和旋转=MVP里的视图变换）
                //把世界空间下切线方向，副切线方向和法线方向【按行排列】来得到从世界空间到切线空间的变换矩阵
                float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal);
                o.tangentLightDir = mul(worldToTangent, WorldSpaceLightDir(v.vertex));
                o.tangentViewDir = mul(worldToTangent, WorldSpaceViewDir(v.vertex));

                // 以下代码不能处理非等比缩放的情况
                // 计算rotation变换矩阵
                //
                // 方法一： 手写
                //float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) ) * v.tangent.w;
                //把模型空间下切线方向，副切线方向和法线方向按行排列来得到从模型空间到切线空间的变换矩阵rotation
                //float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
                //
                // 方法二： 内置函数
                //Or just use the built-in macro
                //TANGENT_SPACE_ROTATION;
                //
                //o.tangentLightDir = mul(rotation, normalize(ObjSpaceLightDir(v.vertex))).xyz;
                //o.tangentViewDir = mul(rotation, normalize(ObjSpaceViewDir(v.vertex))).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            { 
                //从vertex shader传过来的: l v
                fixed3 tangentLightDir = normalize(i.tangentLightDir);
                fixed3 tangentViewDir = normalize(i.tangentViewDir);
                //从法线纹理 ①采样 ②解包 ③人工修正(xy分量*_BumpScale) 获得【切线空间下的】法线: n
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                //半方向h
                fixed3 tangentHalfDir = normalize((tangentLightDir + tangentViewDir));

                //从遮罩纹理 ①采样（并取R通道） ②人工修正（*_SpecularScale）获得specularMask
                //【注意】这里取R通道（说明这个遮罩纹理把高光反射的强度存储在R通道）
                fixed specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;

                // 漫反射系数 / 也叫反射率 (会影响环境光、漫反射光)(在漫反射项中代替了_diffuse)
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                //使用albedo修正
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //使用albedo作为漫反射系数
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                //使用遮罩纹理mask texture来 控制高光反射光照的结果。
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, tangentHalfDir)), _Gloss) * specularMask;
                //fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, tangentHalfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}