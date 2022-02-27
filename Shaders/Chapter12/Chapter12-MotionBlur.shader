Shader "Unity Shaders Book/Chapter 12/Motion Blur" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_BlurAmount ("Blur Amount", Float) = 1.0 //��OnRenderImage�б�����
	}
	SubShader {
		//ʹ��CGINCLUDE����֯���� Ŀ�ģ���������ظ�
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		fixed _BlurAmount;
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
		};
		
		v2f vert(appdata_img v) {
			v2f o;
			
			o.pos = UnityObjectToClipPos(v.vertex);
			
			o.uv = v.texcoord;
					 
			return o;
		}

		//����������ƬԪ��ɫ��
		//һ�����ڸ�����Ⱦ����� RGB ͨ������ 
		fixed4 fragRGB (v2f i) : SV_Target {
			//RGB ͨ���汾�� Shader �Ե�ǰͼ����в�����
			//������ A ͨ����ֵ��Ϊ_BlurAmount, �Ա��ں�����ʱ����ʹ������͸��ͨ�����л��
			return fixed4(tex2D(_MainTex, i.uv).rgb, _BlurAmount);
		}

		//һ�����ڸ�����Ⱦ����� A ͨ������
		half4 fragA (v2f i) : SV_Target {
			//ֱ�ӷ��ز�������� 
			//ʵ���ϣ� ����汾ֻ��Ϊ��ά����Ⱦ�����͸��ͨ��ֵ�� �������ܵ����ʱʹ�õ�͸����ֵ��Ӱ�졣����
			return tex2D(_MainTex, i.uv);
		}
		
		ENDCG
		
		ZTest Always Cull Off ZWrite Off //��Ļ����shader�ı���
                                         //��Ȳ��Եĺ���������ͨ�� �ر��޳� �ر����д��
		
		//��Ҫ���� Pass, һ�����ڸ�����Ⱦ����� RGB ͨ���� ��һ�����ڸ��� A ͨ���� 
		//֮����Ҫ�� A ͨ���� RGB ͨ���ֿ��� ����Ϊ��
		//���� RGB ʱ������Ҫ�������� A ͨ�������ͼ�� ���ֲ�ϣ�� A ͨ����ֵд����Ⱦ�����С�
		Pass {
			Blend SrcAlpha OneMinusSrcAlpha //����ɫͨ����д����=RGB�� �µ���ɫ�����е���ɫ=ƬԪ��ɫ��Aͨ��ֵ+��ɫ�����е���ɫ(1-Aͨ��ֵ)
			ColorMask RGB
			
			CGPROGRAM
			
			#pragma vertex vert  
			#pragma fragment fragRGB  
			
			ENDCG
		}
		
		Pass {   
			Blend One Zero //����ɫͨ����д����=A���µ���ɫ�����е���ɫ=ƬԪ��ɫ������
			ColorMask A //
			   	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment fragA
			  
			ENDCG
		}
	}
 	FallBack Off
}
//�����Ƕ��˶�ģ����һ�ּ�ʵ�֡����ǻ��������֮֡���ͼ�������õ�һ�ž���ģ����β��ͼ��
//Ȼ�����������˶��ٶȹ���ʱ�����ַ������ܻ���ɵ�����֡ͼ���ÿɼ� 
//�ڵ�13 ���л�ѧϰ������á���������ؽ��ٶȡ���ģ���˶�ģ��Ч��