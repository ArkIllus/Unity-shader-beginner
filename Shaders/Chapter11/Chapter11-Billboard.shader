//���㶯�� �����
//�ο���Chapter11-Water

Shader "Unity Shaders Book/Chapter 11/Billboard" {
    Properties{
        _MainTex("Main Tex", 2D) = "white" {}
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _VerticalBillboarding("Vertical Restraints", Range(0,1)) = 1 // ���ڵ����ǹ̶����߻��ǹ̶�ָ���ϵķ��򣬼�Լ����ֱ����ĳ̶ȡ�
                                                                     // =1 �̶����߷���Ϊ�۲��ӽ� // =0 �̶�ָ���ϵķ���Ϊ(0,1,0)
    }
    SubShader
    {
        //���������һ���µı�ǩ��DisableBatching
        // 
        //һЩSubShader��ʹUnity����������ʱ��������⣬��ʱ����ͨ���ñ�ǩ��ֱ��ָ���Ƿ�Ը� SubShader ʹ��������
        //����Щ��Ҫ���⴦��� Shader ͨ������ָ������ģ�Ϳռ�Ķ��㶯����Shader��
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
            Cull Off //�ر����޳����ܡ�����Ϊ���ù���Ƶ�ÿ���涼����ʾ

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //#include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed _VerticalBillboarding;

            struct a2v {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // ���м��㶼���ڡ�ģ�Ϳռ䡿�½��е�
            v2f vert(a2v v)
            {
                v2f o;

                //ѡ��ģ�Ϳռ��ԭ����Ϊ����Ƶ�ê��
                float3 center = float3(0, 0, 0);
                //ģ�Ϳռ��µ��ӽ�λ��
                float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));

                //Ŀ�귨�߷���
                float3 normalDir = viewer - center;
                //����_VerticalBillboarding ���������ƴ�ֱ����(y����)�ϵ�Լ���ȡ�
                // If _VerticalBillboarding equals 1, we use the desired view dir as the normal dir
                // Which means the normal dir is fixed
                // Or if _VerticalBillboarding equals 0, the y of normal is 0
                // Which means the up dir is fixed
                normalDir.y = normalDir.y * _VerticalBillboarding;
                normalDir = normalize(normalDir);
                //������Ե����Ϸ���ֻ���� = ����(0, 1, 0) or ��ǰ(0, 0, 1)��������
                // Get the approximate up dir
                // If normal dir is already towards up, then the up dir is towards front
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                //���Ե����Ϸ��� ��� Ŀ�귨�߷��� �õ� ���ҷ��� ����������
                float3 rightDir = normalize(cross(upDir, normalDir));
                //��ʱ���Ϸ����ǲ�׼ȷ�ģ�����׼ȷ�ķ��߷�������ҷ���õ��������Ϸ��� ����������
                upDir = normalize(cross(normalDir, rightDir));

                //�õ��������3������������
                //����ԭʼλ�������ê���ƫ���� �Լ� 3�������������������µĶ���λ��
                // Use the three vectors to rotate the quad
                float3 centerOffs = v.vertex.xyz - center; //��v.vertexҲ��ģ�Ϳռ��µ����꣩
                float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;

                o.pos = UnityObjectToClipPos(float4(localPos, 1));
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
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

//������������У�����ʹ�õ����Դ����ı���(Quad) ����Ϊ����ƣ�������ʹ���Դ���ƽ��(Plane)��
//������Ϊ�����ǵĴ����ǽ����ڡ�һ����ֱ�ڷŵĶ���Ρ��Ļ����ϵģ�
//Ҳ����˵���������εĶ���ṹ��Ҫ������ģ�Ϳռ�������ֱ���еġ�
//ֻ�����������ǲ���ʹ��v.vertex ������õ���ȷ����������ĵ�λ��ƫ������

//���㶯����ע��������԰棩��
// 1.������ DisableBatching
// 2.�����Ӱ ���õ�ShadowCaster Pass��û�н�����صĶ��㶯�������Unity��Ȼ�ᰴ��ԭ���Ķ���λ����������Ӱ
// 
//��ǰ���ʵ���У�����漰��͸���������Ƕ��� Fallback ���ó��� Transparent / VertexLit,
//Transparent / VertexLit û�ж��� ShadowCaster Pass, ���Ҳ�Ͳ��������Ӱ