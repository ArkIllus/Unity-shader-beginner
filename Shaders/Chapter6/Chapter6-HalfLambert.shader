// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 6/Half Lambert"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1) //材质的漫反射颜色（漫反射系数）
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase"} //LigtMode，用于定义该Pass在Unity的光照流水线中的角色
                                                //只有定义了正确的 LightMode,我们才能得到 Unity 的内置光照变量，例如下面要讲到的_LightColorO
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc" //为了使用 Unity 内置的 些变量，如后面要讲到的_LightColorO

            fixed4 _Diffuse;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL; //模型顶点的法线信息
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0; //这里TEXCOORD0并不是纹理
            };

            v2f vert (a2v v)
            {
                v2f o;
                // 顶点 from object space to projection space
                // 即MVP矩阵变换
                o.pos = UnityObjectToClipPos(v.vertex);

                // 法线 from object space to world space
                // 用顶点变换矩阵（ObjectToWorld）的逆转置矩阵对法线进行变换
                // mul(向量x, 矩阵y) = mul(矩阵y的转置, 向量x)
                o.worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject)); //（这里采用先normalize的做法）

                return o;
            }

            //实现一个逐片元的漫反射光照 ，因此漫反射部分的计算都将在片元着色器中进行
            fixed4 frag(v2f i) : SV_Target
            {
                // 环境光项 //注意：需要定义合适的LightMode标签
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                // 世界空间下的法线
                fixed3 worldNormal = i.worldNormal;

                // 世界空间下的光线方向（已经取反了？）
                //注意：假设场景中只有一个光源且该光源的类型是平行光
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                // 漫反射项
                // 半兰伯特(Half Lambert)光照模型
                // 把dot(n,l)的结果范围从[-1,-1]映射到[0,1]，也就是说对于模型的背光面也会有明暗变化
                fixed halfLambert = dot(worldNormal, worldLight) * 0.5 + 0.5;
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLambert;
                
                fixed3 color = ambient + diffuse; // 没有镜面（高光）反射项

                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse" //回调Shader设置为内置的 Diffuse
}

