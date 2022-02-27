Shader "Unity Shaders Book/Chapter 12/Brightness Saturation And Contrast"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {} //Graphics.Blit(src, dest, material)把src传递给material使用的shader中名为_MainTex的属性
        _Brightness("Brightness", Float) = 1
        _Saturation("Saturation", Float) = 1
        _Contrast("Contrast", Float) = 1
            //亮度、饱和度、对比度，都是由脚本传递得到的。这里的声明仅仅是为了显示在材质面板中
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
            #pragma fragment frag

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            half _Brightness;
            half _Saturation;
            half _Contrast;

            //不需要a2v，因为使用了Unity内置的appdata_img结构体作为顶点着色器的输入
            //struct a2v
            //{
            //    float4 vertex : POSITION;
            //    float4 texcoord : TEXCOORD0;
            //};

            struct v2f
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            //使用了Unity内置的appdata_img结构体作为顶点着色器的输入
            v2f vert (appdata_img v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                //o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv = v.texcoord;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 对原屏幕图像（存在_MainTex中）采样
                fixed4 renderTex = tex2D(_MainTex, i.uv);
                
                //1. 亮度调整
                // 原颜色×亮度系数
                fixed3 finalColor = renderTex.rgb * _Brightness; // _Brightness=3时 (1,1,1)不就变成(3,3,3)了???????
                                                                 // 实验一下就能发现，会限制在[0,1]之内 
                                                                 // 比如(0.5,0.4,0.3)*3 = (1,1,0.9)，再比如亮度很大那么就变纯白，亮度<=0那么就变纯黑

                //2. 饱和度调整
                // 计算该像素对应的亮度值（luminance） 
                // 该公式是RGB转YUV的BT709明亮度转换公式，是基于人眼感知的图像灰度处理公式。这条公式通过计算每个像素RGB值对应的灰度值，来把RGB彩色图像转换为灰度图。
                fixed luminance = 0.2125 * renderTex.r + 0.7154 * renderTex.g + 0.0721 * renderTex.b;
                // 使用该亮度值创建一个饱和度为0的颜色值（灰色or白色or黑色）
                fixed3 luminanceColor = fixed3(luminance, luminance, luminance);
                // 使用_Saturation在（原颜色×亮度系数）和（使用亮度值创建的饱和度为0的颜色值）之间进行插值，从而得到希望的饱和度颜色
                finalColor = lerp(luminanceColor, finalColor, _Saturation);
                
                //3. 对比度调整
                // 先创建一个对比度为0的颜色值（各分量=0.5的灰色）
                fixed3 avgColor = fixed3(0.5, 0.5, 0.5);
                // 使用_Contrast在...和...之间进行插值，从而得到最终的颜色
                finalColor = lerp(avgColor, finalColor, _Contrast);

                return fixed4(finalColor, renderTex.a); //透明度与原屏幕图像保持一致
            }
            ENDCG
        }
    }
    Fallback Off
}
// 感觉这里的亮度、饱和度、对比度调整涉及到对应的理论。。。有空得找理论理解一下
// 
// 不知道为什么，代码和我能看到的设置完全和书上一致，但是效果就是有些不一样。。。？？？
