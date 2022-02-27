//Blinn-Phong ����ģ�� (��ƬԪ) + ����

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Single Texture"
{
    Properties
    {
        //_Diffuse("Diffuse", Color) = (1, 1, 1, 1) //ʹ�������_Color��������������ɫ��ϵ����
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex("Main Tex", 2D) = "white"{}
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Pass
        {
            Tags { "LightMode" = "ForwardBase" } //ǰ����Ⱦ

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc" // for _LightColor0

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; // ����scale��.xy�� ƽ��/ƫ��translation��.zw��
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0; //��һ����������
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0; //����TEXCOORDn����������
                float4 worldPos : TEXCOORD1;
                float2 uv : TEXCOORD2; //�洢��������ı���uv���Ա�ƬԪ��ɫ����ʹ�ø���������������
            };

            v2f vert (a2v v)
            {
                v2f o;
                // ���� from object space to projection space // ��MVP����任
                o.pos = UnityObjectToClipPos(v.vertex);

                // ����ռ��µ� ���㷨�ߣ�ʹ�����ú�����
                //o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                // ����ռ��µ� ����λ�ã���������Ȳ�normalize��������
                o.worldPos = mul(unity_ObjectToWorld, v.vertex);

                // �ȶԶ�����������������ţ�.xy�����ٽ���ƫ�ƣ�.zw��
                o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                // Or just call the built-in function
                //o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                // ʹ������������ �� _Color �õ� ���ʵķ�����albedo������������ϵ��_Diffuse��
                // 
                // tex2D��������������в���
                // tex2D(sampler2D ����tex,float2 ��������uv) 
                // return float4 ���ؼ���õ�������ֵ(�������ݵ�ֵ)
                // 
                // ����ʹ�ò����������ɫ����_Color �ĳ˻�����Ϊ���ʵķ�����albedo
                fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;

                // �������� //ע�⣺��Ҫ������ʵ�LightMode��ǩ
                // ��albedo�ͻ���������˵õ������ⲿ��
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                // ����ռ��µ� ����
                fixed3 worldNormal = normalize(i.worldNormal);
                // ����ռ��µ� ���߷����Ѿ�ȡ���ˣ���
                //fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);//ע�⣺���賡����ֻ��һ����Դ�Ҹù�Դ��������ƽ�й�
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos)); //ע�⣺��������ǰ����Ⱦ

                // �������� // ���ʵķ�����albedo������������ϵ��_Diffuse
                //fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));

                // ����ռ��µ� �۲췽��v
                //fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                // ����ռ��µ� �뷽��h
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                // ���淴���� (����Blinn-Phongģ�ͣ�dot(n,h))
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
