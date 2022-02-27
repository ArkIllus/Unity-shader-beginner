Shader "Unity Shaders Book/Chapter 12/Edge Detection"
{
    Properties
    {
        _MainTex("Base (RGB)", 2D) = "white" {} //Graphics.Blit(src, dest, material)��src���ݸ�materialʹ�õ�shader����Ϊ_MainTex������
        _EdgeOnly("Edge Only", Float) = 1.0
        _EdgeColor("Edge Color", Color) = (0, 0, 0, 1)
        _BackgroundColor("Background Color", Color) = (1, 1, 1, 1)
        //�����ɽű����ݵõ���(��EdgeDetection.cs)�����������������Ϊ����ʾ�ڲ��������
    }
    SubShader
    {
        //Tags { "RenderType"="Opaque" }

        Pass
        {
            ZTest Always Cull Off ZWrite Off //��Ļ����shader�ı���
            //��Ȳ��Եĺ���������ͨ�� �ر��޳� �ر����д��

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragSobel

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            uniform half4 _MainTex_TexelSize; //Unity�ṩ�ķ���xxx�����Ӧ��ÿ�����صĴ�С�������ھ�������������������������ꡣ
                                              //uniform half4 �� half4���� ������
            fixed _EdgeOnly;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;

            //����Ҫa2v����Ϊʹ����Unity���õ�appdata_img�ṹ����Ϊ������ɫ��������
            //struct a2v
            //{
            //    float4 vertex : POSITION;
            //    float4 texcoord : TEXCOORD0;
            //};

            struct v2f
            {
                float4 pos : SV_POSITION;
                //float2 uv : TEXCOORD0;
                half2 uv[9] : TEXCOORD0; //ά��=9���������飬��ӦSobel���Ӳ���ʱ��Ҫ��9��������������
            };
            //ͨ�����������������Ĵ���ƬԪ��ɫ����ת�Ƶ�������ɫ���У����Լ������㣬������ܡ�
            //���ڴӶ�����ɫ����ƬԪ��ɫ���Ĳ�ֵ�����Եģ����������ת�Ʋ�����Ӱ����������ļ�������

            //ʹ����Unity���õ�appdata_img�ṹ����Ϊ������ɫ��������
            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //o.uv = v.texcoord;
                half2 uv = v.texcoord;
				o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
				o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);
                // 9��������������

                return o;
            }

            //������ɫ��Ӧ������ֵ��luminance��
            fixed luminance(fixed4 color) {
                return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
            }

            half Sobel(v2f i) {
                //ˮƽ����ľ����Gx
                const half Gx[9] = {
                    -1, 0, 1,
                    -2, 0, 2,
                    -1, 0, 1
                };
                //��ֱ����ľ����Gy
                const half Gy[9] = {
                    -1, -2, -1,
                    0, 0, 0,
                    1, 2, 1
                };
                half texColor;
                half edgeX = 0;
                half edgeY = 0;
                for (int it = 0; it < 9; it++) {
                    texColor = luminance(tex2D(_MainTex, i.uv[it])); //����ֵ
                    edgeX += texColor * Gx[it]; //�ݶ�ֵGx
                    edgeY += texColor * Gy[it]; //�ݶ�ֵGy
                }

                // �������ܿ��ǣ�ʹ�þ���ֵ���濪���Ų����� G = |Gx| + |Gy|
                half edge = 1 - abs(edgeX) - abs(edgeY); //�����õ���edge=1-GԽС����λ��Խ������һ����Ե��

                return edge;
            }

            fixed4 fragSobel(v2f i) : SV_Target
            {
                // ����Sobel�������㵱ǰ���أ�ƬԪ�����ݶ�ֵedge
                half edge = Sobel(i);
                
                //�����Ե������ԭ��Ⱦͼ�񣨱�����ɫΪԭͼ���ϵ���ɫֵ
                fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), edge);

                //����ֻ��ʾ��Ե������ʾԭͼ�񣨱�����ɫΪ_BackgroundColor������ɫֵ
                fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);

                //�����_EdgeOnly������������ɫ�м��ֵ�õ����յ����أ�ƬԪ����ɫ
                return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
            }
            ENDCG
        }
    }
    Fallback Off
}
// ��Ҫע����ǣ�����ʵ�ֵı�Ե��������������Ļ
//��ɫ��Ϣ������ʵ��Ӧ���У������������Ӱ����Ϣ��
//��Ӱ���Ե��� �Ľ����ʹ�ý����������Ԥ�ڵ���
//�ߡ�Ϊ�˵õ�����׼ȷ�ı�Ե��Ϣ����������������Ļ��
//�������ͷ��������Ͻ��б�Ե��⡣���ǽ����� 13.4
//����ʵ�����ַ�����
