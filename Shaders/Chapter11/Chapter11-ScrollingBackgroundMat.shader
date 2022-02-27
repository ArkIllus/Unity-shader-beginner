//背景循环滚动动画
//参考：无

Shader "Unity Shaders Book/Chapter 11/Scrolling Background" 
{
    Properties
    {
        //_MainTex _DetailTex 分别是第一层（较远）和第二层（较近）的背景纹理，而
        //_ScrollX和_Scroll2X 对应了各自的水平滚动速度。_Multiplier 参数则用于控制纹理的整体亮度。
        _MainTex("Base Layer (RGB)", 2D) = "white" {}
        _DetailTex("2nd Layer (RGB)", 2D) = "white" {}
        _ScrollX("Base layer Scroll Speed", Float) = 1.0
        _Scroll2X("2nd layer Scroll Speed", Float) = 1.0
        _Multiplier("Layer Multiplier", Float) = 1
    }
    SubShader
    {
        Tags { "Queue"="Geometry" "RenderType"="Opaque" }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" } //前向渲染

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            sampler2D _DetailTex;
            float4 _MainTex_ST;
            float4 _DetailTex_ST;
            float _ScrollX;
            float _Scroll2X;
            float _Multiplier;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float4 uv : TEXCOORD0; //把两张纹理的纹理坐标存储在同一个变量 o.uv 中，以减少占用的插值寄存器空间。
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                //o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                //利用内置的_Time.y 变量在水平方向上对纹理坐标进行偏移
                //frac函数返回标量或每个矢量中各分量的小数部分
                o.uv.xy = TRANSFORM_TEX(v.texcoord, _MainTex) + frac(float2(_ScrollX, 0.0) * _Time.y);
                o.uv.zw = TRANSFORM_TEX(v.texcoord, _DetailTex) + frac(float2(_Scroll2X, 0.0) * _Time.y);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //对两张背景纹理进行采样
                fixed4 firstLayer = tex2D(_MainTex, i.uv.xy);
                fixed4 secondLayer = tex2D(_DetailTex, i.uv.zw);

                //使用第二层纹理的透明通道来混合两张纹理，这使用了 CG lerp 函数
                fixed4 c = lerp(firstLayer, secondLayer, secondLayer.a);
                //最后，我们使用_Multiplier 参数和输出颜色进行相乘，以调整背景亮度。
                c.rgb *= _Multiplier;

                return c;

                return c;
            }

            ENDCG
        }
    }
    FallBack "VertexLit"
}