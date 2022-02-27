Shader "Unity Shaders Book/Chapter 13/Edge Detection Normals And Depth" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_EdgeOnly("Edge Only", Float) = 1.0
		_EdgeColor("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor("Background Color", Color) = (1, 1, 1, 1)
		_SampleDistance("Sample Distance", Float) = 1.0
		_Sensitivity("Sensitivity", Vector) = (1, 1, 1, 1) //x,y�����ֱ��Ӧ���ֵ������ֵ��Sensitivity��z,w����=0����
		//��OnRenderImage�б�����
	}
	SubShader {
		//ʹ��CGINCLUDE����֯����
		CGINCLUDE
		
		#include "UnityCG.cginc"

		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		fixed _EdgeOnly;
		fixed4 _EdgeColor;
		fixed4 _BackgroundColor;
		float _SampleDistance;
		half4 _Sensitivity;

		sampler2D _CameraDepthNormalsTexture; //Unity���ݸ����ǵ��������û���� Properties ��������

		struct v2f {
			float4 pos : SV_POSITION;
			//half2 uv : TEXCOORD0;
			//half2 uv_depth : TEXCOORD1; //ר�����ڶ���������������������
			half2 uv[5] : TEXCOORD0;
		};

		//ͨ���Ѽ��������������Ĵ����ƬԪ��ɫ����ת�Ƶ�������ɫ���У����Լ������㣬������ܡ�
		//���ڴӶ�����ɫ����ƬԪ��ɫ���Ĳ�ֵ�����Եģ����������ת�Ʋ�����Ӱ����������ļ�������
		v2f vert(appdata_img v) {
			v2f o;
			o.pos = UnityObjectToClipPos(v.vertex);

			half2 uv = v.texcoord;
			o.uv[0] = uv;

			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				uv.y = 1 - uv.y;
			#endif

			o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1, 1) * _SampleDistance; //����
			o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1, -1) * _SampleDistance; //����
			o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 1) * _SampleDistance; //����
			o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1, -1) * _SampleDistance; //����

			return o;
		}

		half CheckSame(half4 center, half4 sample) {
			//ֵ��ע����ǣ������������ǲ�û�н���õ������ķ���ֵ����������ֱ��ʹ����xy������
			//������Ϊ����ֻ��Ҫ�Ƚ���������ֵ֮��Ĳ���ȣ���������Ҫ֪�����������ķ���ֵ������������
			half2 centerNormal = center.xy; //��û����DecodeViewNormalStereo���뷨����Ϣ
			float centerDepth = DecodeFloatRG(center.zw); //DecodeFloatRG ������ȷ��������е������Ϣ
			half2 sampleNormal = sample.xy;
			float sampleDepth = DecodeFloatRG(sample.zw);

			half2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x; //ʹ��sensitivityNormals��Ĭ��=1������
			int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1; //���ߵ�x������y�����Ĳ���ֵ���<��ֵ1����Ϊ2�������㹻���� //��ֵ1ȡ0.1
			float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y; //ʹ��sensitivityDepth��Ĭ��=1������
			int isSameDepth = diffDepth < 0.1 * centerDepth; //��ȵĲ���ֵ<��ֵ2*����(center)���ص����ֵ����Ϊ2�������㹻���� //��ֵ2ȡ0.1

			// return:
			// 1 - if normals and depth are similar enough
			// 0 - otherwise
			return isSameNormal * isSameDepth ? 1.0 : 0.0;
		}

		fixed4 fragRobertsCrossDepthAndNormal(v2f i) : SV_Target{
			half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]); //����
			half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]); //����
			half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]); //����
			half4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4]); //����

			half edge = 1.0;

			//CheckSame��������ֵ�� 0-����֮�����һ���߽� 1-�����ڱ߽�
			//���������edge���ǣ�ֻҪ �����ϡ����¡� or �����¡����ϡ�2�����������1��������Ǵ��ڱ߽磬��ô�ʹ��ڱ߽磨edge=0�������򲻴��ڣ�edge=1��
			edge *= CheckSame(sample1, sample2);
			edge *= CheckSame(sample3, sample4);

			fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[0]), edge);
			fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);

			return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
		}
		
		ENDCG
		
		Pass {      
			ZTest Always Cull Off ZWrite Off //��Ļ����shader�ı��� //��Ȳ��Եĺ���������ͨ�� �ر��޳� �ر����д��
			    	
			CGPROGRAM  
			
			#pragma vertex vert  
			#pragma fragment fragRobertsCrossDepthAndNormal
			  
			ENDCG  
		}
	} 
	FallBack Off
}

//����ʵ�ֵ����Ч���ǻ���������Ļ�ռ���еģ�Ҳ����˵�������ڵ��������嶼�ᱻ������Ч���� 
//����ʱ������ϣ��ֻ���ض������������ߣ����統���ѡ�г����е�ĳ�������������Ҫ�ڸ�������Χ���һ�����Ч���� 
//��ʱ�����ǿ���ʹ��Unity�ṩ�� Graphics.DrawMesh ��Graphics.DrawMeshNow��������Ҫ��ߵ������ٴ���Ⱦһ�飨�����в�͸��������Ⱦ���֮�󣩣�����������������������������
//Ȼ����ʹ�ñ����ᵽ�ı�Ե����㷨������Ȼ���������ÿ�����ص��ݶ�ֵ���ж������Ƿ�С��ĳ����ֵ��
//����ǣ�����Shader��ʹ��clip()�������������޳������Ӷ���ʾ��ԭ����������ɫ��
