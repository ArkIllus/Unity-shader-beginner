// ����

Shader "Unity Shaders Book/Chapter 10/Mirror"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {} //����Ӧ���ɾ����������Ⱦ�õ�����Ⱦ����
    }
    SubShader
    {
        //���ࣺ��͸��    ��Ⱦ���У�Ĭ�ϣ�2000������������塣��͸�����塣��
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry"}

        Pass
        {
            //Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            //#pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            //#include "Lighting.cginc"
            //#include "AutoLight.cginc"

            fixed4 _Color;
            fixed _FresnelScale;
            sampler2D _MainTex;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // ������������
            // ��תx�������������ꡣ��Ϊ��������ʾ��ͼ���������෴�ġ�
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = v.texcoord;
                // ������Ҫ��תx
                o.uv.x = 1 - o.uv.x;

				return o;
			}

            //����Ⱦ������в��������
            fixed4 frag(v2f i) : SV_Target{
                return tex2D(_MainTex, i.uv);
			}

            ENDCG
	    }
	}
	FallBack Off //???
}