//���㶯�� ģ�������ĺ���
//�ο���Chapter8-AlphaBlend

Shader "Unity Shaders Book/Chapter 11/Water" 
{
    Properties
    {
        //_MainTex �Ǻ������� _Color ���ڿ���������ɫ�� _Magnitude ���ڿ���ˮ�������ķ��ȣ�
        //_Frequency ���ڿ��Ʋ���Ƶ�ʣ�_InvWaveLength ���ڿ��Ʋ����ĵ���(_InvWaveLength Խ�󣬲���ԽС����
        //_Speed ���ڿ��ƺ���������ƶ��ٶȡ�
        _MainTex("Main Tex", 2D) = "white" {}
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _Magnitude("Distortion Magnitude", Float) = 1
        _Frequency("Distortion Frequency", Float) = 1
        _InvWaveLength("Distortion Inverse Wave Length", Float) = 10
        _Speed("Speed", Float) = 0.5
    }
    SubShader
    {
        //���������һ���µı�ǩ��DisableBatching
        // 
        //һЩSubShader��ʹUnity ����������ʱ��������⣬��ʱ����ͨ���ñ�ǩ��ֱ��ָ���Ƿ�Ը� SubShader ʹ��������
        //����Щ��Ҫ���⴦��� Shader ͨ������ָ������ģ�Ϳռ�Ķ��㶯���� Shader ��
        //������Ϊ���������ϲ�������ص�ģ�ͣ�����Щģ�͸��Ե�ģ�Ϳռ�ͻᶪʧ��
        //���ڱ����У�������Ҫ�������ģ�Ϳռ��¶Զ���λ�ý���ƫ�ơ���ˣ���������Ҫȡ���Ը� Shader �������������
        //���������Ǻܶ�������
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}

        Pass
        {
            Tags { "LightMode" = "ForwardBase" } //ǰ����Ⱦ

            ZWrite Off //�ر����д��
            Blend SrcAlpha OneMinusSrcAlpha //���������������á���Pass�Ļ��ģʽ
            //��Դ��ɫ����ƬԪ��ɫ����������ɫ���Ļ��������Ϊ SrcAlpha, 
            //��Ŀ����ɫ���Ѿ���������ɫ�����е���ɫ���Ļ��������ΪOneMinusSrcAlpha
            //��Ϻ������ɫ��
            //DstColor_new = SrcAlpha * SrcColor + (1-SrcAlpha) * DstColor_old
            Cull Off //�ر����޳����ܡ�����Ϊ����ˮ����ÿ���涼����ʾ

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _Magnitude;
            float _Frequency;
            float _InvWaveLength;
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

                //���ȼ��㶥��λ���� ����ֻϣ���Զ����x�������λ��
                float4 offset;
                offset.yzw = float3(0.0, 0.0, 0.0);
                //����_Frequency ���Ժ����õ� _Time.y ��Ĺ���������Һ�����Ƶ��
                //Ϊ���ò�ͬλ�þ��в�ͬ��λ�ƣ����Ƕ��������������ģ�Ϳռ��µ�λ�÷�����������_Inv WaveLength���Ʋ�����
                //������ǶԽ��ֵ����_Magnitude �����Ʋ������ȣ��õ����յ�λ�ơ�
                offset.x = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
                //��λ����ӵ�����λ���� �ٽ��������Ķ���任���ɡ�
                o.pos = UnityObjectToClipPos(v.vertex + offset);

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                //����������������ʹ��_Time.y��_Speed ��������ˮƽ�����ϵ���������
                o.uv += float2(0.0, _Time.y * _Speed);

                return o;
            }

            //ֻ��Ҫ����������������ɫ���Ƽ���
            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 c = tex2D(_MainTex, i.uv);
                c.rgb *= _Color.rgb;

                return c;
            }

            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}

// CV