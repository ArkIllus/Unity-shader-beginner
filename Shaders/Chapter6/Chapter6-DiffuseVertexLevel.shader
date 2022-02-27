Shader "Unity Shaders Book/Chapter 6/Diffuse Vertex-Level"
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
                //float2 uv : TEXCOORD0;
                float3 normal : NORMAL; //ģ�Ͷ���ķ�����Ϣ
            };

            struct v2f
            {
                //float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                fixed3 color : COLOR; //Ϊ�˰��ڶ�����ɫ���м���õ��Ĺ�����ɫ���ݸ�ƬԪ��ɫ��
                                      //�Ҳ����Ǳ���ʹ��COLOR���壬 һЩ�����л�ʹ�� TEXCOORDO ���塣
            };

            //ʵ��һ���𶥵����������� ��
            //��������䲿�ֵļ��㶼���ڶ�����ɫ���н���
            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //�������� 
                //UNITY_LIGHTMODEL_AMBIENT	fixed4	����������ɫ���ݶȻ�������µ������ɫ��
                //ע�⣺��Ҫ������ʵ�LightMode��ǩ
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                //����ռ��µķ��� Transform the normal from object space to world space
                //�ö���任����ObjectToWorld������ת�þ���Է��߽��б任
                //mul(����x,����y)�൱��mul(����y��ת��,����x)
                //��ȡǰ����ǰ����
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject));
                
                //����ռ��µĹ��߷����Ѿ�ȡ���ˣ���
                //_WorldSpaceLightPos0	float4	����⣺������ռ䷽��0����������Դ��������ռ�λ�ã�1����
                //ע�⣺���賡����ֻ��һ����Դ�Ҹù�Դ��������ƽ�й�
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);

                //��������
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));

                o.color = ambient + diffuse; // û�о��棨�߹⣩������
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                return fixed4(i.color, 1.0);
            }
            ENDCG
        }
    }
    Fallback "Diffuse" //�ص�Shader����Ϊ���õ� Diffuse
}
//����ϸ�̶ֳȽϸߵ�ģ�ͣ��𶥵�����Ѿ����Եõ��ȽϺõĹ���Ч���ˡ�
//������һЩϸ�̶ֳȽϵ͵�ģ�ͣ��𶥵���վͻ����һЩ�Ӿ����⣬���米����������Ľ��紦��һЩ��ݡ�
//Ϊ�˽����Щ���⣬���ǿ���ʹ�������ص���������ա�
