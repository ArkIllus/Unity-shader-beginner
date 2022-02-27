//����ѭ����������
//�ο�����

Shader "Unity Shaders Book/Chapter 11/Scrolling Background" 
{
    Properties
    {
        //_MainTex _DetailTex �ֱ��ǵ�һ�㣨��Զ���͵ڶ��㣨�Ͻ����ı���������
        //_ScrollX��_Scroll2X ��Ӧ�˸��Ե�ˮƽ�����ٶȡ�_Multiplier ���������ڿ���������������ȡ�
        _MainTex("Base Layer (RGB)", 2D) = "white" {}
        _DetailTex("2nd Layer (RGB)", 2D) = "white" {}
        _ScrollX("Base layer Scroll Speed", Float) = 1.0
        _Scroll2X("2nd layer Scroll Speed", Float) = 1.0
        _Multiplier("Layer Multiplier", Float) = 1
    }
    SubShader
    {
        Tags { "Queue"="Geometry" "RenderType"="Opaque" }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" } //ǰ����Ⱦ

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _DetailTex;
            float4 _MainTex_ST;
            float4 _DetailTex_ST;
            float _ScrollX;
            float _Scroll2X;
            float _Multiplier;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0; //�������������������洢��ͬһ������ o.uv �У��Լ���ռ�õĲ�ֵ�Ĵ����ռ䡣
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                //o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                //�������õ�_Time.y ������ˮƽ�����϶������������ƫ��
                //frac�������ر�����ÿ��ʸ���и�������С������
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + frac(float2(_ScrollX, 0.0) * _Time.y);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + frac(float2(_Scroll2X, 0.0) * _Time.y);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //�����ű���������в���
                fixed4 firstLayer = tex2D(_MainTex, i.uv.xy);
                fixed4 secondLayer = tex2D(_DetailTex, i.uv.zw);

                //ʹ�õڶ��������͸��ͨ�����������������ʹ���� CG lerp ����
                fixed4 c = lerp(firstLayer, secondLayer, secondLayer.a);
                //�������ʹ��_Multiplier �����������ɫ������ˣ��Ե����������ȡ�
                c.rgb *= _Multiplier;

                return c;

                return c;
            }

            ENDCG
        }
    }
    FallBack "VertexLit"
}