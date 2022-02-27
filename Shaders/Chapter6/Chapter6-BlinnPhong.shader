//Blinn-Phong 光照模型 (逐片元)

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 6/Blinn-Phong"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20 //材质的光泽度的可选范围设为8~256
    }
    SubShader
    {
        Tags { "LightMode" = "ForwardBase" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc" // 为了使用内置变量_LightColor0

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0; //这里TEXCOORD0并不是纹理
                float3 worldPos : TEXCOORD1; //因为frag中不需要第4维，所以这里直接用float3了
            };

            v2f vert (a2v v)
            {
                v2f o;
                // 顶点 from object space to projection space
                // 即MVP矩阵变换
                o.pos = UnityObjectToClipPos(v.vertex);

                // 世界空间下的 顶点法线（这里采用先不normalize的做法）
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);

                // 世界空间下的 顶点位置（这里采用先不normalize的做法）
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 环境光项 //注意：需要定义合适的LightMode标签
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 世界空间下的 法线
                fixed3 worldNormal = normalize(i.worldNormal);
                // 世界空间下的 光线方向（已经取反了！）
                //注意：假设场景中只有一个光源且该光源的类型是平行光
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                // 漫反射项
                //fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir)); //一样
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir)); //一样

                // 世界空间下的 观察方向v
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                // 世界空间下的 半方向h
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // 镜面反射项 (采用Blinn-Phong模型：dot(n,h))
                //fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss); //一样
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss); //一样

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}

//可以看出 Blinn - Phong 光照模型的高光反射部分看起来更大、更亮一些。
//在实际渲染中，绝大多数情况我们都会选择 Blinn - Phong 光照模型。
//需要再次提醒的是，这两种光照模型都是经验模型，也就是说不应该认为 Blinn - Phong 模型是对“正确的" Phong 模型的近似。
//实际上，在一些情况下（详见第 18 基于物理的渲染）， Blinn - Phong 模型更符合实验结果。
