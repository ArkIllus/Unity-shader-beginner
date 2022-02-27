//Blinn-Phong 光照模型 (逐片元) + 
//法线纹理(normal map)实现凹凸映射(bump mapping) 
//（方法一：在切线空间下进行光照计算，在顶点着色器中就可以完成对光照方向和视角方向的变换？）
//（方法二：在世界空间下进行光照计算，由于要先对法线纹理进行采样，所以变换过程必须在片元着色器中实现？）
//这里使用方法一


// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Normal Map In Tangent Space"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1) //配合主纹理 控制漫反射、环境光
        _MainTex("Main Tex", 2D) = "white"{}
        _BumpMap("Normal Map", 2D) = "bump" {} //法线纹理(normal map) 
                                               //bump是Unity内置的法线纹理，对应模型自带的法线信息
        _BumpScale("Bump Scale", Float) = 1.0 //一个用于控制凹凸程度的数字
        _Specular("Specular", Color) = (1, 1, 1, 1)
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
            float4 _MainTex_ST; // 缩放scale（.xy） 平移/偏移translation（.zw）
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; //顶点的切线方向
                                          //【注意】法线方向是float3，而切线方向是float4，
                                          //这是因为我们需要使用tangent.w分量来决定切线空间中的第三个坐标
                                          //——副切线的方向性。
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                //float3 worldNormal : TEXCOORD0; //这里TEXCOORDn并不是纹理
                //float4 worldPos : TEXCOORD1;
                float4 uv : TEXCOORD0; // float4 其中xy分量存储_MainTex的纹理坐标，zw分量存储_BumpMap纹理坐标
                                       // 片元着色器中使用纹理坐标进行纹理采样
                float3 lightDir : TEXCOORD1; //切线空间下的
                float3 viewDir : TEXCOORD2; //切线空间下的
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _BumpMap_ST.xy + _BumpMap_ST.zw;
                // Or just call the built-in function
                //o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex);
                //o.uv.zw = TRANSFORM_TEX(v.texcoord, _BumpMap);

                // 以下代码能处理非等比缩放和非等比缩放的情况
                ///
                /// Note that the code below can handle both uniform and non-uniform scales
                /// 
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
                // Construct a matrix that transforms a point/vector from tangent space to world space
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal); //法线
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz); //切线
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; //副切线
                //在计算副切线时我们使用 .tangent.w 和叉积结果进行相乘 
                //这是因为和切线与法线方向都垂直的方向有两个，而w决定了我们选择其中哪个方向。
                //切线空间to世界空间的变换矩阵是正交矩阵（仅包含平移和旋转，这不就是MVN里的视图变换嘛！）
                //把世界空间下切线方向，副切线方向和法线方向【按行排列】来得到从世界空间到切线空间的变换矩阵
				//wToT = the inverse of tToW = the transpose of tToW as long as tToW is an orthogonal matrix.
                float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal);
                // Transform the light and view dir from world space to tangent space
                o.lightDir = mul(worldToTangent, WorldSpaceLightDir(v.vertex));
                o.viewDir = mul(worldToTangent, WorldSpaceViewDir(v.vertex));

                // 以下代码不能处理非等比缩放的情况
                ///
                /// Note that the code below can only handle uniform scales, not including non-uniform scales
                /// 
                // Compute the binormal
				//float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) ) * v.tangent.w;
				//// Construct a matrix which transform vectors from object space to tangent space
                //把模型空间下切线方向，副切线方向和法线方向按行排列来得到从模型空间到切线空间的变换矩阵rotation
				//float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
                //Unity 也提供了一个内置宏TANGENT_SPACE_ROTATION 来帮助我们直接计算得 rotation变换矩阵。实现和上述代码完全一样。
                //Or just use the built-in macro
				//TANGENT_SPACE_ROTATION;
				//
				//// Transform the light direction from object space to tangent space
				//o.lightDir = mul(rotation, normalize(ObjSpaceLightDir(v.vertex))).xyz;
				//// Transform the view direction from object space to tangent space
				//o.viewDir = mul(rotation, normalize(ObjSpaceViewDir(v.vertex))).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 使用纹理采样结果(float4) 乘 _Color 得到 材质的反射率albedo（代替漫反射系数_Diffuse）
                // 
                // tex2D函数：对纹理进行采样
                // tex2D(sampler2D 纹理tex,float2 纹理坐标uv) 
                // return float4 返回计算得到的纹素值(纹理数据的值)
                // 
                // 我们使用采样结果和颜色属性_Color 的乘积来作为材质的反射率albedo
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                // 环境光项 //注意：需要定义合适的LightMode标签
                // 把albedo和环境光照相乘得到环境光部分
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //// 世界空间下的 法线
                //fixed3 worldNormal = normalize(i.worldNormal);
                //// 世界空间下的 光线方向（已经取反了！）
                ////fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);//注意：假设场景中只有一个光源且该光源的类型是平行光
                //fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos)); //注意：仅可用于前向渲染

                // 对法线纹理_BumpMap进行采样得到纹素值
                // Get the texel in the normal map 
                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                // 切线空间下的 法线n
                fixed3 tangentNormal;
                // 法线纹理中存储的是把法线经过映射后得到的像素值，因此我们需要把它们反映射回来。
                // If the texture is not marked as "Normal map" 如果纹理没有被标为Normal map，手动进行反映射。
				//tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
				//tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                // Or mark the texture as "Normal map", and use the built-in funciton 如果纹理被标为Normal map，使用内置函数
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale; //人工修改法线的xy分量来控制凹凸程度
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                // 切线空间下的 光线方向l
                fixed3 tangentLightDir = normalize(i.lightDir);

                // 漫反射项 // 材质的反射率albedo代替了漫反射系数_Diffuse
                //fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                // 世界空间下的 观察方向v
                //fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                //fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // 世界空间下的 半方向h
                //fixed3 halfDir = normalize(worldLightDir + viewDir);

                // 切线空间下的 观察方向v
                fixed3 tangentViewDir = normalize(i.viewDir);
                // 切线空间下的 半方向h
                fixed3 tangentHalfDir = normalize(tangentLightDir + tangentViewDir);

                // 镜面反射项 (采用Blinn-Phong模型：dot(n,h))
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, tangentHalfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
