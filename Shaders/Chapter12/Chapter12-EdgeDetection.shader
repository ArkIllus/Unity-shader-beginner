Shader "Unity Shaders Book/Chapter 12/Edge Detection"
{
    Properties
    {
        _MainTex("Base (RGB)", 2D) = "white" {} //Graphics.Blit(src, dest, material)把src传递给material使用的shader中名为_MainTex的属性
        _EdgeOnly("Edge Only", Float) = 1.0
        _EdgeColor("Edge Color", Color) = (0, 0, 0, 1)
        _BackgroundColor("Background Color", Color) = (1, 1, 1, 1)
        //都是由脚本传递得到的(见EdgeDetection.cs)。这里的声明仅仅是为了显示在材质面板中
    }
    SubShader
    {
        //Tags { "RenderType"="Opaque" }

        Pass
        {
            ZTest Always Cull Off ZWrite Off //屏幕后处理shader的标配
            //深度测试的函数：总是通过 关闭剔除 关闭深度写入

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment fragSobel

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            uniform half4 _MainTex_TexelSize; //Unity提供的访问xxx纹理对应的每个纹素的大小。用于在卷积计算各个相邻区域的纹理坐标。
                                              //uniform half4 或 half4都可 ？？？
            fixed _EdgeOnly;
            fixed4 _EdgeColor;
            fixed4 _BackgroundColor;

            //不需要a2v，因为使用了Unity内置的appdata_img结构体作为顶点着色器的输入
            //struct a2v
            //{
            //    float4 vertex : POSITION;
            //    float4 texcoord : TEXCOORD0;
            //};

            struct v2f
            {
                float4 pos : SV_POSITION;
                //float2 uv : TEXCOORD0;
                half2 uv[9] : TEXCOORD0; //维数=9的纹理数组，对应Sobel算子采样时需要的9个邻域纹理坐标
            };
            //通过计算采样纹理坐标的代码片元着色器中转移到顶点着色器中，可以减少运算，提高性能。
            //由于从顶点着色器到片元着色器的插值是线性的，因此这样的转移并不会影响纹理坐标的计算结果。

            //使用了Unity内置的appdata_img结构体作为顶点着色器的输入
            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);

                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                //o.uv = v.texcoord;
                half2 uv = v.texcoord;
				o.uv[0] = uv + _MainTex_TexelSize.xy * half2(-1, -1);
				o.uv[1] = uv + _MainTex_TexelSize.xy * half2(0, -1);
				o.uv[2] = uv + _MainTex_TexelSize.xy * half2(1, -1);
				o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1, 0);
				o.uv[4] = uv + _MainTex_TexelSize.xy * half2(0, 0);
				o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1, 0);
				o.uv[6] = uv + _MainTex_TexelSize.xy * half2(-1, 1);
				o.uv[7] = uv + _MainTex_TexelSize.xy * half2(0, 1);
				o.uv[8] = uv + _MainTex_TexelSize.xy * half2(1, 1);
                // 9个邻域纹理坐标

                return o;
            }

            //计算颜色对应的亮度值（luminance）
            fixed luminance(fixed4 color) {
                return  0.2125 * color.r + 0.7154 * color.g + 0.0721 * color.b;
            }

            half Sobel(v2f i) {
                //水平方向的卷积核Gx
                const half Gx[9] = {
                    -1, 0, 1,
                    -2, 0, 2,
                    -1, 0, 1
                };
                //竖直方向的卷积核Gy
                const half Gy[9] = {
                    -1, -2, -1,
                    0, 0, 0,
                    1, 2, 1
                };
                half texColor;
                half edgeX = 0;
                half edgeY = 0;
                for (int it = 0; it < 9; it++) {
                    texColor = luminance(tex2D(_MainTex, i.uv[it])); //亮度值
                    edgeX += texColor * Gx[it]; //梯度值Gx
                    edgeY += texColor * Gy[it]; //梯度值Gy
                }

                // 出于性能考虑，使用绝对值代替开根号操作： G = |Gx| + |Gy|
                half edge = 1 - abs(edgeX) - abs(edgeY); //这样得到的edge=1-G越小，该位置越可能是一个边缘点

                return edge;
            }

            fixed4 fragSobel(v2f i) : SV_Target
            {
                // 调用Sobel函数计算当前像素（片元）的梯度值edge
                half edge = Sobel(i);
                
                //计算边缘叠加在原渲染图像（背景颜色为原图像）上的颜色值
                fixed4 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[4]), edge);

                //计算只显示边缘，不显示原图像（背景颜色为_BackgroundColor）的颜色值
                fixed4 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge);

                //最后用_EdgeOnly在以上两种颜色中间插值得到最终的像素（片元）颜色
                return lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly);
            }
            ENDCG
        }
    }
    Fallback Off
}
// 需要注意的是，本节实现的边缘检测仅仅利用了屏幕
//颜色信息，而在实际应用中，物体的纹理、阴影等信息均
//会影响边缘检测 的结果，使得结果包含许多非预期的描
//边。为了得到更加准确的边缘信息，我们往往会在屏幕的
//深度纹理和法线纹理上进行边缘检测。我们将会在 13.4
//节中实现这种方法。
