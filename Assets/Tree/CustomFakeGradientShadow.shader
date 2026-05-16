Shader "Custom/GrassWindLit"
{
    Properties
    {
        _ColorA ("Color A", Color) = (0,1,0,1)
        _ColorB ("Color B", Color) = (0,0.5,0,1)
        _ShadowColor ("Shadow Color", Color) = (0.2,0.3,0.2,1)

        _MainTex ("Texture", 2D) = "white" {}

        _Strength ("Wind Strength", Float) = 0.3
        _Speed ("Wind Speed", Float) = 1
        _Scale ("Noise Scale", Float) = 1

        _MinBrightness ("Min Brightness", Float) = 0.3
        _Smoothness ("Smoothness", Float) = 0.2

        _AlphaEdge1 ("Alpha Edge 1", Float) = 0.4
        _AlphaEdge2 ("Alpha Edge 2", Float) = 0.6
    }

    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "RenderPipeline"="UniversalPipeline" }

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _ColorA;
                float4 _ColorB;
                float4 _ShadowColor;

                float _Strength;
                float _Speed;
                float _Scale;

                float _MinBrightness;
                float _Smoothness;

                float _AlphaEdge1;
                float _AlphaEdge2;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS   : TEXCOORD0;
                float2 uv         : TEXCOORD1;
                float3 positionWS : TEXCOORD2;
            };

            // Simple hash noise
            float hash(float2 p)
            {
                p = frac(p * 0.3183099 + float2(0.1, 0.1));
                p *= 17.0;
                return frac(p.x * p.y * (p.x + p.y));
            }

            float noise(float2 p)
            {
                float2 i = floor(p);
                float2 f = frac(p);

                float a = hash(i);
                float b = hash(i + float2(1,0));
                float c = hash(i + float2(0,1));
                float d = hash(i + float2(1,1));

                float2 u = f*f*(3.0-2.0*f);
                return lerp(a,b,u.x) +
                       (c-a)*u.y*(1.0-u.x) +
                       (d-b)*u.x*u.y;
            }

            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                float3 positionWS = TransformObjectToWorld(IN.positionOS.xyz);

                // ===== Wind Noise =====
                float t = _Time.y * _Speed;
                float n = noise(positionWS.xz * _Scale + t);

                float wind = (n - 0.5) * _Strength;

                positionWS.x += wind;

                OUT.positionWS = positionWS;
                OUT.positionCS = TransformWorldToHClip(positionWS);
                OUT.normalWS = TransformObjectToWorldNormal(IN.normalOS);
                OUT.uv = IN.uv;

                return OUT;
            }

            half4 frag (Varyings IN) : SV_Target
            {
                float3 normalWS = normalize(IN.normalWS);

                // Main Light
                Light mainLight = GetMainLight();
                float3 lightDir = normalize(mainLight.direction);

                float NdotL = dot(normalWS, lightDir);
                NdotL = saturate(NdotL);

                // Custom min brightness
                float lighting = lerp(_MinBrightness, 1.0, NdotL);

                // Color blend based on UV Y
                float colorMask = IN.uv.y;
                float4 baseColor = lerp(_ColorA, _ColorB, colorMask);

                // Shadow tint
                float4 litColor = lerp(_ShadowColor, baseColor, lighting);

                // Texture alpha
                float4 tex = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);

                float alpha = smoothstep(_AlphaEdge1, _AlphaEdge2, tex.a);

                clip(alpha - 0.5);

                return half4(litColor.rgb, 1);
            }

            ENDHLSL
        }
    }
}