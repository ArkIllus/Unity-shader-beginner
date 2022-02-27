Shader "Unity Shaders Book/Chapter 14/Toon Shading"
{
    Properties
    {
        _Color ("Color Tint", Color) = (1, 1, 1, 1) // white
        _MainTex ("Main Texture", 2D) = "white" {}
        _Ramp ("Ramp Texture", 2D) = "white" {}
        _Outline ("Outline", Range(0, 1)) = 0.1 //���������߿��
        _OutlineColor ("Outline Color", Color) = (0, 0, 0, 1) //��������ɫ black
        _Specular ("Specular Color", Color) = (1, 1, 1, 1) // white
        _SpecularScale ("Specular Scale", Range(0, 0.1)) = 0.01 //���Ƹ߹��С�������threshold=1-_SpecularScale�����Ըò���ԽС���߹�ԽС��
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry"}
        //LOD 100

        //��1��Pass����Ⱦ�������Ƭ������Ⱦ�����ߵ�Pass��
        Pass
        {
            Name "OUTLINE" //��Ⱦ�����ߵ�Pass��NPR�г��õ�Pass

            Cull Front //�޳��������������Ƭ

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            float _Outline;
            fixed4 _OutlineColor;
            
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
            };

            v2f vert (a2v v)
            {
                v2f o;

                //�ӽǣ�������۲졢View���ռ��µĶ���ͷ��ߣ�MV�任��
                float4 pos = mul(UNITY_MATRIX_MV, v.vertex); //Unity�������Ǹ���UnityObjectToViewPos
                float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal); //UNITY_MATRIX_IT_MV��UNITY_MATRIX_MV����ת�þ���
                                                                             //ͨ�����ڰѷ��ߴ�ģ�Ϳռ�ת�����ӽǣ�������ռ�

                //Ϊ�˾����ܱ��ⱳ�����ź�Ķ��㵲ס�������Ƭ��
                //�����÷��ߵ�z����=-0.5�����������������ٶ����һ����
                //�ٽ������ط��߷�������/���죬�õ�����/�����Ķ������ꡣ
                normal.z = -0.5;
                pos = pos + float4(normalize(normal), 0) * _Outline; //_Outline���ƶ����ط��߷�������/����ĳ̶�

                //����ٰѶ�����ӽǣ�������۲졢View���ռ�任���ü��ռ䣨ͶӰP�任��
                o.pos = mul(UNITY_MATRIX_P, pos);

                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                //ֻ��Ҫ����������ɫ��Ⱦ�������漴��
                //���û�е�2��Pass����ῴ��������һƬ_OutlineColor�ģ�_OutlineColor��ɫ���������Ѿ��������
                return float4(_OutlineColor.rgb, 1);
            }

            ENDCG
        }

        //��2��Pass����Ⱦ�������Ƭ��������Ⱦ��
        Pass 
        {
            Tags { "LightMode"="ForwardBase"}

            Cull Back //�޳�����

            CGPROGRAM

            #pragma vertex vert
            #pragma fragment frag

            #pragma multi_compile_fwdbase

            #include "UnityCG.cginc"
            #include "Lighting.cginc"
            #include "AutoLight.cginc"
            #include "UnityShaderVariables.cginc"

            //����LightMode��#pragmaָ�� ����Ϊ����Shader�еĹ��ձ������Ա���ȷ��ֵ

            fixed4 _Color;
            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _Ramp;
            fixed4 _Specular;
            fixed _SpecularScale;

            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 texcoord : TEXCOORD0;
                float4 tangent : TANGENT;
            };

            struct v2f {
                float4 pos : POSITION;
                float2 uv: TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 worldPos : TEXCOORD2;
                SHADOW_COORDS(3) //����꽫����һ����Ϊ_ShadowCoord����Ӱ�������꣬������Ӱ�������
            };

            v2f vert(a2v v) {
                v2f o;

                //o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                o.pos = UnityObjectToClipPos(v.vertex);
                //o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;
                o.uv = TRANSFORM_TEX(v.texcoord, _MainTex);
                //������ɫ���У���������ռ��µķ��߷��򡢶���λ��
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                TRANSFER_SHADOW(o); //����������ڶ�����ɫ���м�����Ӱ��������_ShadowCoord��
                                    //��Ѷ��������ģ�Ϳռ�任����Դ�ռ��洢�� _ShadowCoord��

                return o;
            }

            // ambient + diffuse + specular
            fixed4 frag(v2f i) : SV_Target{ //fixed4 float4 ???
                //���������Ҫ�ķ���ʸ�����ǵù�һ��
                fixed3 worldNormal = normalize(i.worldNormal);
                fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
                fixed3 worldHalfDir = normalize(worldLightDir + worldViewDir);

                fixed4 c = tex2D(_MainTex, i.uv);
                //���ʵķ�����albedo(������������������ɫ����_Color �ĳ˻�����Ϊalbedo)
                fixed3 albedo = c.rgb * _Color.rgb;

                // ambient
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo;

                //������˥������Ӱֵ��˺�Ľ���洢����һ�����С�
                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

                // diffuse
                // ��������(Half Lambert)����ģ��
                // ��dot(n,l)�Ľ����Χ��[-1,-1]ӳ�䵽[0,1]��Ҳ����˵����ģ�͵ı�����Ҳ���������仯
                fixed halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;
                fixed diff = halfLambert * atten; //�������halfLambert��atten�����Ϊ���յ�������ϵ��������֮ǰ��������һ������������
                fixed3 diffuse = _LightColor0.rgb * albedo * tex2D(_Ramp, float2(diff, diff)).rgb;

                // specular����ͨ���ĸ߹���ģ����һ���ֽ���ϸ�Ĵ�ɫ����
                fixed spec = dot(worldNormal, worldHalfDir);
                //smoothstep + fwidth�Ը߹�����ı߽���п���ݴ��� 
                fixed w = fwidth(spec) * 2.0; //fwidth���԰�w��Ϊ��������֮��Ľ��Ƶ���ֵ
                fixed3 specular = _Specular.rgb * lerp(0, 1, smoothstep(-w, w, spec + _SpecularScale - 1)) * step(0.0001, _SpecularScale);
                //smoothstep������w��һ����С��ֵ������threshold=1-_SpecularScale��
                //��������spec-threshold<-wʱ������0������wʱ������1��������0~1֮����в�ֵ���Ӷ�ʵ�ֿ���ݡ�
                //step(0.0001, _SpecularScale)��Ϊ����_SpecularScale=0ʱ����ȫ�����߹ⷴ��Ĺ��գ�
                //step�ĵڶ�������>=��һ�������򷵻�1�����򷵻�0��

                return fixed4(ambient + diffuse + specular, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse" //��Բ�����ȷ����ӰͶ��Ч������Ҫ
}
