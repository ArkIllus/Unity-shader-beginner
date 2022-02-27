//Blinn-Phong ����ģ�� (��ƬԪ) + ��������

//ʹ�ý���������������������յĽ����

// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 7/Ramp Texture"
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        // ֻ��һ����������
        _RampTex("Ramp Tex", 2D) = "white" {}
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
            sampler2D _RampTex;
            float4 _RampTex_ST; // ����scale��.xy�� ƽ��/ƫ��translation��.zw��
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0; //��һ��...
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;  
                float2 uv : TEXCOORD2; //ֻ��һ������
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                o.worldNormal = UnityObjectToWorldNormal(v.normal);

                //o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv = TRANSFORM_TEX(v.texcoord, _RampTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));

                //û�з�������(normal map)
                fixed3 worldNormal = normalize(i.worldNormal);

                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                //��������(Half Lambert)
                //��dot(n,l)�Ľ����Χ��[-1,-1]ӳ�䵽[0,1]
                fixed halfLambert = 0.5 * dot(worldNormal, worldLightDir) + 0.5;
                //ʹ��halfLambert����һ����������(halfLambert, halfLambert)�����������������Խ�������_RampTex���в�����
                //����_RampTex ʵ�ʾ���һ��һά�����������᷽������ɫ���䣩��������������u��v�������Ƕ�ʹ����halfLambert��
                //Ȼ��Ѵӽ�����������õ�����ɫ�Ͳ�����ɫ_Color��ˣ��õ����յ���������ɫ��
                fixed3 diffuseColor = tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;

                // ����ʹ�ò����������ɫ����_Color �ĳ˻�����Ϊ���ʵķ�����albedo
                //fixed3 albedo = tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                //fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;
                //��
                //fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * tex2D(_MainTex, i.uv).rgb * _Color.rgb;
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // ֮ǰ�������������ʱ ���������漸�ַ���
                // ��ʹ�ñ��淨�ߺ͹��շ���ĵ���������ʵ�������ϵ��_Diffuse����Դ��ɫ������õ���������������
                //fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                // ��ʹ�ñ��淨�ߺ͹��շ���ĵ���������ʵķ�����albedo��_MainTex��������õ�������Դ��ɫ������õ���������������
                //fixed3 diffuse = _LightColor0.rgb * albedo * max(0, dot(worldNormal, worldLightDir));
                //��
                //fixed3 diffuse = _LightColor0.rgb * tex2D(_MainTex, i.uv).rgb * _Color.rgb * max(0, dot(normal, worldLightDir));
                //���ڣ�����ʹ�ý���������������������յĽ������Half Lambert+�������������
                fixed3 diffuse = _LightColor0.rgb * diffuseColor;
                //��
                //fixed3 diffuse = _LightColor0.rgb * tex2D(_RampTex, fixed2(halfLambert, halfLambert)).rgb * _Color.rgb;

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, worldHalfDir)), _Gloss);

                return fixed4(ambient + diffuse + specular, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
