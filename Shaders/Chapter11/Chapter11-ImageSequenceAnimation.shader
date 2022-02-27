//����֡����
//�ο���Chapter8-AlphaBlend

Shader "Unity Shaders Book/Chapter 11/Image Sequence Animation" 
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex("Main Tex", 2D) = "white"{} //���������йؼ�֡ͼ�������
        _HorizontalAmount("Horizontal Amount", Float) = 4 //��ˮƽ��������Ĺؼ�֡ͼ��ĸ���
        _VerticalAmount("Vertical Amount", Float) = 4 //����ֱ��������Ĺؼ�֡ͼ��ĸ���
        _Speed("Speed", Range(1, 100)) = 30 //���ڿ�������֡�����Ĳ����ٶȡ�
    }
    SubShader
    {
        //��������֡ͼ��ͨ��������͸��ͨ���� ��˿��Ա������� һ����͸������
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" } //ǰ����Ⱦ

            ZWrite Off //�ر����д��
            Blend SrcAlpha OneMinusSrcAlpha //���������������á���Pass�Ļ��ģʽ
            //��Դ��ɫ����ƬԪ��ɫ����������ɫ���Ļ��������Ϊ SrcAlpha, 
            //��Ŀ����ɫ���Ѿ���������ɫ�����е���ɫ���Ļ��������ΪOneMinusSrcAlpha
            //��Ϻ������ɫ��
            //DstColor_new = SrcAlpha * SrcColor + (1-SrcAlpha) * DstColor_old

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; //������Properties����
            float _HorizontalAmount;
            float _VerticalAmount;
            float _Speed;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //����ؼ�֡���ڵ�����������
                float time = floor(_Time.y * _Speed); //_Time.y��t���Ըó������ؿ�ʼ��������ʱ�䣬.y=t
                float row = floor(time / _HorizontalAmount);
                float column = time - row * _HorizontalAmount;

                //���������������������uv ��
				//half2 uv = float2(i.uv.x /_HorizontalAmount, i.uv.y / _VerticalAmount);
				//uv.x += column / _HorizontalAmount;
				//uv.y -= row / _VerticalAmount;
                //���Ӧ�����������ע�͵��Ĵ��벿�֡� ���ǿ��԰����������еĳ������ϵ�һ�𣬾͵õ���ע���·��Ĵ��� ��
                half2 uv = i.uv + half2(column, -row);
                uv.x /= _HorizontalAmount;
                uv.y /= _VerticalAmount;

                //����֡ͼ�����
                fixed4 c = tex2D(_MainTex, uv);
                c.rgb *= _Color;

                return c;
            }

            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}

//Chapter8-AlphaBlend:
//��ģ�ͱ����и��ӵ��ڵ���ϵ���ǰ����˸��ӵķ�͹�����ʱ��
//�ͻ��и��ָ�����Ϊ��������󡿶������Ĵ����͸��Ч����
//�ⶼ���������ǡ��ر������д�롿��ɵģ���Ϊ�������Ǿ��޷���ģ�ͽ������ؼ�����������
