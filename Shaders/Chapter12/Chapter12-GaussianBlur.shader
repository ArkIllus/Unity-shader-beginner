Shader "Unity Shaders Book/Chapter 12/Gaussian Blur" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {} //Graphics.Blit(buffer0, buffer1, material, 0)��buffer0���ݸ�materialʹ�õ�shader����Ϊ_MainTex������
        _BlurSize("Blur Size", Float) = 1.0 //��OnRenderImage�б�����
        //����û��iterations blurSpread downSample��
    }
    SubShader
    {
        //�����У��״�ʹ��CGINCLUDE����֯���룬��Щ���벻��Ҫ������Pass������С�CGINCLUDE����C++ͷ�ļ��Ĺ��ܡ�
        //Ŀ�ģ���������ظ�
        //
        //��ʽ�� 
        //GCINCLUDE
        //...
        //ENDCG

        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize; //Unity�ṩ�ķ���xxx�����Ӧ��ÿ�����صĴ�С�������ھ�������������������������ꡣ
        float _BlurSize;

        struct v2f {
            float4 pos : SV_POSITION;
            half2 uv[5]: TEXCOORD0; //5��5�Ķ�ά��˹�ˣ����Բ�ֳ�2����СΪ5��һά��˹�ˣ���ֻ��Ҫ5����������
        };

        //ͨ���Ѽ��������������Ĵ����ƬԪ��ɫ����ת�Ƶ�������ɫ���У����Լ������㣬������ܡ�
        //���ڴӶ�����ɫ����ƬԪ��ɫ���Ĳ�ֵ�����Եģ����������ת�Ʋ�����Ӱ����������ļ�������

        // ��ֱ����
        v2f vertBlurVertical(appdata_img v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            half2 uv = v.texcoord;

            // 5���������� �����fragBlur�� weight[3] ��Ӧ
            o.uv[0] = uv;
            o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;

            return o;
        }

        // ˮƽ����
        v2f vertBlurHorizontal(appdata_img v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            half2 uv = v.texcoord;

            // 5���������� �����fragBlur�� weight[3] ��Ӧ
            o.uv[0] = uv;
            o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;

            return o;
        }

        //2��Pass���õ�ƬԪ��ɫ��
        fixed4 fragBlur(v2f i) : SV_Target {
            //5��5�Ķ�ά��˹�ˣ����Բ�ֳ�2����СΪ5��һά��˹�ˣ����ڶԳ��ԣ�ֻ��Ҫ��¼3����˹Ȩ��
            // ԭ����5����˹Ȩ�أ� 0.0545, 0.2442, 0.4026, 0.2442, 0.0545
            float weight[3] = {0.4026, 0.2442, 0.0545};

            fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];

            for (int it = 1; it < 3; it++) {
                //���ݶԳ��ԣ�ÿ�ε�������2���������
                sum += tex2D(_MainTex, i.uv[it * 2 - 1]).rgb * weight[it];
                sum += tex2D(_MainTex, i.uv[it * 2]).rgb * weight[it];
            }

            //��󷵻��˲����sum
            return fixed4(sum, 1.0);
        }

        ENDCG

        ZTest Always Cull Off ZWrite Off //��Ļ����shader�ı���
                                         //��Ȳ��Եĺ���������ͨ�� �ر��޳� �ر����д��

        //����Ϊ���� Pass ʹ�� NAME���嶨�������ǵ����֡�
        //ΪPass�������֣�����������Shader��ֱ��ͨ�����ǵ�������ʹ�ø�Pass��
        Pass {
            NAME "GAUSSIAN_BLUR_VERTICAL"

                CGPROGRAM

                #pragma vertex vertBlurVertical  
                #pragma fragment fragBlur

                ENDCG
        }

        Pass{
            NAME "GAUSSIAN_BLUR_HORIZONTAL"

            CGPROGRAM

            #pragma vertex vertBlurHorizontal  
            #pragma fragment fragBlur

            ENDCG
        }
    }
    Fallback "Diffuse"
}
