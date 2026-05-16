// Shader Vegetasi URP - Tanpa Sistem Wind
// Compatible dengan URP 10.x - 14.x
// Fitur: Custom Color Tinting, Gradient, Snow, Translucency, Alpha Cutout

Shader "Polytope Studio/PT_Vegetation_Plants_NoWind_Shader"
{
    Properties
    {
        [HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
        [HideInInspector] _AlphaCutoff("Alpha Cutoff", Range(0, 1)) = 0.5

        [Header(Base Texture)]
        [NoScaleOffset] _BaseTexture("Base Texture", 2D) = "white" {}

        [Header(Custom Color Tinting)]
        [Toggle] _CUSTOMCOLORSTINTING("CUSTOM COLORS TINTING", Float) = 0
        [HDR] _TopColor("Top Color", Color) = (0, 0.2178235, 1, 1)
        [HDR] _GroundColor("Ground Color", Color) = (1, 0, 0, 1)
        _Gradient("Gradient", Range(0, 10)) = 1.4
        _GradientPower("Gradient Power", Range(0, 10)) = 1

        [Header(Leaves)]
        _LeavesThickness("Leaves Thickness", Range(0.1, 0.95)) = 0.5
        _Smoothness("Smoothness", Range(0, 1)) = 0

        [Header(Snow)]
        [Toggle(_SNOWONOFF_ON)] _SNOWONOFF("SNOW ON/OFF", Float) = 0
        _SnowGradient("Snow Gradient", Range(0, 1)) = 0.83
        _SnowCoverage("Snow Coverage", Range(0, 1)) = 0.45
        _SnowAmount("Snow Amount", Range(0, 1)) = 1

        [Header(Translucency)]
        [Toggle(_TRANSLUCENCYONOFF_ON)] _TRANSLUCENCYONOFF("TRANSLUCENCY ON/OFF", Float) = 1
        _TransStrength("Strength", Range(0, 50)) = 1
        _TransNormal("Normal Distortion", Range(0, 1)) = 0.5
        _TransScattering("Scattering", Range(1, 50)) = 2
        _TransDirect("Direct", Range(0, 1)) = 0.9
        _TransAmbient("Ambient", Range(0, 1)) = 0.1
        _TransShadow("Shadow", Range(0, 1)) = 0.5

        [HideInInspector][ToggleOff] _SpecularHighlights("Specular Highlights", Float) = 1
        [HideInInspector][ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1
        [HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}
    }

    SubShader
    {
        LOD 0

        Tags
        {
            "RenderPipeline" = "UniversalPipeline"
            "RenderType"     = "Transparent"
            "Queue"          = "Transparent"
        }

        Cull Off
        ZWrite Off
        ZTest LEqual
        AlphaToMask Off

        // =====================================================================
        // PASS 1 — Forward Lit
        // =====================================================================
        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            ZWrite On
            ZTest LEqual
            ColorMask RGBA

            HLSLPROGRAM
            #pragma target 3.5

            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF
            #pragma shader_feature_local _SNOWONOFF_ON
            #pragma shader_feature_local _TRANSLUCENCYONOFF_ON

            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile_fog
            #pragma multi_compile_instancing
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #pragma vertex   vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            // ------------------------------------------------------------------
            // CBUFFER — sama persis di semua pass agar SRP Batcher kompatibel
            // ------------------------------------------------------------------
            CBUFFER_START(UnityPerMaterial)
                float4 _GroundColor;
                float4 _TopColor;
                float  _CUSTOMCOLORSTINTING;
                float  _Gradient;
                float  _GradientPower;
                float  _SnowAmount;
                float  _SnowGradient;
                float  _SnowCoverage;
                float  _Smoothness;
                float  _LeavesThickness;
                float  _TransStrength;
                float  _TransNormal;
                float  _TransScattering;
                float  _TransDirect;
                float  _TransAmbient;
                float  _TransShadow;
            CBUFFER_END

            TEXTURE2D(_BaseTexture);
            SAMPLER(sampler_BaseTexture);

            // ------------------------------------------------------------------
            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float2 uv         : TEXCOORD0;
                float2 lightmapUV : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                float3 positionWS : TEXCOORD1;
                float3 normalWS   : TEXCOORD2;
                float4 shadowCoord: TEXCOORD3;
                half   fogFactor  : TEXCOORD4;
                half3  vertexSH   : TEXCOORD5;
                half3  vertexLight: TEXCOORD6;
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, lightmapSH, 7);
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // ------------------------------------------------------------------
            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                VertexPositionInputs posInputs  = GetVertexPositionInputs(IN.positionOS.xyz);
                VertexNormalInputs   normInputs = GetVertexNormalInputs(IN.normalOS, IN.tangentOS);

                OUT.positionCS = posInputs.positionCS;
                OUT.positionWS = posInputs.positionWS;
                OUT.normalWS   = normInputs.normalWS;
                OUT.uv         = IN.uv;
                OUT.shadowCoord = GetShadowCoord(posInputs);
                OUT.fogFactor   = ComputeFogFactor(posInputs.positionCS.z);
                OUT.vertexLight = VertexLighting(posInputs.positionWS, normInputs.normalWS);

                // Lightmap atau SH — macro menangani kedua kasus
                OUTPUT_LIGHTMAP_UV(IN.lightmapUV, unity_LightmapST, OUT.lightmapSH);
                OUTPUT_SH(normInputs.normalWS, OUT.vertexSH);

                return OUT;
            }

            // ------------------------------------------------------------------
            half4 frag(Varyings IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

                #ifdef LOD_FADE_CROSSFADE
                    LODDitheringTransition(IN.positionCS.xyz, unity_LODFade.x);
                #endif

                float3 normalWS  = normalize(IN.normalWS);
                float3 viewDirWS = normalize(_WorldSpaceCameraPos.xyz - IN.positionWS);

                // --- Sample texture ---
                float4 texColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, IN.uv);

                // --- Gradient ---
                float g         = clamp(pow(clamp(IN.uv.y * _Gradient, 0.0, 1.0), _GradientPower), 0.0, 1.0);
                float4 grad     = lerp(_GroundColor, _TopColor, g);
                float4 blended  = texColor * grad;
                float4 COLOR    = (_CUSTOMCOLORSTINTING > 0.5) ? blended : texColor;

                // --- Snow ---
                float fresnelNdotV = dot(normalWS, viewDirWS);
                float fresnel      = 0.11 + pow(max(1.0 - fresnelNdotV, 0.0), 1.0);
                float snowInput    = (1.0 - IN.uv.y * 0.65) + (-1.0 + _SnowCoverage * 2.0);
                float snowMask     = smoothstep(0.0, _SnowGradient, snowInput);
                float SNOW         = (_SnowAmount * 10.0 * fresnel) * snowMask;
                float4 snowColor   = float4(SNOW, SNOW, SNOW, 1.0);

                #ifdef _SNOWONOFF_ON
                    float4 finalColor = snowColor;
                #else
                    float4 finalColor = COLOR;
                #endif

                // --- Alpha cutout ---
                float alphaCut = 1.0 - step(texColor.a, 1.0 - _LeavesThickness);
                clip(alphaCut - 0.1);

                // --- Baked GI: pakai SampleSHVertex yang sudah di-interpolasi ---
                // OUTPUT_SH mengisi vertexSH di vertex shader; pakai di sini
                float3 bakedGI = SAMPLE_GI(IN.lightmapSH, IN.vertexSH, normalWS);

                // --- InputData ---
                InputData inputData      = (InputData)0;
                inputData.positionWS     = IN.positionWS;
                inputData.normalWS       = normalWS;
                inputData.viewDirectionWS = viewDirWS;
                inputData.shadowCoord    = IN.shadowCoord;
                inputData.fogCoord       = IN.fogFactor;
                inputData.vertexLighting = IN.vertexLight;
                inputData.bakedGI        = bakedGI;

                // --- SurfaceData ---
                SurfaceData surfaceData      = (SurfaceData)0;
                surfaceData.albedo           = finalColor.rgb;
                surfaceData.metallic         = 0.0;
                surfaceData.specular         = float3(0.5, 0.5, 0.5);
                surfaceData.smoothness       = saturate(_Smoothness);
                surfaceData.occlusion        = 1.0;
                surfaceData.emission         = float3(0, 0, 0);
                surfaceData.alpha            = saturate(alphaCut);
                surfaceData.normalTS         = float3(0, 0, 1);
                surfaceData.clearCoatMask    = 0;
                surfaceData.clearCoatSmoothness = 1;

                half4 color = UniversalFragmentPBR(inputData, surfaceData);

                // --- Translucency ---
                #ifdef _TRANSLUCENCYONOFF_ON
                {
                    float3 transColor = finalColor.rgb;
                    float shadow      = _TransShadow;
                    float nDist       = _TransNormal;
                    float scatter     = _TransScattering;
                    float direct      = _TransDirect;
                    float ambient     = _TransAmbient;
                    float strength    = _TransStrength;

                    Light mainLight  = GetMainLight(IN.shadowCoord);
                    float3 mainAtten = mainLight.color * mainLight.distanceAttenuation;
                    mainAtten = lerp(mainAtten, mainAtten * mainLight.shadowAttenuation, shadow);

                    half3 mainLDir  = mainLight.direction + normalWS * nDist;
                    half  mainVdotL = pow(saturate(dot(viewDirWS, -mainLDir)), scatter);
                    half3 mainTrans = mainAtten * (mainVdotL * direct + bakedGI * ambient) * transColor;
                    color.rgb += finalColor.rgb * mainTrans * strength;

                    #ifdef _ADDITIONAL_LIGHTS
                        int lightCount = GetAdditionalLightsCount();
                        for (int i = 0; i < lightCount; ++i)
                        {
                            Light light  = GetAdditionalLight(i, IN.positionWS);
                            float3 atten = light.color * light.distanceAttenuation;
                            atten        = lerp(atten, atten * light.shadowAttenuation, shadow);
                            half3 lDir   = light.direction + normalWS * nDist;
                            half  VdotL  = pow(saturate(dot(viewDirWS, -lDir)), scatter);
                            half3 trans  = atten * (VdotL * direct + bakedGI * ambient) * transColor;
                            color.rgb   += finalColor.rgb * trans * strength;
                        }
                    #endif
                }
                #endif

                color.rgb = MixFog(color.rgb, IN.fogFactor);
                return color;
            }
            ENDHLSL
        }

        // =====================================================================
        // PASS 2 — Shadow Caster
        // =====================================================================
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0

            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #pragma vertex   vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _GroundColor;
                float4 _TopColor;
                float  _CUSTOMCOLORSTINTING;
                float  _Gradient;
                float  _GradientPower;
                float  _SnowAmount;
                float  _SnowGradient;
                float  _SnowCoverage;
                float  _Smoothness;
                float  _LeavesThickness;
                float  _TransStrength;
                float  _TransNormal;
                float  _TransScattering;
                float  _TransDirect;
                float  _TransAmbient;
                float  _TransShadow;
            CBUFFER_END

            TEXTURE2D(_BaseTexture);
            SAMPLER(sampler_BaseTexture);

            float3 _LightDirection;
            float3 _LightPosition;

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                OUT.uv = IN.uv;
                float3 posWS    = TransformObjectToWorld(IN.positionOS.xyz);
                float3 normalWS = TransformObjectToWorldNormal(IN.normalOS);

                #ifdef _CASTING_PUNCTUAL_LIGHT_SHADOW
                    float3 lightDir = normalize(_LightPosition - posWS);
                #else
                    float3 lightDir = _LightDirection;
                #endif

                float4 posCS = TransformWorldToHClip(ApplyShadowBias(posWS, normalWS, lightDir));
                #if UNITY_REVERSED_Z
                    posCS.z = min(posCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    posCS.z = max(posCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif

                OUT.positionCS = posCS;
                return OUT;
            }

            half4 frag(Varyings IN) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                float4 tex      = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, IN.uv);
                float  alphaCut = 1.0 - step(tex.a, 1.0 - _LeavesThickness);
                clip(alphaCut - 0.1);

                #ifdef LOD_FADE_CROSSFADE
                    LODDitheringTransition(IN.positionCS.xyz, unity_LODFade.x);
                #endif
                return 0;
            }
            ENDHLSL
        }

        // =====================================================================
        // PASS 3 — Depth Only
        // =====================================================================
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0

            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #pragma vertex   vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _GroundColor;
                float4 _TopColor;
                float  _CUSTOMCOLORSTINTING;
                float  _Gradient;
                float  _GradientPower;
                float  _SnowAmount;
                float  _SnowGradient;
                float  _SnowCoverage;
                float  _Smoothness;
                float  _LeavesThickness;
                float  _TransStrength;
                float  _TransNormal;
                float  _TransScattering;
                float  _TransDirect;
                float  _TransAmbient;
                float  _TransShadow;
            CBUFFER_END

            TEXTURE2D(_BaseTexture);
            SAMPLER(sampler_BaseTexture);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                OUT.uv = IN.uv;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                float4 tex      = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, IN.uv);
                float  alphaCut = 1.0 - step(tex.a, 1.0 - _LeavesThickness);
                clip(alphaCut - 0.1);

                #ifdef LOD_FADE_CROSSFADE
                    LODDitheringTransition(IN.positionCS.xyz, unity_LODFade.x);
                #endif
                return 0;
            }
            ENDHLSL
        }

        // =====================================================================
        // PASS 4 — Depth Normals
        // =====================================================================
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode" = "DepthNormals" }

            ZWrite On
            Blend One Zero
            ZTest LEqual

            HLSLPROGRAM
            #pragma target 3.5
            #pragma multi_compile_instancing
            #pragma multi_compile_fragment _ LOD_FADE_CROSSFADE

            #pragma vertex   vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _GroundColor;
                float4 _TopColor;
                float  _CUSTOMCOLORSTINTING;
                float  _Gradient;
                float  _GradientPower;
                float  _SnowAmount;
                float  _SnowGradient;
                float  _SnowCoverage;
                float  _Smoothness;
                float  _LeavesThickness;
                float  _TransStrength;
                float  _TransNormal;
                float  _TransScattering;
                float  _TransDirect;
                float  _TransAmbient;
                float  _TransShadow;
            CBUFFER_END

            TEXTURE2D(_BaseTexture);
            SAMPLER(sampler_BaseTexture);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 normalWS   : TEXCOORD0;
                float2 uv         : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                OUT.uv         = IN.uv;
                OUT.normalWS   = TransformObjectToWorldNormal(IN.normalOS);
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                float4 tex      = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, IN.uv);
                float  alphaCut = 1.0 - step(tex.a, 1.0 - _LeavesThickness);
                clip(alphaCut - 0.1);

                #ifdef LOD_FADE_CROSSFADE
                    LODDitheringTransition(IN.positionCS.xyz, unity_LODFade.x);
                #endif

                float3 normalWS = normalize(IN.normalWS);
                return half4(normalWS * 0.5 + 0.5, 0.0);
            }
            ENDHLSL
        }

        // =====================================================================
        // PASS 5 — Meta (Lightmap baking)
        // =====================================================================
        Pass
        {
            Name "Meta"
            Tags { "LightMode" = "Meta" }

            Cull Off

            HLSLPROGRAM
            #pragma target 3.5
            #pragma shader_feature EDITOR_VISUALIZATION
            #pragma shader_feature_local _SNOWONOFF_ON

            #pragma vertex   vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/MetaInput.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _GroundColor;
                float4 _TopColor;
                float  _CUSTOMCOLORSTINTING;
                float  _Gradient;
                float  _GradientPower;
                float  _SnowAmount;
                float  _SnowGradient;
                float  _SnowCoverage;
                float  _Smoothness;
                float  _LeavesThickness;
                float  _TransStrength;
                float  _TransNormal;
                float  _TransScattering;
                float  _TransDirect;
                float  _TransAmbient;
                float  _TransShadow;
            CBUFFER_END

            TEXTURE2D(_BaseTexture);
            SAMPLER(sampler_BaseTexture);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv0        : TEXCOORD0;
                float2 uv1        : TEXCOORD1;
                float2 uv2        : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 positionWS : TEXCOORD0;
                float3 normalWS   : TEXCOORD1;
                float2 uv         : TEXCOORD2;
                #ifdef EDITOR_VISUALIZATION
                    float4 VizUV      : TEXCOORD3;
                    float4 LightCoord : TEXCOORD4;
                #endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                OUT.uv         = IN.uv0;
                OUT.positionWS = TransformObjectToWorld(IN.positionOS.xyz);
                OUT.normalWS   = TransformObjectToWorldNormal(IN.normalOS);
                OUT.positionCS = MetaVertexPosition(IN.positionOS, IN.uv1, IN.uv1,
                                                     unity_LightmapST, unity_DynamicLightmapST);

                #ifdef EDITOR_VISUALIZATION
                    float2 VizUV    = 0;
                    float4 LightCoord = 0;
                    UnityEditorVizData(IN.positionOS.xyz, IN.uv0, IN.uv1, IN.uv2, VizUV, LightCoord);
                    OUT.VizUV      = float4(VizUV, 0, 0);
                    OUT.LightCoord = LightCoord;
                #endif

                return OUT;
            }

            half4 frag(Varyings IN) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);

                float2 uv       = IN.uv;
                float4 texColor = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, uv);

                float g         = clamp(pow(clamp(uv.y * _Gradient, 0.0, 1.0), _GradientPower), 0.0, 1.0);
                float4 grad     = lerp(_GroundColor, _TopColor, g);
                float4 blended  = texColor * grad;
                float4 COLOR    = (_CUSTOMCOLORSTINTING > 0.5) ? blended : texColor;

                float3 viewDir  = normalize(_WorldSpaceCameraPos.xyz - IN.positionWS);
                float  fresnel  = 0.11 + pow(max(1.0 - dot(IN.normalWS, viewDir), 0.0), 1.0);
                float  snowIn   = (1.0 - uv.y * 0.65) + (-1.0 + _SnowCoverage * 2.0);
                float  snowMask = smoothstep(0.0, _SnowGradient, snowIn);
                float  SNOW     = (_SnowAmount * 10.0 * fresnel) * snowMask;
                float4 snowCol  = float4(SNOW, SNOW, SNOW, 1.0);

                #ifdef _SNOWONOFF_ON
                    float4 finalColor = snowCol;
                #else
                    float4 finalColor = COLOR;
                #endif

                float alphaCut = 1.0 - step(texColor.a, 1.0 - _LeavesThickness);
                clip(alphaCut - 0.1);

                MetaInput metaInput = (MetaInput)0;
                metaInput.Albedo    = finalColor.rgb;
                metaInput.Emission  = 0;
                #ifdef EDITOR_VISUALIZATION
                    metaInput.VizUV      = IN.VizUV.xy;
                    metaInput.LightCoord = IN.LightCoord;
                #endif

                return UnityMetaFragment(metaInput);
            }
            ENDHLSL
        }

        // =====================================================================
        // PASS 6 — Scene Selection
        // =====================================================================
        Pass
        {
            Name "SceneSelectionPass"
            Tags { "LightMode" = "SceneSelectionPass" }

            Cull Off

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex   vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            int _ObjectId;
            int _PassValue;

            CBUFFER_START(UnityPerMaterial)
                float4 _GroundColor;
                float4 _TopColor;
                float  _CUSTOMCOLORSTINTING;
                float  _Gradient;
                float  _GradientPower;
                float  _SnowAmount;
                float  _SnowGradient;
                float  _SnowCoverage;
                float  _Smoothness;
                float  _LeavesThickness;
                float  _TransStrength;
                float  _TransNormal;
                float  _TransScattering;
                float  _TransDirect;
                float  _TransAmbient;
                float  _TransShadow;
            CBUFFER_END

            TEXTURE2D(_BaseTexture);
            SAMPLER(sampler_BaseTexture);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                OUT.uv         = IN.uv;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_TARGET
            {
                float4 tex      = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, IN.uv);
                float  alphaCut = 1.0 - step(tex.a, 1.0 - _LeavesThickness);
                clip(alphaCut - 0.1);
                return half4(_ObjectId, _PassValue, 1.0, 1.0);
            }
            ENDHLSL
        }

        // =====================================================================
        // PASS 7 — Scene Picking
        // =====================================================================
        Pass
        {
            Name "ScenePickingPass"
            Tags { "LightMode" = "Picking" }

            HLSLPROGRAM
            #pragma target 3.5
            #pragma vertex   vert
            #pragma fragment frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            float4 _SelectionID;

            CBUFFER_START(UnityPerMaterial)
                float4 _GroundColor;
                float4 _TopColor;
                float  _CUSTOMCOLORSTINTING;
                float  _Gradient;
                float  _GradientPower;
                float  _SnowAmount;
                float  _SnowGradient;
                float  _SnowCoverage;
                float  _Smoothness;
                float  _LeavesThickness;
                float  _TransStrength;
                float  _TransNormal;
                float  _TransScattering;
                float  _TransDirect;
                float  _TransAmbient;
                float  _TransShadow;
            CBUFFER_END

            TEXTURE2D(_BaseTexture);
            SAMPLER(sampler_BaseTexture);

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            Varyings vert(Attributes IN)
            {
                Varyings OUT = (Varyings)0;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(OUT);

                OUT.uv         = IN.uv;
                OUT.positionCS = TransformObjectToHClip(IN.positionOS.xyz);
                return OUT;
            }

            half4 frag(Varyings IN) : SV_TARGET
            {
                float4 tex      = SAMPLE_TEXTURE2D(_BaseTexture, sampler_BaseTexture, IN.uv);
                float  alphaCut = 1.0 - step(tex.a, 1.0 - _LeavesThickness);
                clip(alphaCut - 0.1);
                return _SelectionID;
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/InternalErrorShader"
}
