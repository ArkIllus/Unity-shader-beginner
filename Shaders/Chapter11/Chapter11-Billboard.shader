//顶点动画 广告牌
//参考：Chapter11-Water

Shader "Unity Shaders Book/Chapter 11/Billboard" {
    Properties{
        _MainTex("Main Tex", 2D) = "white" {}
        _Color("Color Tint", Color) = (1, 1, 1, 1)
        _VerticalBillboarding("Vertical Restraints", Range(0,1)) = 1 // 用于调整是固定法线还是固定指向上的方向，即约束垂直方向的程度。
                                                                     // =1 固定法线方向为观察视角 // =0 固定指向上的方向为(0,1,0)
    }
    SubShader
    {
        //这里出现了一个新的标签：DisableBatching
        // 
        //一些SubShader在使Unity的批处理功能时会出现问题，这时可以通过该标签来直接指明是否对该 SubShader 使用批处理。
        //而这些需要特殊处理的 Shader 通常就是指包含了模型空间的顶点动画的Shader。
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
            Cull Off //关闭了剔除功能。这是为了让广告牌的每个面都能显示

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //#include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed _VerticalBillboarding;

            struct a2v {
                float4 vertex : POSITION;
                float4 texcoord : TEXCOORD0;
            };

            struct v2f {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            // 所有计算都是在【模型空间】下进行的
            v2f vert(a2v v)
            {
                v2f o;

                //选择模型空间的原点作为广告牌的锚点
                float3 center = float3(0, 0, 0);
                //模型空间下的视角位置
                float3 viewer = mul(unity_WorldToObject, float4(_WorldSpaceCameraPos, 1));

                //目标法线方向
                float3 normalDir = viewer - center;
                //根据_VerticalBillboarding 属性来控制垂直方向(y方向)上的约束度。
                // If _VerticalBillboarding equals 1, we use the desired view dir as the normal dir
                // Which means the normal dir is fixed
                // Or if _VerticalBillboarding equals 0, the y of normal is 0
                // Which means the up dir is fixed
                normalDir.y = normalDir.y * _VerticalBillboarding;
                normalDir = normalize(normalDir);
                //计算粗略的向上方向（只可能 = 向上(0, 1, 0) or 向前(0, 0, 1)）？？？
                // Get the approximate up dir
                // If normal dir is already towards up, then the up dir is towards front
                float3 upDir = abs(normalDir.y) > 0.999 ? float3(0, 0, 1) : float3(0, 1, 0);
                //粗略的向上方向 叉乘 目标法线方向 得到 向右方向 ？？？？？
                float3 rightDir = normalize(cross(upDir, normalDir));
                //此时向上方向是不准确的，根据准确的法线方向和向右方向得到最后的向上方向 ？？？？？
                upDir = normalize(cross(normalDir, rightDir));

                //得到了所需的3个正交基向量
                //根据原始位置相对于锚点的偏移量 以及 3个正交基向量，计算新的顶点位置
                // Use the three vectors to rotate the quad
                float3 centerOffs = v.vertex.xyz - center; //（v.vertex也是模型空间下的坐标）
                float3 localPos = center + rightDir * centerOffs.x + upDir * centerOffs.y + normalDir * centerOffs.z;

                o.pos = UnityObjectToClipPos(float4(localPos, 1));
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
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

//在上面的例子中，我们使用的是自带的四边形(Quad) 来作为广告牌，而不能使用自带的平面(Plane)。
//这是因为，我们的代码是建立在【一个竖直摆放的多边形】的基础上的，
//也就是说，这个多边形的顶点结构需要满足在模型空间下是竖直排列的。
//只有这样，我们才能使用v.vertex 来计算得到正确的相对于中心的位置偏移量。

//顶点动画的注意事项（简略版）：
// 1.批处理 DisableBatching
// 2.添加阴影 内置的ShadowCaster Pass并没有进行相关的顶点动画，因此Unity仍然会按照原来的顶点位置来计算阴影
// 
//在前面的实现中，如果涉及半透明物体我们都把 Fallback 设置成了 Transparent / VertexLit,
//Transparent / VertexLit 没有定义 ShadowCaster Pass, 因此也就不会产生阴影