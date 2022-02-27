//序列帧动画
//参考：Chapter8-AlphaBlend

Shader "Unity Shaders Book/Chapter 11/Image Sequence Animation" 
{
    Properties
    {
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _MainTex("Main Tex", 2D) = "white"{} //包含了所有关键帧图像的纹理
        _HorizontalAmount("Horizontal Amount", Float) = 4 //在水平方向包含的关键帧图像的个数
        _VerticalAmount("Vertical Amount", Float) = 4 //在竖直方向包含的关键帧图像的个数
        _Speed("Speed", Range(1, 100)) = 30 //用于控制序列帧动画的播放速度。
    }
    SubShader
    {
        //由于序列帧图像通常包含了透明通道， 因此可以被当成是 一个半透明对象。
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" }

        Pass
        {
            Tags { "LightMode" = "ForwardBase" } //前向渲染

            ZWrite Off //关闭深度写入
            Blend SrcAlpha OneMinusSrcAlpha //【开启】并【设置】该Pass的混合模式
            //将源颜色（该片元着色器产生的颜色）的混合因子设为 SrcAlpha, 
            //把目标颜色（已经存在于颜色缓冲中的颜色）的混合因子设为OneMinusSrcAlpha
            //混合后的新颜色：
            //DstColor_new = SrcAlpha * SrcColor + (1-SrcAlpha) * DstColor_old

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST; //不用在Properties声明
            float _HorizontalAmount;
            float _VerticalAmount;
            float _Speed;

            struct a2v
            {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //计算关键帧所在的行列索引数
                float time = floor(_Time.y * _Speed); //_Time.y：t是自该场景加载开始所经过的时间，.y=t
                float row = floor(time / _HorizontalAmount);
                float column = time - row * _HorizontalAmount;

                //计算真正的纹理采样坐标uv ？
				//half2 uv = float2(i.uv.x /_HorizontalAmount, i.uv.y / _VerticalAmount);
				//uv.x += column / _HorizontalAmount;
				//uv.y -= row / _VerticalAmount;
                //这对应了上面代码中注释掉的代码部分。 我们可以把上述过程中的除法整合到一起，就得到了注释下方的代码 。
                half2 uv = i.uv + half2(column, -row);
                uv.x /= _HorizontalAmount;
                uv.y /= _VerticalAmount;

                //序列帧图像采样
                fixed4 c = tex2D(_MainTex, uv);
                c.rgb *= _Color;

                return c;
            }

            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}

//Chapter8-AlphaBlend:
//当模型本身有复杂的遮挡关系或是包含了复杂的非凸网格的时候，
//就会有各种各样因为【排序错误】而产生的错误的透明效果。
//这都是由于我们【关闭了深度写入】造成的，因为这样我们就无法对模型进行像素级别的深度排序。
