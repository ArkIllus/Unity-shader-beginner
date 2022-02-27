Shader "Unity Shaders Book/Chapter 5/Simple Shader"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _Color("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0) // ��ɫ
    }
        SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //// POSITION: ��ģ�͵Ķ���������䵽�������v��
            //// SV_POSITION: ������ɫ��������ǲü��ռ��еĶ�������
            //float4 vert(float4 v : POSITION) : SV_POSITION {
            //    //return mul(UNITY_MATRIX_MVP, v);
            //    // �Ѷ��������ģ�Ϳռ�ת�����ü��ռ���
            //    return UnityObjectToClipPos(v);
            //}
            //
            //// SV_TARGET: ������Ⱦ�������û��������ɫ�洢��һ����ȾĿ�꣨render target���У�
            //// ���ｫ�����Ĭ�ϵ�֡������
            //fixed4 frag() : SV_TARGET {
            //    //return fixed4(1.0, 1.0, 1.0, 1.0); // ��ɫ
            //    return fixed4(0.0, 0.0, 0.0, 1.0); // ��ɫ
            //}

            //��CG�����У� ������Ҫ����һ�����������ƺ����Ͷ�ƥ��ı���
            fixed4 _Color;

            // application to vertex shader
            struct a2v {
                // POSITION: ��ģ�Ϳռ�Ķ���������䵽�������v��
                float4 vertex : POSITION;
                // NORMAL: ��ģ�Ϳռ�ķ��߷�����䵽�������normal��
                float3 normal : NORMAL;
                // TEXCOORD0: ��ģ�͵ĵ�һ������������䵽�������texcoord��
                float4 texcoord : TEXCOORD0;
            };
            
            // vertex shader to fragment shader
            struct v2f {
                // SV_POSITION: ����unity��pos�����˲ü��ռ��еĶ�������
                float4 pos : SV_POSITION;
                // COLOR0: ���ڴ洢��ɫ��Ϣ
                fixed3 color : COLOR0;
            };

            //// SV_POSITION: ������ɫ��������ǲü��ռ��еĶ�������
            //float4 vert(a2v v) : SV_POSITION{
            //    return UnityObjectToClipPos(v.vertex);
            //}

            v2f vert(a2v v) { // ����������v2f�����Բ����� SV_POSITON:
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // v.normalΪ����ķ��߷��򣬷�����Χ��[-1.0, 1.0]
                // ����Ĵ���ѷ�����Χӳ�䵽��[0.0, 1.0]
                // �洢��o.color�д��ݸ�ƬԪ��ɫ��
                o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
                return o;
            }

            // SV_TARGET: ������Ⱦ�������û��������ɫ�洢��һ����ȾĿ�꣨render target���У�
            // ���ｫ�����Ĭ�ϵ�֡������
            fixed4 frag(v2f i) : SV_TARGET{
                // ����ֵ���i.color��ʾ����Ļ��
                fixed3 c = i.color;
                // ʹ��_Color���ԣ���rgb�������������ɫ
                c *= _Color.rgb;
                return fixed4(c, 1.0);
            }
            //��Ҫע����ǣ� ������ɫ�����𶥵���õģ� ��ƬԪ��ɫ������ƬԪ���õġ�
            //ƬԪ��ɫ���е�����ʵ�����ǰѶ�����ɫ����������в�ֵ��õ��Ľ����

            ENDCG
        }
    }
}
