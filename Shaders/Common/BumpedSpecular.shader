//Blinn-Phong 光照模型 (逐片元)（有高光反射项） + 主纹理 + 法线纹理(在世界空间下进行光照计算) + 光照衰减和阴影（UNITY_LIGHT_ATTENUATION）

//使用法线纹理normal map来 实现凹凸映射bump mapping。

Shader "Unity Shaders Book/Common/Bumped Specular"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1) //配合主纹理 控制漫反射、环境光
        _MainTex("Main Tex", 2D) = "white"{} //主纹理
        _BumpMap("Normal Map", 2D) = "bump" {} //法线纹理
        _BumpScale("Bump Scale", Float) = 1.0
        //_SpecularMask("Specular Mask", 2D) = "white" {} //遮罩纹理
        //_SpecularScale("Specular Scale", Float) = 1.0
        //_Specular("Specular", Color) = (1, 1, 1, 1) //配合遮罩纹理 控制高光
        _Specular("Specular Color", Color) = (1, 1, 1, 1) //控制高光
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        //分类：不透明    
        //渲染队列：默认（2000）（大多数物体。不透明物体。）
        Tags {"RenderType"="Opaque" "Queue"="Geometry"}

        Pass //处理最亮的平行光
        {
            Tags { "LightMode" = "ForwardBase" } //前向渲染

            CGPROGRAM

            #pragma multi_compile_fwdbase
            //该指令可以保证我们在Shader中使用光照衰减等光照变量可以被正确赋值。这是不可缺少的。
            
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc" // for _LightColor0
            #include "AutoLight.cginc" //for 计算阴影时所用的宏

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; // scale=.xy translation=.zw
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            //sampler2D _SpecularMask;
            //float _SpecularScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; //顶点的切线方向，需要使用tangent.w分量来决定副切线的方向性。
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0; // xy分量=_MainTex的纹理坐标，zw分量=_BumpMap的纹理坐标
                                       // 片元着色器中使用纹理坐标进行纹理采样                    
                //从切线空间到世界空间的变换矩阵：
                //【1个插值寄存器最多只能存储 float4 大小的变量】
                // ∴对于矩阵这样的变我们可以把它们按行拆成多个变扯再进行存储
                //对方向矢量的变换需要3x3的矩阵，把每行分别存到下面三个float4的xyz分量中
                //把世界空间下的顶点位置存在这三个float4的w分量中
                float4 TtoW0: TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                SHADOW_COORDS(4) //这个宏 声明一个用于对阴影纹理采样的坐标。
                                 //实际上就是声明了 一个名为_ShadowCoord 的阴影纹理坐标变量
                                 //阴影纹理/坐标将占用第四个插值寄存器 TEXCOORD
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                //TANGENT_SPACE_ROTATION; //得到从模型空间到切线空间的变换矩阵rotation 
                //这行代码应该是用于切线空间的法线纹理吧？放这里完全没卵用。但是源码里有这一行，意义不明。。。

                //世界空间的
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal); //法线
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz); //切线
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; //副切线

                /*
                //计算世界空间to切线空间矩阵的原理
                切线空间为子空间（c），世界空间为父空间（p），套用M_c_to_p的公式即可得到：【按列排列】
                float4x4 tangentToWorld = float4x4(worldTangent.x, worldBinormal.x, worldNormal.x, 0.0,
                                                   worldTangent.y, worldBinormal.y, worldNormal.y, 0.0,
                                                   worldTangent.z, worldBinormal.z, worldNormal.z, 0.0,
                                                   0.0,            0.0,             0.0,           1.0);
                // The matrix that transforms from world space to tangent space is inverse of tangentToWorld
                再求个逆
                float3x3 worldToTangent = inverse(tangentToWorld);
                */

                //切线空间to世界空间的变换矩阵是正交矩阵
                //把世界空间下切线方向，副切线方向和法线方向【按行排列】来得到从世界空间到切线空间的变换矩阵
                //wToT = the inverse of tToW = the transpose of tToW as long as tToW is an orthogonal matrix.
                //float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal); 这么写好像是按列排？所以不对？？

                //但这里【把tangentToWorld分成三行存储】
                //w分量存worldPos
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                TRANSFER_SHADOW(o); //这个宏用于在顶点着色器中计算v2f中声明的阴影纹理坐标。
                                    //会把顶点坐标从模型空间变换到光源空间后存储到 _ShadowCoord中

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);

                // _WorldSpaceLightPos0.xyz：
                //如果是平行光，表示平行光的方向
                //如果是其他光，表示光源的位置
                //#ifdef USING_DIRECTIONAL_LIGHT
                //  fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                //#else
                //  fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - worldPos.xyz);
                //#endif
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));

                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                // 法线
                // 1.先获取【切线空间】中的法线
                fixed3 normal = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                normal.xy *= _BumpScale;
                normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
                // 2.Transfer法线from切线空间to世界空间（第1、2步共用一个变量normal）
                normal = normalize(half3(dot(i.TtoW0.xyz, normal), dot(i.TtoW1.xyz, normal), dot(i.TtoW2.xyz, normal)));

                // 我们使用采样结果和颜色属性_Color 的乘积来作为材质的反射率albedo
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(normal, worldLightDir));

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(normal, worldHalfDir)), _Gloss);

                //将光照衰减和阴影值相乘后的结果存储到第一参数中。
                UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

                //return fixed4(ambient + diffuse + specular, 1.0);
                return fixed4(ambient + (diffuse + specular) * atten, 1.0);
            }

            ENDCG
        }

        Pass //处理除最亮的平行光以外的其他光源
        {
            Tags { "LightMode" = "ForwardAdd" }

            //【注意】需要开启和设置混合模式
            Blend One One
            //Blend SrcAlpha One
            //因为我们希望Additional Pass计算得到的光照结果可以在帧缓存中与之前的光照结果进行叠加。
            //如果没有Blend命令，Additional Pass会直接覆盖掉之前的光照结果。
            //这里我们选择的混合系数是Blend One One
            //这不是必需的 我们可以设置成 Unity 支持的任何混合系数。常见的还有 Blend SrcAlpha One

            CGPROGRAM

            #pragma multi_compile_fwdadd

            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Lighting.cginc" // for _LightColor0
            #include "AutoLight.cginc" //for 计算阴影时所用的宏

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; // scale=.xy translation=.zw
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            //sampler2D _SpecularMask;
            //float _SpecularScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; //顶点的切线方向，需要使用tangent.w分量来决定副切线的方向性。
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0; // xy分量=_MainTex的纹理坐标，zw分量=_BumpMap的纹理坐标
                                       // 片元着色器中使用纹理坐标进行纹理采样                    
                //从切线空间到世界空间的变换矩阵：
                //【1个插值寄存器最多只能存储 float4 大小的变量】
                // ∴对于矩阵这样的变我们可以把它们按行拆成多个变扯再进行存储
                //对方向矢量的变换需要3x3的矩阵，把每行分别存到下面三个float4的xyz分量中
                //把世界空间下的顶点位置存在这三个float4的w分量中
                float4 TtoW0: TEXCOORD1;
                float4 TtoW1 : TEXCOORD2;
                float4 TtoW2 : TEXCOORD3;
                SHADOW_COORDS(4) //这个宏 声明一个用于对阴影纹理采样的坐标。
                                 //实际上就是声明了 一个名为_ShadowCoord 的阴影纹理坐标变量
                                 //阴影纹理/坐标将占用第四个插值寄存器 TEXCOORD
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                //TANGENT_SPACE_ROTATION; //得到从模型空间到切线空间的变换矩阵rotation 
                //这行代码应该是用于切线空间的法线纹理吧？放这里完全没卵用。但是源码里有这一行，意义不明。。。

                //世界空间的
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal); //法线
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz); //切线
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; //副切线

                /*
                //计算世界空间to切线空间矩阵的原理
                切线空间为子空间（c），世界空间为父空间（p），套用M_c_to_p的公式即可得到：【按列排列】
                float4x4 tangentToWorld = float4x4(worldTangent.x, worldBinormal.x, worldNormal.x, 0.0,
                                                   worldTangent.y, worldBinormal.y, worldNormal.y, 0.0,
                                                   worldTangent.z, worldBinormal.z, worldNormal.z, 0.0,
                                                   0.0, 0.0, 0.0, 1.0);
                // The matrix that transforms from world space to tangent space is inverse of tangentToWorld
                再求个逆
                float3x3 worldToTangent = inverse(tangentToWorld);
                */

                //切线空间to世界空间的变换矩阵是正交矩阵
                //把世界空间下切线方向，副切线方向和法线方向【按行排列】来得到从世界空间到切线空间的变换矩阵
                //wToT = the inverse of tToW = the transpose of tToW as long as tToW is an orthogonal matrix.
                //float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal); 这么写好像是按列排？所以不对？？

                //但这里【把tangentToWorld分成三行存储】
                //w分量存worldPos
                o.TtoW0 = float4(worldTangent.x, worldBinormal.x, worldNormal.x, worldPos.x);
                o.TtoW1 = float4(worldTangent.y, worldBinormal.y, worldNormal.y, worldPos.y);
                o.TtoW2 = float4(worldTangent.z, worldBinormal.z, worldNormal.z, worldPos.z);

                TRANSFER_SHADOW(o); //这个宏用于在顶点着色器中计算v2f中声明的阴影纹理坐标。
                                    //会把顶点坐标从模型空间变换到光源空间后存储到 _ShadowCoord中

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);

                // _WorldSpaceLightPos0.xyz：
                //如果是平行光，表示平行光的方向
                //如果是其他光，表示光源的位置
                //#ifdef USING_DIRECTIONAL_LIGHT
                //  fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                //#else
                //  fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - worldPos.xyz);
                //#endif
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(worldPos));

                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                // 法线
                // 1.先获取【切线空间】中的法线
                fixed3 normal = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                normal.xy *= _BumpScale;
                normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
                // 2.Transfer法线from切线空间to世界空间（第1、2步共用一个变量normal）
                normal = normalize(half3(dot(i.TtoW0.xyz, normal), dot(i.TtoW1.xyz, normal), dot(i.TtoW2.xyz, normal)));

                // 我们使用采样结果和颜色属性_Color 的乘积来作为材质的反射率albedo
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                //不包含环境光项
                //fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(normal, worldLightDir));

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(normal, worldHalfDir)), _Gloss);

                //将光照衰减和阴影值相乘后的结果存储到第一参数中。
                UNITY_LIGHT_ATTENUATION(atten, i, worldPos);

                //不包含环境光项
                //return fixed4(ambient + diffuse + specular, 1.0);
                //return fixed4(ambient + (diffuse + specular) * atten, 1.0);
                return fixed4((diffuse + specular) * atten, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}