Shader "Unity Shaders Book/Chapter 13/Motion Blur With Depth Texture" {
	Properties{
		_MainTex("Base (RGB)", 2D) = "white" {}
		_BlurSize("Blur Size", Float) = 1.0  //��OnRenderImage�б�����
		//����ע�⵽����Ȼ�ڽű��������˲��ʵ�_PreviousViewProjectionMatrix ��_CurrentViewProjectioInverseMatrix���ԣ�
		//����û���� Properties �����������ǡ�������Ϊ Unity û���ṩ�������͵����ԣ���������Ȼ
		//������ CG ������ж�����Щ���󣬲��ӽű����������ǡ�
	}
	SubShader {
		//ʹ��CGINCLUDE����֯���� Ŀ�ģ���������ظ�
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		half4 _MainTex_TexelSize;
		sampler2D _CameraDepthTexture; //Unity���ݸ����ǵ��������
		float4x4 _CurrentViewProjectionInverseMatrix; //�ű��������ľ���
		float4x4 _PreviousViewProjectionMatrix; //�ű��������ľ���
		half _BlurSize;
		
		struct v2f {
			float4 pos : SV_POSITION;
			half2 uv : TEXCOORD0;
			half2 uv_depth : TEXCOORD1; //ר�����ڶ���������������������
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

			return o;
		}

		fixed4 frag(v2f i) : SV_Target {
			// ʹ�����õ� SAMPLE_DEPTH_TEXTURE �� ��������������������в��� ���õ������ֵd
			// Get the depth buffer value at this pixel.
			float d = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv_depth);
			// ���ֵd����NDC�µ�����ӳ������ġ������ֵd����ӳ���NDC��d * 2 - 1
			// ͬ����NDC��xy�������������ص���������ӳ��������õ�NDC����H��xyz������Χ��Ϊ[-1, 1]�����ֳ��ӿ�λ�ã���
			// H is the viewport position at this pixel in the range -1 to 1.
			float4 H = float4(i.uv.x * 2 - 1, i.uv.y * 2 - 1, d * 2 - 1, 1);
			// ʹ�õ�ǰ֡���ӽ�*ͶӰ�����������H���б任�����ѽ��ֵ��������w�������õ�����ռ��µ�����worldPos
			// Transform by the view-projection inverse.
			float4 D = mul(_CurrentViewProjectionInverseMatrix, H);
			// Divide by w to get the world position. 
			float4 worldPos = D / D.w;
			
			// ��ǰ֡��NDC�µ�����
			// Current viewport position 
			float4 currentPos = H;
			// ǰһ֡���ӽ�*ͶӰ���� * ����ռ��µ����� = ǰһ֡��NDC�µ�����previousPos��Ҳ�ǻ�Ҫ��������w������
			// Use the world position, and transform by the previous view-projection matrix.  
			float4 previousPos = mul(_PreviousViewProjectionMatrix, worldPos);
			// Convert to nonhomogeneous points [-1,1] by dividing by w.
			previousPos /= previousPos.w;
			
			// ����ǰһ֡�͵�ǰ֡����Ļ�ռ䣨NDC���꣩�µ�λ�ò�õ������أ�ƬԪ�����ٶ�
			// Use this frame's position and last frame's to compute the pixel velocity.
			float2 velocity = (currentPos.xy - previousPos.xy)/2.0f;
			
			// ʹ���ٶ�ֵ�Ը����أ�ƬԪ�����������ؽ��в�������Ӻ�ȡƽ���õ�ģ����Ч��
			float2 uv = i.uv;
			float4 c = tex2D(_MainTex, uv);
			uv += velocity * _BlurSize; //���ﻹ��_BlurSize�����˲�������
			for (int it = 1; it < 3; it++, uv += velocity * _BlurSize) {
				float4 currentColor = tex2D(_MainTex, uv);
				c += currentColor;
			}
			c /= 3;
			
			return fixed4(c.rgb, 1.0);
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

//����ʵ�ֵ��˶�ģ�������ڳ�����ֹ������������˶��������������Ϊ�����ڼ���ʱֻ��������������˶���
//��ˣ�������߰ѱ����еĴ���Ӧ�õ�һ����������˶����������ֹ�ĳ������ᷢ�ֲ�������κ��˶�ģ��Ч����
//���������Ҫ�Կ����ƶ�����������˶�ģ����Ч��������Ҫ���ɸ��Ӿ�ȷ���ٶ�ӳ��ͼ��
//���߿����� Unity �Դ��� Image Effect �����ҵ�������˶�ģ����ʵ�ַ�����
//
//����ѡ����ƬԪ��ɫ����ʹ����������ؽ�ÿ������������ռ��µ�λ�á����ǣ���������������Ӱ�����ܣ�
//�� 13.3 ���У����ǻ����һ�ָ����ٵ�����������ؽ���������ķ�����

//�ң����⣬�о�Ч����̫�Ծ���������֮�������ڲ��������ͣ�Ļ��ᷢ���ǻ���û��ģ����Ϊɶ�أ�����