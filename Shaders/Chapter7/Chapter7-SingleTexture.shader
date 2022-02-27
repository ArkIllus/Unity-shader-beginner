//Blinn-Phong 光照模型 (逐片元) + 纹理

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Single Texture"
{
    Properties
    {
        //_Diffuse("Diffuse", Color) = (1, 1, 1, 1) //使用纹理和_Color代替了漫反射颜色（系数）
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex("Main Tex", 2D) = "white"{}
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
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0; //第一组纹理坐标
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0; //这里TEXCOORDn并不是纹理
                float4 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2; //存储纹理坐标的变量uv，以便片元着色器中使用改坐标进行纹理采样
            };

            v2f vert (a2v v)
            {
                v2f o;
                // 顶点 from object space to projection space // 即MVP矩阵变换
                o.pos = UnityObjectToClipPos(v.vertex);

                // 世界空间下的 顶点法线（使用内置函数）
                //o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                // 世界空间下的 顶点位置（这里采用先不normalize的做法）
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                // 先对顶点纹理坐标进行缩放（.xy），再进行偏移（.zw）
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                // Or just call the built-in function
                //o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // 使用纹理抽样结果 乘 _Color 得到 材质的反射率albedo（代替漫反射系数_Diffuse）
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

                // 世界空间下的 法线
                fixed3 worldNormal = normalize(i.worldNormal);
                // 世界空间下的 光线方向（已经取反了！）
                //fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);//注意：假设场景中只有一个光源且该光源的类型是平行光
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos)); //注意：仅可用于前向渲染

                // 漫反射项 // 材质的反射率albedo代替了漫反射系数_Diffuse
                //fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                // 世界空间下的 观察方向v
                //fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // 世界空间下的 半方向h
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // 镜面反射项 (采用Blinn-Phong模型：dot(n,h))
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
