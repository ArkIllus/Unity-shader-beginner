Shader "Unity Shaders Book/Chapter 5/Simple Shader"
{
    Properties
    {
        //_MainTex ("Texture", 2D) = "white" {}
        _Color("Color Tint", Color) = (1.0, 1.0, 1.0, 1.0) // 白色
    }
        SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //// POSITION: 把模型的顶点坐标填充到输入参数v中
            //// SV_POSITION: 顶点着色器的输出是裁剪空间中的顶点坐标
            //float4 vert(float4 v : POSITION) : SV_POSITION {
            //    //return mul(UNITY_MATRIX_MVP, v);
            //    // 把顶点坐标从模型空间转换到裁剪空间中
            //    return UnityObjectToClipPos(v);
            //}
            //
            //// SV_TARGET: 告诉渲染器，把用户输出的颜色存储到一个渲染目标（render target）中，
            //// 这里将输出到默认的帧缓存中
            //fixed4 frag() : SV_TARGET {
            //    //return fixed4(1.0, 1.0, 1.0, 1.0); // 白色
            //    return fixed4(0.0, 0.0, 0.0, 1.0); // 黑色
            //}

            //在CG代码中， 我们需要定义一个与属性名称和类型都匹配的变量
            fixed4 _Color;

            // application to vertex shader
            struct a2v {
                // POSITION: 把模型空间的顶点坐标填充到输入参数v中
                float4 vertex : POSITION;
                // NORMAL: 把模型空间的法线方向填充到输入参数normal中
                float3 normal : NORMAL;
                // TEXCOORD0: 把模型的第一套纹理坐标填充到输入参数texcoord中
                float4 texcoord : TEXCOORD0;
            };
            
            // vertex shader to fragment shader
            struct v2f {
                // SV_POSITION: 告诉unity，pos包含了裁剪空间中的顶点坐标
                float4 pos : SV_POSITION;
                // COLOR0: 用于存储颜色信息
                fixed3 color : COLOR0;
            };

            //// SV_POSITION: 顶点着色器的输出是裁剪空间中的顶点坐标
            //float4 vert(a2v v) : SV_POSITION{
            //    return UnityObjectToClipPos(v.vertex);
            //}

            v2f vert(a2v v) { // 返回类型是v2f，所以不再有 SV_POSITON:
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                // v.normal为顶点的法线方向，分量范围在[-1.0, 1.0]
                // 下面的代码把分量范围映射到了[0.0, 1.0]
                // 存储到o.color中传递给片元着色器
                o.color = v.normal * 0.5 + fixed3(0.5, 0.5, 0.5);
                return o;
            }

            // SV_TARGET: 告诉渲染器，把用户输出的颜色存储到一个渲染目标（render target）中，
            // 这里将输出到默认的帧缓存中
            fixed4 frag(v2f i) : SV_TARGET{
                // 将插值后的i.color显示到屏幕上
                fixed3 c = i.color;
                // 使用_Color属性（的rgb）来控制输出颜色
                c *= _Color.rgb;
                return fixed4(c, 1.0);
            }
            //需要注意的是， 顶点着色器是逐顶点调用的， 而片元着色器是逐片元调用的。
            //片元着色器中的输入实际上是把顶点着色器的输出进行插值后得到的结果。

            ENDCG
        }
    }
}
