// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 6/Half Lambert"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1) //���ʵ���������ɫ��������ϵ����
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase"} //LigtMode�����ڶ����Pass��Unity�Ĺ�����ˮ���еĽ�ɫ
                                                //ֻ�ж�������ȷ�� LightMode,���ǲ��ܵõ� Unity �����ù��ձ�������������Ҫ������_LightColorO
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc" //Ϊ��ʹ�� Unity ���õ� Щ�����������Ҫ������_LightColorO

            fixed4 _Diffuse;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL; //ģ�Ͷ���ķ�����Ϣ
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0; //����TEXCOORD0����������
            };

            v2f vert (a2v v)
            {
                v2f o;
                // ���� from object space to projection space
                // ��MVP����任
                o.pos = UnityObjectToClipPos(v.vertex);

                // ���� from object space to world space
                // �ö���任����ObjectToWorld������ת�þ���Է��߽��б任
                // mul(����x, ����y) = mul(����y��ת��, ����x)
                o.worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject)); //�����������normalize��������

                return o;
            }

            //ʵ��һ����ƬԪ����������� ����������䲿�ֵļ��㶼����ƬԪ��ɫ���н���
            fixed4 frag(v2f i) : SV_Target
            {
                // �������� //ע�⣺��Ҫ������ʵ�LightMode��ǩ
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                
                // ����ռ��µķ���
                fixed3 worldNormal = i.worldNormal;

                // ����ռ��µĹ��߷����Ѿ�ȡ���ˣ���
                //ע�⣺���賡����ֻ��һ����Դ�Ҹù�Դ��������ƽ�й�
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                // ��������
                // ��������(Half Lambert)����ģ��
                // ��dot(n,l)�Ľ����Χ��[-1,-1]ӳ�䵽[0,1]��Ҳ����˵����ģ�͵ı�����Ҳ���������仯
                fixed halfLambert = dot(worldNormal, worldLight) * 0.5 + 0.5;
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLambert;
                
                fixed3 color = ambient + diffuse; // û�о��棨�߹⣩������

                return fixed4(color, 1.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse" //�ص�Shader����Ϊ���õ� Diffuse
}

