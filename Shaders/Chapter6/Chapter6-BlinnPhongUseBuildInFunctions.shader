//Blinn-Phong ����ģ�� (��ƬԪ)

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 6/Blinn-Phong Use Built-in Functions"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20 //���ʵĹ���ȵĿ�ѡ��Χ��Ϊ8~256
    }
    SubShader
    {
        Tags { "LightMode" = "ForwardBase" } //ǰ����Ⱦ

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
                float3 worldNormal : TEXCOORD0; //����TEXCOORD0����������
                //float3 worldPos : TEXCOORD1; //��Ϊfrag�в���Ҫ��4ά����������ֱ����float3��
                float4 worldPos : TEXCOORD1; //3άor4ά������
            };

            v2f vert (a2v v)
            {
                v2f o;
                // ���� from object space to projection space
                // ��MVP����任
                o.pos = UnityObjectToClipPos(v.vertex);

                // ����ռ��µ� ���㷨�ߣ�ʹ�����ú�����
                //o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                // ����ռ��µ� ����λ�ã���������Ȳ�normalize��������
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // �������� //ע�⣺��Ҫ������ʵ�LightMode��ǩ
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // ����ռ��µ� ����
                fixed3 worldNormal = normalize(i.worldNormal);
                // ����ռ��µ� ���߷����Ѿ�ȡ���ˣ���
                //fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);//ע�⣺���賡����ֻ��һ����Դ�Ҹù�Դ��������ƽ�й�
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos)); //ע�⣺��������ǰ����Ⱦ

                // ��������
                //fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLightDir)); //һ��
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir)); //һ��

                // ����ռ��µ� �۲췽��v
                //fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // ����ռ��µ� �뷽��h
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // ���淴���� (����Blinn-Phongģ�ͣ�dot(n,h))
                //fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(worldNormal, halfDir)), _Gloss); //һ��
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss); //һ��

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
