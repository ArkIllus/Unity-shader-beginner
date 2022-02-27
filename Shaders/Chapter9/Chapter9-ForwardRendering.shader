//Blinn-Phong 光照模型 (逐片元) + 前向渲染（处理不同类型的光源，不再只是平行光）
//为前向渲染定义了 Base Pass 和 AdditionalPass 来处理多个光源

Shader "Unity Shaders Book/Chapter 9/Forward Rendering"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        //RenderType标签可以让Unity把这个Shader归入到提前定义的组（Opaque组）中，
        //以指明该shader是一个不透明的shader。RenderType标签通常被用于着色器替换功能。

        Pass
        {   // Pass for ambient light & first pixel light (directional light)
            Tags { "LightMode" = "ForwardBase"}

            CGPROGRAM

            #pragma multi_compile_fwdbase
            //该指令可以保证我们在Shader中使用光照衰减等光照变量可以被正确赋值。这是不可缺少的。

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"

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
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                
                //_WorldSpaceLightPos0.xyz：
                //如果是平行光，表示平行光的方向
                //如果是其他光，表示光源的位置
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                // 一般是用下面这行 (????????????????????????????)
                //fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                // 一般是用下面这行 (????????????????????????????)
                //fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                //平行光的衰减系数为1（没有衰减）
                fixed atten = 1.0;

                return fixed4(ambient + (diffuse + specular) * atten, 1.0);
            }

            ENDCG
        }

        Pass
        {   // Pass for other pixel lights
            Tags { "LightMode" = "ForwardAdd"}

            //【注意】需要开启和设置混合模式
            Blend One One
            //Blend SrcAlpha One
            //因为我们希望Additional Pass计算得到的光照结果可以在帧缓存中与之前的光照结果进行叠加。
            //如果没有Blend命令，Additional Pass会直接覆盖掉之前的光照结果。
            //这里我们选择的混合系数是Blend One One
            //这不是必需的 我们可以设置成 Unity 支持的任何混合系数。常见的还有 Blend SrcAlpha One

            CGPROGRAM

            #pragma multi_compile_fwdadd
            //该指令可以保证我们在Shader中使用光照衰减等光照变量可以被正确赋值。这是不可缺少的。

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

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
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);

                //_WorldSpaceLightPos0.xyz：
                //如果是平行光，表示平行光的方向
                //如果是其他光，表示光源的位置
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                #endif
                // 一般是用下面这行 (????????????????????????????)
                //fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                // 一般是用下面这行 (????????????????????????????)
                //fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed atten = 1.0;
                #else
                    //Unity 在内部使用一张名为_LightTextureO 的纹理来计算光源衰减
                    //为了对_LightTextureO 纹理采样得到给定点到该光源的衰减值，我们首先需要得到该点在光源
                    //空间中的位置，这是通过_LightMatrix.0 变换矩阵得到的
                    //然后，我们可以使用这个坐标的模的平方对衰减纹理进行采样，得到衰减值：
                    #if defined (POINT)
                        float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                        fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #elif defined (SPOT)
                        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
                        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #else
                        fixed atten = 1.0;
                    #endif
                #endif
                //需要注意的是，本节只是为了讲解处理其他类型光源的实现原理，上述代码并不会用于真正的项目中。

                //不包含环境光项
                return fixed4((diffuse + specular) * atten, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}
