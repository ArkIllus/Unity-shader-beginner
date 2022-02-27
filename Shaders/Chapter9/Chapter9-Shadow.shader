//Blinn-Phong ����ģ�� (��ƬԪ) + ǰ����Ⱦ������ͬ���͵Ĺ�Դ������ֻ��ƽ�й⣩+ ������Ӱ��ʹ�ú꣩
//Ϊǰ����Ⱦ������ Base Pass �� AdditionalPass ����������Դ

Shader "Unity Shaders Book/Chapter 9/Shadow"
{
    Properties
    {
        _Diffuse("Diffuse", Color) = (1, 1, 1, 1)
        _Specular("Specular", Color) = (1, 1, 1, 1)
        _Gloss("Gloss", Range(8.0, 256)) = 20
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        //RenderType��ǩ������Unity�����Shader���뵽��ǰ������飨Opaque�飩�У�
        //��ָ����shader��һ����͸����shader��RenderType��ǩͨ����������ɫ���滻���ܡ�

        Pass
        {   // Pass for ambient light & first pixel light (directional light)
            Tags {"LightMode"="ForwardBase"}

            CGPROGRAM

            #pragma multi_compile_fwdbase
            //��ָ����Ա�֤������Shader��ʹ�ù���˥���ȹ��ձ������Ա���ȷ��ֵ�����ǲ���ȱ�ٵġ�

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc" //������Ӱʱ���õĺ궼��������ļ��������ġ�

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                SHADOW_COORDS(2) //����� ����һ�����ڶ���Ӱ������������ꡣ
                                 //ʵ���Ͼ��������� һ����Ϊ_ShadowCoord ����Ӱ�����������
            };

            v2f vert (a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;

                TRANSFER_SHADOW(o); //����������ڶ�����ɫ���м���v2f����������Ӱ�������ꡣ
                                    //��Ѷ��������ģ�Ϳռ�任����Դ�ռ��洢�� _ShadowCoord��
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);
                
                //_WorldSpaceLightPos0.xyz��
                //�����ƽ�й⣬��ʾƽ�й�ķ���
                //����������⣬��ʾ��Դ��λ��
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                // һ�������������� (????????????????????????????)
                //fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                // һ�������������� (????????????????????????????)
                //fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                //ƽ�й��˥��ϵ��Ϊ1��û��˥����
                fixed atten = 1.0;

                fixed shadow = SHADOW_ATTENUATION(i); //ƬԪ��ɫ���м�����Ӱֵ
                                                      //����ʹ�� _ShadowCoord����ص�������в������õ���Ӱ��Ϣ

                // ������Ӱֵshadow �� �����䡢�߹ⷴ����ɫ��ˡ�
                return fixed4(ambient + (diffuse + specular) * atten * shadow, 1.0);
            }

            ENDCG
        }

        //����û�ж�Additional Pass �����κθ��ģ�������Ϊ�˽�����������������Ӱ��
        Pass
        {   // Pass for other pixel lights
            Tags { "LightMode" = "ForwardAdd"}

            //��ע�⡿��Ҫ���������û��ģʽ
            Blend One One
            //Blend SrcAlpha One
            //��Ϊ����ϣ��Additional Pass����õ��Ĺ��ս��������֡��������֮ǰ�Ĺ��ս�����е��ӡ�
            //���û��Blend���Additional Pass��ֱ�Ӹ��ǵ�֮ǰ�Ĺ��ս����
            //��������ѡ��Ļ��ϵ����Blend One One
            //�ⲻ�Ǳ���� ���ǿ������ó� Unity ֧�ֵ��κλ��ϵ���������Ļ��� Blend SrcAlpha One

            CGPROGRAM

            #pragma multi_compile_fwdadd
            //��ָ����Ա�֤������Shader��ʹ�ù���˥���ȹ��ձ������Ա���ȷ��ֵ�����ǲ���ȱ�ٵġ�

            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"
            #include "AutoLight.cginc" //��Ҫinclude

            fixed4 _Diffuse;
            fixed4 _Specular;
            float _Gloss;

            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 worldNormal : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed3 worldNormal = normalize(i.worldNormal);

                //_WorldSpaceLightPos0.xyz��
                //�����ƽ�й⣬��ʾƽ�й�ķ���
                //����������⣬��ʾ��Դ��λ��
                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);
                #else
                    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz - i.worldPos.xyz);
                #endif
                // һ�������������� (????????????????????????????)
                //fixed3 worldLightDir = normalize(UnityWorldSpaceLightDir(i.worldPos));
                
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * max(0, dot(worldNormal, worldLightDir));
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);
                // һ�������������� (????????????????????????????)
                //fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                fixed3 halfDir = normalize(worldLightDir + viewDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0, dot(worldNormal, halfDir)), _Gloss);

                #ifdef USING_DIRECTIONAL_LIGHT
                    fixed atten = 1.0;
                #else
                    //Unity ���ڲ�ʹ��һ����Ϊ_LightTextureO �������������Դ˥��
                    //Ϊ�˶�_LightTextureO ��������õ������㵽�ù�Դ��˥��ֵ������������Ҫ�õ��õ��ڹ�Դ
                    //�ռ��е�λ�ã�����ͨ��_LightMatrix.0 �任����õ���
                    //Ȼ�����ǿ���ʹ����������ģ��ƽ����˥��������в������õ�˥��ֵ��
                    #if defined (POINT)
                        float3 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1)).xyz;
                        fixed atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #elif defined (SPOT)
                        float4 lightCoord = mul(unity_WorldToLight, float4(i.worldPos, 1));
                        fixed atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                    #else
                        fixed atten = 1.0;
                    #endif
                #endif
                //��Ҫע����ǣ�����ֻ��Ϊ�˽��⴦���������͹�Դ��ʵ��ԭ���������벢����������������Ŀ�С�

                //��������������
                return fixed4((diffuse + specular) * atten, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Specular"
}

//��Ҫע����ǣ� ������Ĵ���������ֻ������Base Pass�еĴ��룬 ʹ����Եõ���ӰЧ���� ��û
//�ж�Additional Pass �����κθ��ġ� �����ϣ�Additional Pass����Ӱ�����Base Pass��һ���ġ�
//���ǽ���9.4.4�ڿ�����δ�����Щ��Ӱ�� 
//����ʵ�ֵĴ������Ϊ�˽�����������������Ӱ�� ��������ֱ��Ӧ�õ���Ŀ��