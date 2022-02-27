//Blinn-Phong ����ģ�� (��ƬԪ) + 
//��������(normal map)ʵ�ְ�͹ӳ��(bump mapping) 
//������һ�������߿ռ��½��й��ռ��㣬�ڶ�����ɫ���оͿ�����ɶԹ��շ�����ӽǷ���ı任����
//����������������ռ��½��й��ռ��㣬����Ҫ�ȶԷ���������в��������Ա任���̱�����ƬԪ��ɫ����ʵ�֣���
//����ʹ�÷�����


// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Normal Map In World Space"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1) //��������� ���������䡢������
        _MainTex("Main Tex", 2D) = "white"{}
        _BumpMap("Normal Map", 2D) = "bump" {} //��������(normal map) //bump��Unity���õķ���������Ӧģ���Դ��ķ�����Ϣ
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
                float4 tangent : TANGENT; //��������߷�����Ҫʹ��tangent.w���������������ߵķ����ԡ�
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0; // xy����=_MainTex���������꣬zw����=_BumpMap����������
                                       // ƬԪ��ɫ����ʹ��������������������                    
                //�����߿ռ䵽����ռ�ı任����
                //��1����ֵ�Ĵ������ֻ�ܴ洢 float4 ��С�ı�����
                // ����ھ��������ı����ǿ��԰����ǰ��в�ɶ���䳶�ٽ��д洢
                //�Է���ʸ���ı任��Ҫ3x3�ľ��󣬰�ÿ�зֱ�浽��������float4��xyz������
                //������ռ��µĶ���λ�ô���������float4��w������
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

                //����ռ��
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal); //����
                fixed3 worldTangent = UnityObjectToWorldDir(v.tangent.xyz); //����
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; //������

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

                //���߿ռ�to����ռ�ı任��������������
                //������ռ������߷��򣬸����߷���ͷ��߷��򡾰������С����õ�������ռ䵽���߿ռ�ı任����
                //wToT = the inverse of tToW = the transpose of tToW as long as tToW is an orthogonal matrix.
                //float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal); ��ôд�����ǰ����ţ����Բ��ԣ���

                //�������tangentToWorld�ֳ����д洢��
                //w������worldPos
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

                // ����
                // 1.�Ȼ�ȡ�����߿ռ䡿�еķ���
                fixed3 normal = UnpackNormal(tex2D(_BumpMap, i.uv.zw));
                normal.xy *= _BumpScale;
                normal.z = sqrt(1.0 - saturate(dot(normal.xy, normal.xy)));
                // 2.Transfer����from���߿ռ�to����ռ䣨��1��2������һ������normal��
                normal = normalize(half3(dot(i.TtoW0.xyz, normal), dot(i.TtoW1.xyz, normal), dot(i.TtoW2.xyz, normal)));

                // ����ʹ�ò����������ɫ����_Color �ĳ˻�����Ϊ���ʵķ�����albedo
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
//���Ӿ������ϣ������߿ռ��º�������ռ��¼�����ռ���û���κβ��
//Unity4.x�汾�У��ڲ���Ҫʹ�� Cubemap ���л���ӳ�������� �����õ� Unity Shader ʹ�õ������߿ռ������з���ӳ��͹��ռ��㡣
//���� Unity.5x �У��������õ� Unity Shader ʹ��������ռ������й��ռ��㡣
