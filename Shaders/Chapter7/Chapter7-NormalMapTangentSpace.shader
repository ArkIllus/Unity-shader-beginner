//Blinn-Phong ����ģ�� (��ƬԪ) + 
//��������(normal map)ʵ�ְ�͹ӳ��(bump mapping) 
//������һ�������߿ռ��½��й��ռ��㣬�ڶ�����ɫ���оͿ�����ɶԹ��շ�����ӽǷ���ı任����
//����������������ռ��½��й��ռ��㣬����Ҫ�ȶԷ���������в��������Ա任���̱�����ƬԪ��ɫ����ʵ�֣���
//����ʹ�÷���һ


// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Normal Map In Tangent Space"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1) //��������� ���������䡢������
        _MainTex("Main Tex", 2D) = "white"{}
        _BumpMap("Normal Map", 2D) = "bump" {} //��������(normal map) 
                                               //bump��Unity���õķ���������Ӧģ���Դ��ķ�����Ϣ
        _BumpScale("Bump Scale", Float) = 1.0 //һ�����ڿ��ư�͹�̶ȵ�����
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" } //ǰ����Ⱦ

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc" // for _LightColor0

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; // ����scale��.xy�� ƽ��/ƫ��translation��.zw��
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; //��������߷���
                                          //��ע�⡿���߷�����float3�������߷�����float4��
                                          //������Ϊ������Ҫʹ��tangent.w�������������߿ռ��еĵ���������
                                          //���������ߵķ����ԡ�
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                //float3 worldNormal : TEXCOORD0; //����TEXCOORDn����������
                //float4 worldPos : TEXCOORD1;
                float4 uv : TEXCOORD0; // float4 ����xy�����洢_MainTex���������꣬zw�����洢_BumpMap��������
                                       // ƬԪ��ɫ����ʹ��������������������
                float3 lightDir : TEXCOORD1; //���߿ռ��µ�
                float3 viewDir : TEXCOORD2; //���߿ռ��µ�
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

                // ���´����ܴ���ǵȱ����źͷǵȱ����ŵ����
                ///
                /// Note that the code below can handle both uniform and non-uniform scales
                /// 
                /*
                //��������ռ�to���߿ռ�����ԭ��
                ���߿ռ�Ϊ�ӿռ䣨c��������ռ�Ϊ���ռ䣨p��������M_c_to_p�Ĺ�ʽ���ɵõ������������С�
                float4x4 tangentToWorld = float4x4(worldTangent.x, worldBinormal.x, worldNormal.x, 0.0,
                                                   worldTangent.y, worldBinormal.y, worldNormal.y, 0.0,
                                                   worldTangent.z, worldBinormal.z, worldNormal.z, 0.0,
                                                   0.0, 0.0, 0.0, 1.0);
                // The matrix that transforms from world space to tangent space is inverse of tangentToWorld
                �������
                float3x3 worldToTangent = inverse(tangentToWorld);
                */
                // Construct a matrix that transforms a point/vector from tangent space to world space
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal); //����
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz); //����
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; //������
                //�ڼ��㸱����ʱ����ʹ�� .tangent.w �Ͳ������������ 
                //������Ϊ�������뷨�߷��򶼴�ֱ�ķ�������������w����������ѡ�������ĸ�����
                //���߿ռ�to����ռ�ı任�������������󣨽�����ƽ�ƺ���ת���ⲻ����MVN�����ͼ�任���
                //������ռ������߷��򣬸����߷���ͷ��߷��򡾰������С����õ�������ռ䵽���߿ռ�ı任����
				//wToT = the inverse of tToW = the transpose of tToW as long as tToW is an orthogonal matrix.
                float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal);
                // Transform the light and view dir from world space to tangent space
                o.lightDir = mul(worldToTangent, WorldSpaceLightDir(v.vertex));
                o.viewDir = mul(worldToTangent, WorldSpaceViewDir(v.vertex));

                // ���´��벻�ܴ���ǵȱ����ŵ����
                ///
                /// Note that the code below can only handle uniform scales, not including non-uniform scales
                /// 
                // Compute the binormal
				//float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) ) * v.tangent.w;
				//// Construct a matrix which transform vectors from object space to tangent space
                //��ģ�Ϳռ������߷��򣬸����߷���ͷ��߷������������õ���ģ�Ϳռ䵽���߿ռ�ı任����rotation
				//float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
                //Unity Ҳ�ṩ��һ�����ú�TANGENT_SPACE_ROTATION ����������ֱ�Ӽ���� rotation�任����ʵ�ֺ�����������ȫһ����
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
                // ʹ������������(float4) �� _Color �õ� ���ʵķ�����albedo������������ϵ��_Diffuse��
                // 
                // tex2D��������������в���
                // tex2D(sampler2D ����tex,float2 ��������uv) 
                // return float4 ���ؼ���õ�������ֵ(�������ݵ�ֵ)
                // 
                // ����ʹ�ò����������ɫ����_Color �ĳ˻�����Ϊ���ʵķ�����albedo
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                // �������� //ע�⣺��Ҫ������ʵ�LightMode��ǩ
                // ��albedo�ͻ���������˵õ������ⲿ��
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //// ����ռ��µ� ����
                //fixed3 worldNormal = normalize(i.worldNormal);
                //// ����ռ��µ� ���߷����Ѿ�ȡ���ˣ���
                ////fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);//ע�⣺���賡����ֻ��һ����Դ�Ҹù�Դ��������ƽ�й�
                //fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos)); //ע�⣺��������ǰ����Ⱦ

                // �Է�������_BumpMap���в����õ�����ֵ
                // Get the texel in the normal map 
                fixed4 packedNormal = tex2D(_BumpMap, i.uv.zw);
                // ���߿ռ��µ� ����n
                fixed3 tangentNormal;
                // ���������д洢���ǰѷ��߾���ӳ���õ�������ֵ�����������Ҫ�����Ƿ�ӳ�������
                // If the texture is not marked as "Normal map" �������û�б���ΪNormal map���ֶ����з�ӳ�䡣
				//tangentNormal.xy = (packedNormal.xy * 2 - 1) * _BumpScale;
				//tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                // Or mark the texture as "Normal map", and use the built-in funciton ���������ΪNormal map��ʹ�����ú���
                tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale; //�˹��޸ķ��ߵ�xy���������ư�͹�̶�
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));

                // ���߿ռ��µ� ���߷���l
                fixed3 tangentLightDir = normalize(i.lightDir);

                // �������� // ���ʵķ�����albedo������������ϵ��_Diffuse
                //fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                // ����ռ��µ� �۲췽��v
                //fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                //fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // ����ռ��µ� �뷽��h
                //fixed3 halfDir = normalize(worldLightDir + viewDir);

                // ���߿ռ��µ� �۲췽��v
                fixed3 tangentViewDir = normalize(i.viewDir);
                // ���߿ռ��µ� �뷽��h
                fixed3 tangentHalfDir = normalize(tangentLightDir + tangentViewDir);

                // ���淴���� (����Blinn-Phongģ�ͣ�dot(n,h))
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, tangentHalfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
