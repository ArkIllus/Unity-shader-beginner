Shader "Unity Shaders Book/Chapter 12/Brightness Saturation And Contrast"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} //Graphics.Blit(src, dest, material)��src���ݸ�materialʹ�õ�shader����Ϊ_MainTex������
        _Brightness("Brightness", Float) = 1
        _Saturation("Saturation", Float) = 1
        _Contrast("Contrast", Float) = 1
            //���ȡ����Ͷȡ��Աȶȣ������ɽű����ݵõ��ġ����������������Ϊ����ʾ�ڲ��������
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
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            half _Brightness;
            half _Saturation;
            half _Contrast;

            //����Ҫa2v����Ϊʹ����Unity���õ�appdata_img�ṹ����Ϊ������ɫ��������
            //struct a2v
            //{
            //    float4 vertex : POSITION;
            //    float4 texcoord : TEXCOORD0;
            //};

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            //ʹ����Unity���õ�appdata_img�ṹ����Ϊ������ɫ��������
            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // ��ԭ��Ļͼ�񣨴���_MainTex�У�����
                fixed4 renderTex = tex2D(_MainTex, i.uv);
                
                //1. ���ȵ���
                // ԭ��ɫ������ϵ��
                fixed3 finalColor = renderTex.rgb * _Brightness; // _Brightness=3ʱ (1,1,1)���ͱ��(3,3,3)��???????
                                                                 // ʵ��һ�¾��ܷ��֣���������[0,1]֮�� 
                                                                 // ����(0.5,0.4,0.3)*3 = (1,1,0.9)���ٱ������Ⱥܴ���ô�ͱ䴿�ף�����<=0��ô�ͱ䴿��

                //2. ���Ͷȵ���
                // ��������ض�Ӧ������ֵ��luminance�� 
                // �ù�ʽ��RGBתYUV��BT709������ת����ʽ���ǻ������۸�֪��ͼ��Ҷȴ���ʽ��������ʽͨ������ÿ������RGBֵ��Ӧ�ĻҶ�ֵ������RGB��ɫͼ��ת��Ϊ�Ҷ�ͼ��
                fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                // ʹ�ø�����ֵ����һ�����Ͷ�Ϊ0����ɫֵ����ɫor��ɫor��ɫ��
                fixed3 luminanceColor = fixed3(luminance, luminance, luminance);
                // ʹ��_Saturation�ڣ�ԭ��ɫ������ϵ�����ͣ�ʹ������ֵ�����ı��Ͷ�Ϊ0����ɫֵ��֮����в�ֵ���Ӷ��õ�ϣ���ı��Ͷ���ɫ
                finalColor = lerp(luminanceColor, finalColor, _Saturation);
                
                //3. �Աȶȵ���
                // �ȴ���һ���Աȶ�Ϊ0����ɫֵ��������=0.5�Ļ�ɫ��
                fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
                // ʹ��_Contrast��...��...֮����в�ֵ���Ӷ��õ����յ���ɫ
                finalColor = lerp(avgColor, finalColor, _Contrast);

                return fixed4(finalColor, renderTex.a); //͸������ԭ��Ļͼ�񱣳�һ��
            }
            ENDCG
        }
    }
    Fallback Off
}
// �о���������ȡ����Ͷȡ��Աȶȵ����漰����Ӧ�����ۡ������пյ����������һ��
// 
// ��֪��Ϊʲô����������ܿ�����������ȫ������һ�£�����Ч��������Щ��һ��������������
