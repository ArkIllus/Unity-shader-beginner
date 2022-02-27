// 镜子

Shader "Unity Shaders Book/Chapter 10/Mirror"
{
    Properties
    {
        _MainTex ("Main Tex", 2D) = "white" {} //它对应了由镜子摄像机渲染得到的渲染纹理
    }
    SubShader
    {
        //分类：不透明    渲染队列：默认（2000）（大多数物体。不透明物体。）
        Tags { "RenderType" = "Opaque" "Queue" = "Geometry"}

        Pass
        {
            //Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM

            //#pragma multi_compile_fwdbase

            #pragma vertex vert
            #pragma fragment frag

            //#include "Lighting.cginc"
            //#include "AutoLight.cginc"

            fixed4 _Color;
            fixed _FresnelScale;
            sampler2D _MainTex;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // 计算纹理坐标
            // 翻转x分量的纹理坐标。因为镜子里显示的图像都是左右相反的。
			v2f vert(a2v v) {
				v2f o;
				o.pos = UnityObjectToClipPos(v.vertex);

                o.uv = v.texcoord;
                // 镜子需要翻转x
                o.uv.x = 1 - o.uv.x;

				return o;
			}

            //对渲染纹理进行采样和输出
            fixed4 frag(v2f i) : SV_Target{
                return tex2D(_MainTex, i.uv);
			}

            ENDCG
	    }
	}
	FallBack Off //???
}