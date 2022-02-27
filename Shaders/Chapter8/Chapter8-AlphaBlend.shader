//���������ģ�� (��ƬԪ)�������߹ⷴ�䣩 + ������ + ͸���Ȼ��

Shader "Unity Shaders Book/Chapter 8/Alpha Blend"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1) //��������� ���������䡢������
        _MainTex("Main Tex", 2D) = "white"{}
        _AlphaScale("Alpha Scale", Range(0, 1)) = 1 //��͸������Ļ����� �ֶ�����͸���̶�
    }
    SubShader
    {
        Tags {"Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
        //Transparent:Unity�������Ⱦ���У���Ҫ͸���Ȼ�ϵ�����ʹ�øö���
        //IgnoreProjector ����Ϊ True, ����ζ����� Shader �����ܵ�ͶӰ�� (Projectors) ��Ӱ��
        //RenderType��ǩ������Unity�����Shader���뵽��ǰ������飨Transparent�飩�У�
        //��ָ����shader��һ��ʹ����͸���Ȼ�ϵ�shader��RenderType��ǩͨ����������ɫ���滻���ܡ�

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

            #include "Lighting.cginc" // for _LightColor0

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; //������Properties����
            fixed _AlphaScale;

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
                
                // ������ϵ�� / Ҳ�з����� (��Ӱ�컷���⡢�������)(�����������д�����_diffuse)
                fixed3 albedo = texColor.rgb * _Color.rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                //return fixed4(ambient + diffuse, 1.0);
                // ʹ���������Alphaͨ��ֵ �� _AlphaScale ��� ��Ϊ�����͸����
                return fixed4(ambient + diffuse, texColor.a * _AlphaScale);
            }

            ENDCG
        }
    }
    //FallBack "Transparent/Cutout/VertexLit"
    FallBack "Transparent/VertexLit"
}

//��ģ�ͱ����и��ӵ��ڵ���ϵ���ǰ����˸��ӵķ�͹�����ʱ��
//�ͻ��и��ָ�����Ϊ��������󡿶������Ĵ����͸��Ч����
//�ⶼ���������ǡ��ر������д�롿��ɵģ���Ϊ�������Ǿ��޷���ģ�ͽ������ؼ�����������
//
//8.1 ���������ᵽ��һ�ֽ�������Ƿָ����񣬴Ӷ����Եõ� ���������ŵȡ�������
//���Ǻܶ�������������ǲ���ʵ�ʵġ�
//
//��ʱ�����ǿ�����취�����������д�룬��ģ�Ϳ������͸�������������е��뵭����
//�������������Ҫ�������ݡ�