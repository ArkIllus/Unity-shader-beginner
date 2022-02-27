Shader "Unity Shaders Book/Chapter 13/Fog With Depth Texture" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_FogDensity("Fog Density", Float) = 1.0 //��OnRenderImage�б�����
		_FogColor("Fog Color", Color) = (1, 1, 1, 1) //��OnRenderImage�б�����
		_FogStart("Fog Start", Float) = 0.0 //��OnRenderImage�б�����
		_FogEnd("Fog End", Float) = 1.0 //��OnRenderImage�б�����
	}
	SubShader {
		//ʹ��CGINCLUDE����֯���� Ŀ�ģ���������ظ�
		CGINCLUDE
		
		#include "UnityCG.cginc"

		float4x4 _FrustumCornersRay; //�ű��������ľ���û���� Properties ��������

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture; //Unity���ݸ����ǵ��������û���� Properties ��������
		half _FogDensity;
		fixed4 _FogColor;
		float _FogStart;
		float _FogEnd;
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1; //ר�����ڶ���������������������
			float4 interpolatedRay : TEXCOORD2; //�洢��ֵ�����������
		};

		v2f vert(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);

			o.uv = v.texcoord;
			o.uv_depth = v.texcoord;

			//ͬʱ���������Ⱦ���� + ����ݣ���ʱ��Ҫ��DirectX������ƽ̨����ת���⣨����ƽ̨���컯����
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				o.uv_depth.y = 1 - o.uv_depth.y;
			#endif

			// Unity �У����������(0, 0) ���Ӧ�����½ǣ���(1, 1) ���Ӧ�����Ͻǡ�
			//���Ǿݴ����жϸö����Ӧ�������������Ӧ��ϵ�������ڽű��ж� frustumCorners��ֵ˳����һ�µ�
			int index = 0;
			if (v.texcoord.x < 0.5 && v.texcoord.y < 0.5) {
				index = 0;
			}
			else if (v.texcoord.x > 0.5 && v.texcoord.y < 0.5) {
				index = 1;
			}
			else if (v.texcoord.x > 0.5 && v.texcoord.y > 0.5) {
				index = 2;
			}
			else {
				index = 3;
			}

			//���� DirectX��Metal ������ƽ̨�����ϽǶ�Ӧ��(0, 0) ��
			//ͬʱ���������Ⱦ���� + ����ݣ���ʱ��Ҫ��DirectX������ƽ̨����ת���⣨����ƽ̨���컯����
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				index = 3 - index;
			#endif

			//���ʹ������ֵ��ȡ_FrustumCornersRay�ж�Ӧ������Ϊ�ö����interpolatedRayֵ
			o.interpolatedRay = _FrustumCornersRay[index];

			return o;
		}
		//������������ʹ���˺ܶ��ж���䣬��������Ļ�������õ�ģ����һ���ı�������ֻ����
		//4�����㣬�����Щ���������������ɺܴ�Ӱ��

		fixed4 frag(v2f i) : SV_Target{
			//�ӽǿռ��µ��������ֵ��SAMPLE_DEPTH_TEXTURE+ LinearEyeDepth��
			float linearDepth = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth));
			//����ռ��µ�λ�� = ����ռ��µ��������λ�� + �ӽǿռ��µ��������ֵ * �����ص�interpolatedRayֵ��������ɫ���������ֵ��õ������ߣ����������ص�������ķ��򡢾�����Ϣ��
			float3 worldPos = _WorldSpaceCameraPos + linearDepth * i.interpolatedRay.xyz;

			//������ ���ڸ߶ȵ���Чģ��
			float fogDensity = (_FogEnd - worldPos.y) / (_FogEnd - _FogStart);
			fogDensity = saturate(fogDensity * _FogDensity);

			fixed4 finalColor = tex2D(_MainTex, i.uv);
			finalColor.rgb = lerp(finalColor.rgb, _FogColor.rgb, fogDensity);

			return finalColor;
		}
		
		ENDCG
		
		Pass {      
			ZTest Always Cull Off ZWrite Off //��Ļ����shader�ı��� //��Ȳ��Եĺ���������ͨ�� �ر��޳� �ر����д��
			    	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment frag  
			  
			ENDCG  
		}
	} 
	FallBack Off
}

//���ڽ��ܵ�ʹ����������ؽ����ص���������ķ����Ƿǳ����õġ�����Ҫע����ǣ�����
//��ʵ���ǻ����������ͶӰ������͸��ͶӰ��ǰ���¡������Ҫ������ͶӰ��������ؽ�������
//�꣬��Ҫʹ�ò�ͬ�Ĺ�ʽ