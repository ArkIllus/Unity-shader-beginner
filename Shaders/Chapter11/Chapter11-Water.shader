//顶点动画 模拟流动的河流
//参考：Chapter8-AlphaBlend

Shader "Unity Shaders Book/Chapter 11/Water" 
{
    Properties
    {
        //_MainTex 是河流纹理， _Color 用于控制整体颜色， _Magnitude 用于控制水流波动的幅度，
        //_Frequency 用于控制波动频率，_InvWaveLength 用于控制波长的倒数(_InvWaveLength 越大，波长越小），
        //_Speed 用于控制河流纹理的移动速度。
        _MainTex("Main Tex", 2D) = "white" {}
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _Magnitude("Distortion Magnitude", Float) = 1
        _Frequency("Distortion Frequency", Float) = 1
        _InvWaveLength("Distortion Inverse Wave Length", Float) = 10
        _Speed("Speed", Float) = 0.5
    }
    SubShader
    {
        //这里出现了一个新的标签：DisableBatching
        // 
        //一些SubShader在使Unity 的批处理功能时会出现问题，这时可以通过该标签来直接指明是否对该 SubShader 使用批处理。
        //而这些需要特殊处理的 Shader 通常就是指包含了模型空间的顶点动画的 Shader 。
        //这是因为，批处理会合并所有相关的模型，而这些模型各自的模型空间就会丢失。
        //而在本例中，我们需要在物体的模型空间下对顶点位置进行偏移。因此，在这里需要取消对该 Shader 的批处理操作。
        //。。。不是很懂。。。
        Tags { "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent" "DisableBatching"="True"}

        Pass
        {
            Tags { "LightMode" = "ForwardBase" } //前向渲染

            ZWrite Off //关闭深度写入
            Blend SrcAlpha OneMinusSrcAlpha //【开启】并【设置】该Pass的混合模式
            //将源颜色（该片元着色器产生的颜色）的混合因子设为 SrcAlpha, 
            //把目标颜色（已经存在于颜色缓冲中的颜色）的混合因子设为OneMinusSrcAlpha
            //混合后的新颜色：
            //DstColor_new = SrcAlpha * SrcColor + (1-SrcAlpha) * DstColor_old
            Cull Off //关闭了剔除功能。这是为了让水流的每个面都能显示

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _Magnitude;
            float _Frequency;
            float _InvWaveLength;
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

                //首先计算顶点位移量 我们只希望对顶点的x方向进行位移
                float4 offset;
                offset.yzw = float3(0.0, 0.0, 0.0);
                //利用_Frequency 屈性和内置的 _Time.y 变墓来控制正弦函数的频率
                //为了让不同位置具有不同的位移，我们对上述结果加上了模型空间下的位置分批，并乘以_Inv WaveLength控制波长。
                //最后，我们对结果值乘以_Magnitude 来控制波动幅度，得到最终的位移。
                offset.x = sin(_Frequency * _Time.y + v.vertex.x * _InvWaveLength + v.vertex.y * _InvWaveLength + v.vertex.z * _InvWaveLength) * _Magnitude;
                //把位移添加到顶点位置上 再进行正常的顶点变换即可。
                o.pos = UnityObjectToClipPos(v.vertex + offset);

                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                //进行了纹理动画，即使用_Time.y和_Speed 来控制在水平方向上的纹理动画。
                o.uv += float2(0.0, _Time.y * _Speed);

                return o;
            }

            //只需要对纹理采样再添加颜色控制即可
            fixed4 frag(v2f i) : SV_Target
            {
                fixed4 c = tex2D(_MainTex, i.uv);
                c.rgb *= _Color.rgb;

                return c;
            }

            ENDCG
        }
    }
    FallBack "Transparent/VertexLit"
}

// CV