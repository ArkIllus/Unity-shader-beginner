//Blinn-Phong 光照模型 (逐片元) + 
//法线纹理(normal map)实现凹凸映射(bump mapping) 
//（方法一：在切线空间下进行光照计算，在顶点着色器中就可以完成对光照方向和视角方向的变换？）
//（方法二：在世界空间下进行光照计算，由于要先对法线纹理进行采样，所以变换过程必须在片元着色器中实现？）
//这里使用方法二


// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Normal Map In World Space"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1) //配合主纹理 控制漫反射、环境光
        _MainTex("Main Tex", 2D) = "white"{}
        _BumpMap("Normal Map", 2D) = "bump" {} //法线纹理(normal map) //bump是Unity内置的法线纹理，对应模型自带的法线信息
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
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv.zw = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

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

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 worldPos = float3(i.TtoW0.w, i.TtoW1.w, i.TtoW2.w);

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

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
//从视觉表现上，在切线空间下和在世界空间下计算光照几乎没有任何差别。
//Unity4.x版本中，在不需要使用 Cubemap 进行环境映射的情况下 ，内置的 Unity Shader 使用的是切线空间来进行法线映射和光照计算。
//而在 Unity.5x 中，所有内置的 Unity Shader 使用了世界空间来进行光照计算。
