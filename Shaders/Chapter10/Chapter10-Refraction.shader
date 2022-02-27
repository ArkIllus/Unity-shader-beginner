//���������ģ�� (��ƬԪ)�������߹ⷴ�䣬��refraction� + ͳ���������˥������Ӱ��ʹ�ú꣩ + ǰ����Ⱦ������ͬ���͵Ĺ�Դ������ֻ��ƽ�й⣩

//Ϊǰ����Ⱦ������ Base Pass �� AdditionalPass ����������Դ

// ����ӳ���Ӧ�ã�����

Shader "Unity Shaders Book/Chapter 10/Refraction"
{
    Properties
    {
        _Color("Color Tint",Color) = (1, 1, 1, 1)
        _RefractColor("Refraction Color",Color) = (1, 1, 1, 1) //���ڿ���ɢ����ɫ
        _RefractAmount("Refraction Amount",Range(0,1)) = 1 //���ڿ���������ʵ�ɢ��̶�
        _RefractRatio("Refraction Ratio",Range(0.1, 1)) = 0.5 //����������ڽ��ʵ������ʺ�����������ڽ��ʵ�������֮��ı�ֵ
                                                              //�����1����ô���������߾���û�з������䣬��ԭ���ķ��򴩹����������һ��
        _Cubemap ("Refraction Cubemap", Cube) = "_Skybox" {} //����ģ��ɢ��Ļ���ӳ������
    }
    SubShader
    {
        //���ࣺ��͸��    ��Ⱦ���У�Ĭ�ϣ�2000������������塣��͸�����塣��
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry"}

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            #pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc"

            fixed4 _Color;
            fixed4 _RefractColor;
            float _RefractAmount;
            fixed _RefractRatio;
            samplerCUBE _Cubemap; // samplerCUBE ?????????

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldPos : TEXCOORD0;
                fixed3 worldNormal : TEXCOORD1;
                fixed3 worldViewDir : TEXCOORD2;
                fixed3 worldRefr : TEXCOORD3;
                SHADOW_COORDS(4) //����� ����һ�����ڶ���Ӱ������������ꡣ
                                 //ʵ���Ͼ��������� һ����Ϊ_ShadowCoord ����Ӱ�����������
                                 //��Ӱ����/���꽫ռ�õ��ĸ���ֵ�Ĵ��� TEXCOORD
            };

            // �ڶ�����ɫ���м����˸ö��㴦��ɢ�䷽������ͨ��ʹ�� refract ������ʵ�ֵ�
			v2f vert(a2v v) {
				v2f o;

				o.pos = UnityObjectToClipPos(v.vertex);

				o.worldNormal = UnityObjectToWorldNormal(v.normal);

				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

				o.worldViewDir = UnityWorldSpaceViewDir(o.worldPos);

				// Compute the refract dir in world space //ע�⸺�ţ������һ����
                // refract �����ĵ����������� ����������ڽ��ʵ������ʺ�����������ڽ��ʵ�������֮��ı�ֵ
				o.worldRefr = refract(-normalize(o.worldViewDir), normalize(o.worldNormal), _RefractRatio);

				TRANSFER_SHADOW(o); //����������ڶ�����ɫ���м���v2f����������Ӱ�������ꡣ
                                    //��Ѷ��������ģ�Ϳռ�任����Դ�ռ��洢�� _ShadowCoord��

				return o;
			}

            // ��ƬԪ��ɫ���У�����ɢ�䷽���������������������
			fixed4 frag(v2f i) : SV_Target{
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
				fixed3 worldViewDir = normalize(i.worldViewDir);

				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * max(0, dot(worldNormal, worldLightDir));

				// Use the refract dir in world space to access the cubemap
				//������������Ĳ�����Ҫʹ�� CG �� texCUBE ����     ����_refractColor���ڿ��Ʒ�����ɫ��
				fixed3 refraction = texCUBE(_Cubemap, i.worldRefr).rgb * _RefractColor.rgb;

                //������˥������Ӱֵ��˺�Ľ���洢����һ�����С�
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				// Mix the diffuse color with the refracted color
				//����ʹ��_refractAmount�����(lerp����)��������ɫ�ͷ�����ɫ����atten��Դ�Ĺ���˥���������ͻ���������Ӻ󷵻أ�û�и߹��
				fixed3 color = ambient + lerp(diffuse, refraction, _RefractAmount) * atten;

				return fixed4(color, 1.0);
			}

            ENDCG
	    }
	}
	FallBack "Reflective/VertexLit"
}
//������ļ����У�����ѡ���ڶ�����ɫ���м���ɢ�䷽�򡣵�Ȼ������Ҳ����ѡ����ƬԪ��
//ɫ���м��㣬�����õ���Ч������ϸ�塣���ǣ���ǧ�����������˵���ֲ�������ǿ��Ժ��Բ�
//�Ƶģ���˳������ܷ���Ŀ��ǣ�����ѡ���ڶ�����ɫ���м���ɢ�䷽��

//�ġ���һ��͸��������˵��һ�ָ�׼ȷ��ģ�ⷽ����Ҫ�����������䡣
//�����ǵ����߽��������ڲ�ʱ������һ�����Ǵ����ڲ����ʱ��
//���ǣ���Ҫ��ʵʱ��Ⱦ��ģ����ڶ������䷽���ǱȽϸ��ӵģ����ҽ���ģ��һ�εõ���Ч�����Ӿ��Ͽ�������Ҳͦ����ô���µġ���
//��������֮ǰ�ᵽ��һͼ��ѧ��һ׼��������������ǶԵģ���ô�����ǶԵġ���
//��ˣ���ʵʱ��Ⱦ������ͨ����ģ���һ������