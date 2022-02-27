Shader "Unity Shaders Book/Chapter 12/Gaussian Blur" {
    Properties{
        _MainTex("Base (RGB)", 2D) = "white" {} //Graphics.Blit(buffer0, buffer1, material, 0)把buffer0传递给material使用的shader中名为_MainTex的属性
        _BlurSize("Blur Size", Float) = 1.0 //在OnRenderImage中被设置
        //这里没有iterations blurSpread downSample了
    }
    SubShader
    {
        //本节中，首次使用CGINCLUDE来组织代码，这些代码不需要包含在Pass语义块中。CGINCLUDE类似C++头文件的功能。
        //目的：避免代码重复
        //
        //形式： 
        //GCINCLUDE
        //...
        //ENDCG

        CGINCLUDE

        #include "UnityCG.cginc"

        sampler2D _MainTex;
        half4 _MainTex_TexelSize; //Unity提供的访问xxx纹理对应的每个纹素的大小。用于在卷积计算各个相邻区域的纹理坐标。
        float _BlurSize;

        struct v2f {
            float4 pos : SV_POSITION;
            half2 uv[5]: TEXCOORD0; //5×5的二维高斯核，可以拆分成2个大小为5的一维高斯核，∴只需要5个纹理坐标
        };

        //通过把计算采样纹理坐标的代码从片元着色器中转移到顶点着色器中，可以减少运算，提高性能。
        //由于从顶点着色器到片元着色器的插值是线性的，因此这样的转移并不会影响纹理坐标的计算结果。

        // 竖直方向
        v2f vertBlurVertical(appdata_img v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            half2 uv = v.texcoord;

            // 5个纹理坐标 与后面fragBlur的 weight[3] 对应
            o.uv[0] = uv;
            o.uv[1] = uv + float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[2] = uv - float2(0.0, _MainTex_TexelSize.y * 1.0) * _BlurSize;
            o.uv[3] = uv + float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;
            o.uv[4] = uv - float2(0.0, _MainTex_TexelSize.y * 2.0) * _BlurSize;

            return o;
        }

        // 水平方向
        v2f vertBlurHorizontal(appdata_img v) {
            v2f o;
            o.pos = UnityObjectToClipPos(v.vertex);

            half2 uv = v.texcoord;

            // 5个纹理坐标 与后面fragBlur的 weight[3] 对应
            o.uv[0] = uv;
            o.uv[1] = uv + float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[2] = uv - float2(_MainTex_TexelSize.x * 1.0, 0.0) * _BlurSize;
            o.uv[3] = uv + float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;
            o.uv[4] = uv - float2(_MainTex_TexelSize.x * 2.0, 0.0) * _BlurSize;

            return o;
        }

        //2个Pass共用的片元着色器
        fixed4 fragBlur(v2f i) : SV_Target {
            //5×5的二维高斯核，可以拆分成2个大小为5的一维高斯核，由于对称性，只需要记录3个高斯权重
            // 原本的5个高斯权重： 0.0545, 0.2442, 0.4026, 0.2442, 0.0545
            float weight[3] = {0.4026, 0.2442, 0.0545};

            fixed3 sum = tex2D(_MainTex, i.uv[0]).rgb * weight[0];

            for (int it = 1; it < 3; it++) {
                //根据对称性，每次迭代包含2次纹理采样
                sum += tex2D(_MainTex, i.uv[it * 2 - 1]).rgb * weight[it];
                sum += tex2D(_MainTex, i.uv[it * 2]).rgb * weight[it];
            }

            //最后返回滤波结果sum
            return fixed4(sum, 1.0);
        }

        ENDCG

        ZTest Always Cull Off ZWrite Off //屏幕后处理shader的标配
                                         //深度测试的函数：总是通过 关闭剔除 关闭深度写入

        //我们为两个 Pass 使用 NAME语义定义了它们的名字。
        //为Pass定义名字，可以在其他Shader中直接通过它们的名字来使用该Pass。
        Pass {
            NAME "GAUSSIAN_BLUR_VERTICAL"

                CGPROGRAM

                #pragma vertex vertBlurVertical  
                #pragma fragment fragBlur

                ENDCG
        }

        Pass{
            NAME "GAUSSIAN_BLUR_HORIZONTAL"

            CGPROGRAM

            #pragma vertex vertBlurHorizontal  
            #pragma fragment fragBlur

            ENDCG
        }
    }
    Fallback "Diffuse"
}
