Shader "Unity Shaders Book/Chapter 6/Diffuse Vertex-Level"
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
                //float2 uv : TEXCOORD0;
                float3 normal : NORMAL; //模型顶点的法线信息
            };

            struct v2f
            {
                //float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                fixed3 color : COLOR; //为了把在顶点着色器中计算得到的光照颜色传递给片元着色器
                                      //且并不是必须使用COLOR语义， 一些资料中会使用 TEXCOORDO 语义。
            };

            //实现一个逐顶点的漫反射光照 ，
            //因此漫反射部分的计算都将在顶点着色器中进行
            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //环境光项 
                //UNITY_LIGHTMODEL_AMBIENT	fixed4	环境光照颜色（梯度环境情况下的天空颜色）
                //注意：需要定义合适的LightMode标签
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //世界空间下的法线 Transform the normal from object space to world space
                //用顶点变换矩阵（ObjectToWorld）的逆转置矩阵对法线进行变换
                //mul(向量x,矩阵y)相当于mul(矩阵y的转置,向量x)
                //截取前三行前三列
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                
                //世界空间下的光线方向（已经取反了？）
                //_WorldSpaceLightPos0	float4	方向光：（世界空间方向，0）。其他光源：（世界空间位置，1）。
                //注意：假设场景中只有一个光源且该光源的类型是平行光
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                //漫反射项
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

                o.color = ambient + diffuse; // 没有镜面（高光）反射项
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return fixed4(i.color, 1.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse" //回调Shader设置为内置的 Diffuse
}
//对于细分程度较高的模型，逐顶点光照已经可以得到比较好的光照效果了。
//但对于一些细分程度较低的模型，逐顶点光照就会出现一些视觉问题，比如背光面和向光面的交界处有一些锯齿。
//为了解决这些问题，我们可以使用逐像素的漫反射光照。
