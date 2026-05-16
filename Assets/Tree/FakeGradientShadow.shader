Shader "Custom/FakeGradientShadow"
{
    Properties
    {
        [Header(Zone Colors)]
        _BrightColor ("Bright Color", Color) = (0.4,0.9,0.4,1)
        _MidColor    ("Mid Color",    Color) = (0.2,0.6,0.2,1)
        _DarkColor   ("Dark Color",   Color) = (0.05,0.15,0.05,1)

        [Header(Zone Distribution)]
        _DarkWidth    ("Dark Width",    Range(0,1)) = 0.33
        _MidWidth     ("Mid Width",     Range(0,1)) = 0.33
        _EdgeSoftness ("Edge Softness", Range(0,0.2)) = 0.01

        [Header(Gradient Mode)]
        [Enum(LightDirection,0, RadialStatic,1, WorldY,2, UVVertical,3, UVHorizontal,4)]
        _GradientMode   ("Gradient Mode", Float) = 0
        _GradientOffset ("Gradient Offset", Range(-1,1)) = 0
        _GradientRotate ("Gradient Rotate (UV only)", Range(0,360)) = 0

        [Header(Radial and Light Settings)]
        _RadialWorldX  ("Radial Center X", Float) = 0
        _RadialWorldY  ("Radial Center Y", Float) = 1
        _RadialWorldZ  ("Radial Center Z", Float) = 0
        _RadialRadius  ("Radial Radius",   Range(0.1,20)) = 3.0
        _RadialAspectY ("Radial Aspect Y", Range(0.1,3))  = 1.0

        [Header(Shadow)]
        _ShadowStrength  ("Shadow Strength",  Range(0,1)) = 0.8
        // Seberapa gelap area yang kena shadow
        _ShadowColor     ("Shadow Color Tint", Color) = (0.1,0.15,0.1,1)
        // Warna tint shadow — defaultnya sedikit kehijauan
        _ShadowBlend     ("Shadow Blend",     Range(0,1)) = 0.5
        // 0 = shadow hanya menggelapkan, 1 = shadow pakai ShadowColor penuh

        [Header(Per Leaf Color Variation)]
        [Enum(ObjectPos,0, WorldPos,1)]
        _LeafSeedSource    ("Seed Source",    Float)        = 1
        _LeafVariationSeed ("Variation Seed", Range(0,99))  = 1.0
        _HueShiftMin ("Hue Shift Min",        Range(-0.5,0.5)) = -0.05
        _HueShiftMax ("Hue Shift Max",        Range(-0.5,0.5)) =  0.05
        _SatShiftMin ("Saturation Shift Min", Range(-1,1))     = -0.1
        _SatShiftMax ("Saturation Shift Max", Range(-1,1))     =  0.1
        _BriShiftMin ("Brightness Shift Min", Range(-1,1))     = -0.1
        _BriShiftMax ("Brightness Shift Max", Range(-1,1))     =  0.1

        [Header(Wind)]
        _WindDirection   ("Wind Direction (XZ)", Vector)       = (1,0,0.3,0)
        _WindSpeed       ("Wind Speed",          Range(0,5))   = 1.0
        _WindStrength    ("Wind Strength",        Range(0,0.5)) = 0.05
        _WindTurbulence  ("Wind Turbulence",      Range(0,5))   = 2.0
        _WindHeightMask  ("Wind Height Mask",     Range(0,5))   = 1.0
        _WindPhaseOffset ("Wind Phase Offset",    Range(0,10))  = 3.0
        [Toggle] _FlipWindUV ("Flip Wind UV", Float) = 0

        [Header(Alpha)]
        _MainTex    ("Alpha Texture", 2D) = "white" {}
        _AlphaEdge1 ("Alpha Edge 1", Float) = 0.4
        _AlphaEdge2 ("Alpha Edge 2", Float) = 0.6
    }

    SubShader
    {
        Tags { "RenderType"="TransparentCutout" "RenderPipeline"="UniversalPipeline" }

        // ================================================================
        //  PASS 1: ForwardLit — rendering utama + terima shadow
        // ================================================================
        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode"="UniversalForward" }

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Keyword untuk shadow receiving
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
            #pragma multi_compile _ _SHADOWS_SOFT

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _BrightColor;
                float4 _MidColor;
                float4 _DarkColor;
                float  _DarkWidth;
                float  _MidWidth;
                float  _EdgeSoftness;
                float  _GradientMode;
                float  _GradientOffset;
                float  _GradientRotate;
                float  _RadialWorldX;
                float  _RadialWorldY;
                float  _RadialWorldZ;
                float  _RadialRadius;
                float  _RadialAspectY;
                float  _ShadowStrength;
                float4 _ShadowColor;
                float  _ShadowBlend;
                float  _LeafVariationSeed;
                float  _LeafSeedSource;
                float  _HueShiftMin; float _HueShiftMax;
                float  _SatShiftMin; float _SatShiftMax;
                float  _BriShiftMin; float _BriShiftMax;
                float4 _WindDirection;
                float  _WindSpeed;
                float  _WindStrength;
                float  _WindTurbulence;
                float  _WindHeightMask;
                float  _WindPhaseOffset;
                float  _FlipWindUV;
                float  _AlphaEdge1;
                float  _AlphaEdge2;
            CBUFFER_END

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct Varyings
            {
                float4 positionCS  : SV_POSITION;
                float3 normalWS    : TEXCOORD0;
                float3 normalOS    : TEXCOORD2;
                float3 positionWS  : TEXCOORD4;
                float2 uv          : TEXCOORD1;
                float3 leafRandom  : TEXCOORD3;
                float4 shadowCoord : TEXCOORD5; // ← koordinat untuk sample shadow map
            };

            // ================================================================
            //  UTILITY
            // ================================================================

            float Hash3to1(float3 p)
            {
                p = frac(p * float3(127.1, 311.7, 74.7));
                p += dot(p, p.yzx + 19.19);
                return frac((p.x + p.y) * p.z);
            }

            float3 RGBtoHSV(float3 c)
            {
                float4 K = float4(0.0, -1.0/3.0, 2.0/3.0, -1.0);
                float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
                float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));
                float d = q.x - min(q.w, q.y);
                float e = 1.0e-10;
                return float3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
            }

            float3 HSVtoRGB(float3 c)
            {
                float4 K = float4(1.0, 2.0/3.0, 1.0/3.0, 3.0);
                float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
                return c.z * lerp(K.xxx, saturate(p - K.xxx), c.y);
            }

            float3 ApplyHSVShift(float3 rgb, float hShift, float sShift, float bShift)
            {
                float3 hsv = RGBtoHSV(rgb);
                hsv.x = frac(hsv.x + hShift);
                hsv.y = saturate(hsv.y + sShift);
                hsv.z = saturate(hsv.z + bShift);
                return HSVtoRGB(hsv);
            }

            float2 RotateUV(float2 uv, float degrees)
            {
                float rad = degrees * (3.14159265 / 180.0);
                float s = sin(rad); float c = cos(rad);
                uv -= 0.5;
                uv = float2(uv.x * c - uv.y * s, uv.x * s + uv.y * c);
                uv += 0.5;
                return uv;
            }

            // ================================================================
            //  WIND
            // ================================================================
            float3 ApplyWind(float3 posOS, float uvY, float leafRandVal)
            {
                float2 windDir2D  = normalize(_WindDirection.xz + float2(0.0001, 0.0001));
                float  phase      = leafRandVal * _WindPhaseOffset;
                float  heightMask = pow(saturate(uvY), max(_WindHeightMask * 0.5, 0.1));
                float  t          = _Time.y * _WindSpeed;
                float  wave1      = sin(t + phase);
                float  wave2      = sin(t * _WindTurbulence * 0.7 + phase * 1.3) * 0.4;
                float  wave3      = sin(t * _WindTurbulence * 1.3 + phase * 0.7) * 0.2;
                float  windWave   = (wave1 + wave2 + wave3) / 1.6;
                float3 windOffset;
                windOffset.x = windDir2D.x * windWave * _WindStrength * heightMask;
                windOffset.z = windDir2D.y * windWave * _WindStrength * heightMask;
                windOffset.y = abs(windWave) * _WindStrength * 0.3 * heightMask;
                return posOS + windOffset;
            }

            // ================================================================
            //  VERTEX
            // ================================================================
            Varyings vert (Attributes IN)
            {
                Varyings OUT;

                float3 objectWorldPos = float3(
                    UNITY_MATRIX_M[0][3],
                    UNITY_MATRIX_M[1][3],
                    UNITY_MATRIX_M[2][3]
                );

                float3 seedPos = (_LeafSeedSource < 0.5) ? IN.positionOS.xyz : objectWorldPos;
                float  seed    = _LeafVariationSeed + 1.0;
                OUT.leafRandom = float3(
                    Hash3to1(seedPos * seed),
                    Hash3to1(seedPos * seed * 2.371 + 5.813),
                    Hash3to1(seedPos * seed * 4.927 + 11.43)
                );

                float  uvY   = (_FlipWindUV > 0.5) ? (1.0 - IN.uv.y) : IN.uv.y;
                float3 posOS = ApplyWind(IN.positionOS.xyz, uvY, OUT.leafRandom.x);

                OUT.positionCS = TransformObjectToHClip(posOS);
                OUT.positionWS = TransformObjectToWorld(posOS);
                OUT.normalWS   = TransformObjectToWorldNormal(IN.normalOS);
                OUT.normalOS   = IN.normalOS;
                OUT.uv         = IN.uv;

                // Hitung shadow coordinates dari world position
                OUT.shadowCoord = TransformWorldToShadowCoord(OUT.positionWS);

                return OUT;
            }

            // ================================================================
            //  FRAGMENT
            // ================================================================
            half4 frag (Varyings IN) : SV_Target
            {
                float3 normalWS      = normalize(IN.normalWS);
                float  gradientValue = 0;

                float3 center   = float3(_RadialWorldX, _RadialWorldY, _RadialWorldZ);
                Light  mainLight = GetMainLight(IN.shadowCoord); // ← pass shadowCoord untuk shadow
                float3 lightDir  = normalize(mainLight.direction);

                if (_GradientMode < 0.5)
                {
                    // LightDirection — proyeksi posisi ke arah cahaya
                    float proj        = dot(IN.positionWS, lightDir);
                    float centerProj  = dot(center, lightDir);
                    float projMin     = centerProj - _RadialRadius;
                    float projMax     = centerProj + _RadialRadius;
                    gradientValue = saturate((proj - projMin) / max(projMax - projMin, 0.001));
                }
                else if (_GradientMode < 1.5)
                {
                    // RadialStatic
                    float3 delta = IN.positionWS - center;
                    delta.y *= _RadialAspectY;
                    gradientValue = saturate(length(delta) / max(_RadialRadius, 0.001));
                }
                else if (_GradientMode < 2.5)
                {
                    // WorldY
                    float worldYMin = center.y - _RadialRadius;
                    float worldYMax = center.y + _RadialRadius;
                    gradientValue = saturate((IN.positionWS.y - worldYMin) / max(worldYMax - worldYMin, 0.001));
                }
                else if (_GradientMode < 3.5)
                {
                    float2 uv = RotateUV(IN.uv, _GradientRotate);
                    gradientValue = uv.y;
                }
                else
                {
                    float2 uv = RotateUV(IN.uv, _GradientRotate);
                    gradientValue = uv.x;
                }

                gradientValue = saturate(gradientValue + _GradientOffset);

                // ── Zona Dark / Mid / Bright ──
                float t1 = _DarkWidth;
                float t2 = saturate(_DarkWidth + _MidWidth);
                float e  = _EdgeSoftness;

                float darkToMid   = smoothstep(t1 - e, t1 + e, gradientValue);
                float midToBright = smoothstep(t2 - e, t2 + e, gradientValue);

                float3 color = _DarkColor.rgb;
                color = lerp(color, _MidColor.rgb,    darkToMid);
                color = lerp(color, _BrightColor.rgb, midToBright);

                // ── HSV shift per daun ──
                float hShift = lerp(_HueShiftMin, _HueShiftMax, IN.leafRandom.x);
                float sShift = lerp(_SatShiftMin, _SatShiftMax, IN.leafRandom.y);
                float bShift = lerp(_BriShiftMin, _BriShiftMax, IN.leafRandom.z);
                color = ApplyHSVShift(color, hShift, sShift, bShift);

                // ================================================================
                //  SHADOW
                // ================================================================
                // mainLight.shadowAttenuation: 1.0 = tidak kena shadow, 0.0 = kena shadow penuh
                float shadowAtten = mainLight.shadowAttenuation;

                // Warna shadow: blend antara gelap dan ShadowColor
                float3 shadowedColor = lerp(color * (1.0 - _ShadowStrength),
                                            _ShadowColor.rgb,
                                            _ShadowBlend * _ShadowStrength);

                // Terapkan shadow: shadowAtten=1 → warna normal, shadowAtten=0 → warna shadow
                color = lerp(shadowedColor, color, shadowAtten);

                // ── Alpha Clip ──
                float4 tex   = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float  alpha = smoothstep(_AlphaEdge1, _AlphaEdge2, tex.a);
                clip(alpha - 0.5);

                return half4(color, 1);
            }
            ENDHLSL
        }

        // ================================================================
        //  PASS 2: ShadowCaster — agar objek ini MEMBUANG shadow ke objek lain
        // ================================================================
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0 // tidak perlu tulis warna, hanya depth

            HLSLPROGRAM
            #pragma vertex vertShadow
            #pragma fragment fragShadow
            #pragma multi_compile_shadowcaster

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _BrightColor;
                float4 _MidColor;
                float4 _DarkColor;
                float  _DarkWidth;
                float  _MidWidth;
                float  _EdgeSoftness;
                float  _GradientMode;
                float  _GradientOffset;
                float  _GradientRotate;
                float  _RadialWorldX;
                float  _RadialWorldY;
                float  _RadialWorldZ;
                float  _RadialRadius;
                float  _RadialAspectY;
                float  _ShadowStrength;
                float4 _ShadowColor;
                float  _ShadowBlend;
                float  _LeafVariationSeed;
                float  _LeafSeedSource;
                float  _HueShiftMin; float _HueShiftMax;
                float  _SatShiftMin; float _SatShiftMax;
                float  _BriShiftMin; float _BriShiftMax;
                float4 _WindDirection;
                float  _WindSpeed;
                float  _WindStrength;
                float  _WindTurbulence;
                float  _WindHeightMask;
                float  _WindPhaseOffset;
                float  _FlipWindUV;
                float  _AlphaEdge1;
                float  _AlphaEdge2;
            CBUFFER_END

            float Hash3to1(float3 p)
            {
                p = frac(p * float3(127.1, 311.7, 74.7));
                p += dot(p, p.yzx + 19.19);
                return frac((p.x + p.y) * p.z);
            }

            float3 ApplyWind(float3 posOS, float uvY, float leafRandVal)
            {
                float2 windDir2D  = normalize(_WindDirection.xz + float2(0.0001, 0.0001));
                float  phase      = leafRandVal * _WindPhaseOffset;
                float  heightMask = pow(saturate(uvY), max(_WindHeightMask * 0.5, 0.1));
                float  t          = _Time.y * _WindSpeed;
                float  wave1      = sin(t + phase);
                float  wave2      = sin(t * _WindTurbulence * 0.7 + phase * 1.3) * 0.4;
                float  wave3      = sin(t * _WindTurbulence * 1.3 + phase * 0.7) * 0.2;
                float  windWave   = (wave1 + wave2 + wave3) / 1.6;
                float3 windOffset;
                windOffset.x = windDir2D.x * windWave * _WindStrength * heightMask;
                windOffset.z = windDir2D.y * windWave * _WindStrength * heightMask;
                windOffset.y = abs(windWave) * _WindStrength * 0.3 * heightMask;
                return posOS + windOffset;
            }

            struct AttributesShadow
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
            };

            struct VaryingsShadow
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
            };

            VaryingsShadow vertShadow (AttributesShadow IN)
            {
                VaryingsShadow OUT;

                float3 objectWorldPos = float3(
                    UNITY_MATRIX_M[0][3],
                    UNITY_MATRIX_M[1][3],
                    UNITY_MATRIX_M[2][3]
                );

                float3 seedPos    = objectWorldPos;
                float  seed       = _LeafVariationSeed + 1.0;
                float  leafRand   = Hash3to1(seedPos * seed);

                float  uvY   = (_FlipWindUV > 0.5) ? (1.0 - IN.uv.y) : IN.uv.y;
                float3 posOS = ApplyWind(IN.positionOS.xyz, uvY, leafRand);

                // Offset normal untuk menghindari shadow acne
                float3 worldNormal = TransformObjectToWorldNormal(IN.normalOS);
                float3 worldPos    = TransformObjectToWorld(posOS);
                worldPos = ApplyShadowBias(worldPos, worldNormal, _MainLightPosition.xyz);

                OUT.positionCS = TransformWorldToHClip(worldPos);
                OUT.uv         = IN.uv;
                return OUT;
            }

            half4 fragShadow (VaryingsShadow IN) : SV_Target
            {
                // Alpha clip sama seperti ForwardLit agar shadow mengikuti bentuk daun
                float4 tex   = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, IN.uv);
                float  alpha = smoothstep(_AlphaEdge1, _AlphaEdge2, tex.a);
                clip(alpha - 0.5);
                return 0;
            }
            ENDHLSL
        }
    }
}