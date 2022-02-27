//Blinn-Phong 光照模型 (逐片元) + 渐变纹理

//使用渐变纹理来控制漫反射光照的结果。

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Ramp Texture"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        // 只有一个渐变纹理
        _RampTex("Ramp Tex", 2D) = "white" {}
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
            sampler2D _RampTex;
            float4 _RampTex_ST; // 缩放scale（.xy） 平移/偏移translation（.zw）
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0; //第一组...
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;  
                float2 uv : TEXCOORD2; //只有一个纹理
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                //o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                //没有法线纹理(normal map)
                fixed3 worldNormal = normalize(i.worldNormal);

                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                //半兰伯特(Half Lambert)
                //把dot(n,l)的结果范围从[-1,-1]映射到[0,1]
                fixed halfLambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
                //使用halfLambert构建一个纹理坐标(halfLambert, halfLambert)，并用这个纹理坐标对渐变纹理_RampTex进行采样。
                //由于_RampTex 实际就是一个一维纹理（它在纵轴方向上颜色不变），因此纹理坐标的u和v方向我们都使用了halfLambert。
                //然后把从渐变纹理采样得到的颜色和材质颜色_Color相乘，得到最终的漫反射颜色。
                fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;

                // 我们使用采样结果和颜色属性_Color 的乘积来作为材质的反射率albedo
                //fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                //fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                //即
                //fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // 之前计算漫反射光照时 我们有下面几种方法
                // ①使用表面法线和光照方向的点积结果与材质的漫反射系数_Diffuse、光源颜色相乘来得到表面的漫反射光照
                //fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                // ②使用表面法线和光照方向的点积结果与材质的反射率albedo（_MainTex纹理采样得到）、光源颜色相乘来得到表面的漫反射光照
                //fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                //即
                //fixed3 diffuse = _LightColor0.rgb * tex2D(_MainTex, i.uv).rgb * _Color.rgb * max(0, dot(normal, worldLightDir));
                //现在，我们使用渐变纹理来控制漫反射光照的结果。（Half Lambert+渐变纹理采样）
                fixed3 diffuse = _LightColor0.rgb * diffuseColor;
                //即
                //fixed3 diffuse = _LightColor0.rgb * tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, worldHalfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
