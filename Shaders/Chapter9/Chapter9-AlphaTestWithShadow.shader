//���������ģ�� (��ƬԪ)�������߹ⷴ�䣩 + ������ + ͸���Ȳ��� 

Shader "Unity Shaders Book/Chapter 9/Alpha Test With Shadow"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1) //��������� ���������䡢������
        _MainTex("Main Tex", 2D) = "white"{}
        _Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5 //���ھ������ǵ��� clip ����͸���Ȳ���ʱʹ�õ��ж�����
    }
    SubShader
    {
        Tags {"Queue" = "AlphaTest" "IgnoreProjector" = "True" "RenderType" = "TransparentCutout"}
        //AlphaTest:Unity�������Ⱦ���У���Ҫ͸���Ȳ��Ե�����ʹ�øö���
        //IgnoreProjector ����Ϊ True, ����ζ����� Shader �����ܵ�ͶӰ�� (Projectors) ��Ӱ��
        //RenderType��ǩ������Unity�����Shader���뵽��ǰ������飨TransparentCutout�飩�У�
        //��ָ����shader��һ��ʹ����͸���Ȳ��Ե�shader��RenderType��ǩͨ����������ɫ���滻���ܡ�

        Pass
        {
            Tags { "LightMode" = "ForwardBase" } //ǰ����Ⱦ

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc" // for _LightColor0
            #include "AutoLight.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; //������Properties����
            fixed _Cutoff;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
                SHADOW_COORDS(3) // �������Ѿ�ռ����3����ֵ�Ĵ�����ʹ�� TEXCOORDO TEXCOORDl
                    //TEXCOORD2 ���εı���������� SHADOW_COORDS �д���Ĳ�����3 ����ζ�ţ���Ӱ����
                    //���꽫ռ�õ��ĸ���ֵ�Ĵ��� TEXCOORD
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                TRANSFER_SHADOW(o);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);

                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed4 texColor = tex2D(_MainTex, i.uv);

                //Alpha Test
                clip(texColor.a - _Cutoff);
                //Equal to
                //if (texColor.a - _Cutoff < 0.0) {
                //    discard; //�޳���ƬԪ
                //}

                // ������ϵ�� / Ҳ�з����� (��Ӱ�컷���⡢�������)(�����������д�����_diffuse)
                fixed3 albedo = texColor.rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                return fixed4(ambient + diffuse, 1.0);
            }

            ENDCG
        }
    }

    //FallBack "VertexLit" //��ʹ�����õ� VertexLit ���ṩ��ShadowCaster ��Ͷ����Ӱ������� Pass �в�û�н����κ�͸���Ȳ��Եļ��㣬

    FallBack "Transparent/Cutout/VertexLit"
    //�ⲻ���ܹ���֤�����Ǳ�д�� SubShader �޷��ڵ�ǰ�Կ��Ϲ���ʱ�����к��ʵĴ��� Shader, 
    //�����Ա�֤ʹ��͸���Ȳ��Ե����������ȷ������������Ͷ����Ӱ
}

//�����Ľ����Ȼ��һЩ���⣬�������һЩ��Ӧ��͸����Ĳ��֡� �������������
//ԭ���ǣ�Ĭ������°�������Ⱦ�����ͼ����Ӱӳ�������н�������������� �������ڱ�������
//������˵����һЩ����ȫ���Թ�Դ �������Щ��������Ϣû�м��뵽��ӳ������ļ����С�
//Ϊ�˵õ���ȷ��������ǿ��Խ�������� Mesh Renderer ����е� Cast Shadows ��������Ϊ ��Two Sided��,
// ǿ�� Unity �ڼ�����Ӱӳ������ʱ����������������Ϣ��