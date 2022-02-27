//Phong ����ģ�� (�𶥵�)

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 6/Specular Vertex-Level"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20 //���ʵĹ���ȵĿ�ѡ��Χ��Ϊ8~256
    }
    SubShader
    {
        Tags { "LightMode" = "ForwardBase" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc" // Ϊ��ʹ�����ñ���_LightColor0

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
                // ���� from object space to projection space
                // ��MVP����任
                o.pos = UnityObjectToClipPos(v.vertex);

                // �������� //ע�⣺��Ҫ������ʵ�LightMode��ǩ
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // ����ռ��µ� ����
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));

                // ����ռ��µ� ���߷����Ѿ�ȡ���ˣ�����
                //ע�⣺���賡����ֻ��һ����Դ�Ҹù�Դ��������ƽ�й�
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

                // ��������
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir));

                // ����ռ��µ� ���淴�䷽��r
                fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));

                // ����ռ��µ� �۲췽��v
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);

                // ���淴���� (����Phongģ�ͣ�dot(v,r))
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
//ʹ���𶥵�ķ����õ��ĸ߹�Ч���бȽϴ�����⣬���ǿ�����ͼ 6.10 �п����߹ⲿ�����Բ�ƽ����
//����Ҫ����Ϊ���߹ⷴ�䲿�ֵļ����Ƿ����Եģ����ڶ�����ɫ���м�������ٽ��в�ֵ�Ĺ��������Եģ�
//�ƻ���ԭ����ķ����Թ�ϵ���ͻ���ֽϴ���Ӿ����⡣
// 
//��ˣ����Ǿ���Ҫʹ�������صķ���������߹ⷴ�䡣