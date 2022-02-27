//���������ģ�� (��ƬԪ)�������߹ⷴ�䣩 + ������ + ͸���Ȳ��� ��˫����Ⱦ��

Shader "Unity Shaders Book/Chapter 8/Alpha Test"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1) //��������� ���������䡢������
        _MainTex("Main Tex", 2D) = "white"{}
        _Cutoff("Alpha Cutoff", Range(0, 1)) = 0.5 //���ھ������ǵ��� clip ����͸���Ȳ���ʱʹ�õ��ж�����
    }
    SubShader
    {
        Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
        //AlphaTest:Unity�������Ⱦ���У���Ҫ͸���Ȳ��Ե�����ʹ�øö���
        //IgnoreProjector ����Ϊ True, ����ζ����� Shader �����ܵ�ͶӰ�� (Projectors) ��Ӱ��
        //RenderType��ǩ������Unity�����Shader���뵽��ǰ������飨TransparentCutout�飩�У�
        //��ָ����shader��һ��ʹ����͸���Ȳ��Ե�shader��RenderType��ǩͨ����������ɫ���滻���ܡ�

        Pass
        {
            Tags { "LightMode" = "ForwardBase" } //ǰ����Ⱦ

            //͸���Ȳ��Ե�˫����Ⱦ ֻҪ��һ�У�
            //�ر��޳����ܣ�ʹ�ø���������е���ȾͼԪ���ᱻ��Ⱦ��
            Cull Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc" // for _LightColor0

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; //������Properties����
            fixed _Cutoff;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                //float4 tangent : TANGENT;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2;
                //float3 tangentLightDir : TEXCOORD1;
                //float3 tangentViewDir : TEXCOORD2;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

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

                return fixed4(ambient + diffuse, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Transparent/Cutout/VertexLit"
    //�ⲻ���ܹ���֤�����Ǳ�д�� SubShader �޷��ڵ�ǰ�Կ��Ϲ���ʱ�����к��ʵĴ��� Shader, 
    //�����Ա�֤ʹ��͸���Ȳ��Ե����������ȷ������������Ͷ����Ӱ
}

//͸���Ȳ��Եõ���͸��Ч���ܡ����ˡ�һһҪô��ȫ͸����Ҫô��ȫ��͸�� ��
//����Ч����������һ����͸������������ ���ն���
//���ң��õ���͸��Ч���ڱ�Ե�������β�룬�о�ݣ�������Ϊ�ڱ߽紦������͸���ȵı仯�������⡣s
//Ϊ�˵õ������Ử��͸��Ч�����Ϳ���ʹ��͸���Ȼ�ϡ�