//Phong 光照模型 (逐顶点)

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 6/Specular Vertex-Level"
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
                fixed3 color : COLOR;
            };

            v2f vert (a2v v)
            {
                v2f o;
                // 顶点 from object space to projection space
                // 即MVP矩阵变换
                o.pos = UnityObjectToClipPos(v.vertex);

                // 环境光项 //注意：需要定义合适的LightMode标签
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 世界空间下的 法线
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

                // 世界空间下的 光线方向（已经取反了？！）
                //注意：假设场景中只有一个光源且该光源的类型是平行光
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // 漫反射项
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                // 世界空间下的 镜面反射方向r
                fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));

                // 世界空间下的 观察方向v
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);

                // 镜面反射项 (采用Phong模型：dot(v,r))
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);

                o.color = ambient + diffuse + specular;

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(i.color, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
//使用逐顶点的方法得到的高光效果有比较大的问题，我们可以在图 6.10 中看出高光部分明显不平滑。
//这主要是因为，高光反射部分的计算是非线性的，而在顶点着色器中计算光照再进行插值的过程是线性的，
//破坏了原计算的非线性关系，就会出现较大的视觉问题。
// 
//因此，我们就需要使用逐像素的方法来计算高光反射。