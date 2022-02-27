//Blinn-Phong ����ģ�� (��ƬԪ) + ������ + ��������(����һ�������߿ռ��½��й��ռ���) + ��������

//ʹ�÷�������normal texture�� ʵ�ְ�͹ӳ��bump mapping��
//ʹ����������mask texture�� ���Ƹ߹ⷴ����յĽ����

Shader "Unity Shaders Book/Chapter 7/Mask Texture"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1) //��������� ���������䡢������
        _MainTex("Main Tex", 2D) = "white"{}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Bump Scale", Float) = 1.0
        _SpecularMask("Specular Mask", 2D) = "white" {}
        _SpecularScale("Specular Scale", Float) = 1.0
        _Specular("Specular", Color) = (1, 1, 1, 1) //����������� ���Ƹ߹�
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
            float4 _MainTex_ST; // scale��.xy�� translation��.zw��//��ô���?????
                                //Ϊ�������������������������˹�ͬʹ�õ����ź�ƽ�Ʊ���_MainTex_ST
            sampler2D _BumpMap;
            float _BumpScale;
            sampler2D _SpecularMask;
            float _SpecularScale;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT; //ʹ��tangent.w�������������߿ռ��еĵ��������ꡪ�������ߵķ����ԡ�
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                //float4 uv : TEXCOORD0;
                float2 uv : TEXCOORD0; //����ֻ��һ��ST�������������Ҳֻ��һ��
                float3 tangentLightDir : TEXCOORD1; //���߿ռ��µ�
                float3 tangentViewDir : TEXCOORD2; //���߿ռ��µ�
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.uv.xy = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                // ���´����ܴ���ǵȱ����źͷǵȱ����ŵ����
                /*
                //��������ռ�to���߿ռ�����ԭ��
                ���߿ռ�Ϊ�ӿռ䣨c��������ռ�Ϊ���ռ䣨p��������M_c_to_p�Ĺ�ʽ���ɵõ������������С�
                float4x4 tangentToWorld = float4x4(worldTangent.x, worldBinormal.x, worldNormal.x, 0.0,
                                                    worldTangent.y, worldBinormal.y, worldNormal.y, 0.0,
                                                    worldTangent.z, worldBinormal.z, worldNormal.z, 0.0,
                                                    0.0, 0.0, 0.0, 1.0);
                �������
                float3x3 worldToTangent = inverse(tangentToWorld);
                */
                fixed3 worldNormal = UnityObjectToWorldNormal(v.normal);
                fixed3 worldTangent = UnityObjectToWorldNormal(v.tangent.xyz);
                fixed3 worldBinormal = cross(worldNormal, worldTangent) * v.tangent.w; //v.tanget.w��������
                //�ñ任�������������󣨽�����ƽ�ƺ���ת=MVP�����ͼ�任��
                //������ռ������߷��򣬸����߷���ͷ��߷��򡾰������С����õ�������ռ䵽���߿ռ�ı任����
                float3x3 worldToTangent = float3x3(worldTangent, worldBinormal, worldNormal);
                o.tangentLightDir = mul(worldToTangent, WorldSpaceLightDir(v.vertex));
                o.tangentViewDir = mul(worldToTangent, WorldSpaceViewDir(v.vertex));

                // ���´��벻�ܴ���ǵȱ����ŵ����
                // ����rotation�任����
                //
                // ����һ�� ��д
                //float3 binormal = cross( normalize(v.normal), normalize(v.tangent.xyz) ) * v.tangent.w;
                //��ģ�Ϳռ������߷��򣬸����߷���ͷ��߷������������õ���ģ�Ϳռ䵽���߿ռ�ı任����rotation
                //float3x3 rotation = float3x3(v.tangent.xyz, binormal, v.normal);
                //
                // �������� ���ú���
                //Or just use the built-in macro
                //TANGENT_SPACE_ROTATION;
                //
                //o.tangentLightDir = mul(rotation, normalize(ObjSpaceLightDir(v.vertex))).xyz;
                //o.tangentViewDir = mul(rotation, normalize(ObjSpaceViewDir(v.vertex))).xyz;

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            { 
                //��vertex shader��������: l v
                fixed3 tangentLightDir = normalize(i.tangentLightDir);
                fixed3 tangentViewDir = normalize(i.tangentViewDir);
                //�ӷ������� �ٲ��� �ڽ�� ���˹�����(xy����*_BumpScale) ��á����߿ռ��µġ�����: n
                fixed3 tangentNormal = UnpackNormal(tex2D(_BumpMap, i.uv));
                tangentNormal.xy *= _BumpScale;
                tangentNormal.z = sqrt(1.0 - saturate(dot(tangentNormal.xy, tangentNormal.xy)));
                //�뷽��h
                fixed3 tangentHalfDir = normalize((tangentLightDir + tangentViewDir));

                //���������� �ٲ�������ȡRͨ���� ���˹�������*_SpecularScale�����specularMask
                //��ע�⡿����ȡRͨ����˵�������������Ѹ߹ⷴ���ǿ�ȴ洢��Rͨ����
                fixed specularMask = tex2D(_SpecularMask, i.uv).r * _SpecularScale;

                // ������ϵ�� / Ҳ�з����� (��Ӱ�컷���⡢�������)(�����������д�����_diffuse)
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                //ʹ��albedo����
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //ʹ��albedo��Ϊ������ϵ��
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(tangentNormal, tangentLightDir));

                //ʹ����������mask texture�� ���Ƹ߹ⷴ����յĽ����
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, tangentHalfDir)), _Gloss) * specularMask;
                //fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(tangentNormal, tangentHalfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}