// Custom Leaf Atlas Shader v3
// Fix: Smooth shadow dithering + proper multi-axis wind

Shader "Custom/PT_Vegetation_LeafAtlas"
{
    Properties
    {
        [Header(Texture)]
        [NoScaleOffset] _BaseTexture ("Base Texture (Grayscale Atlas)", 2D) = "white" {}

        [Header(Alpha Cutout)]
        _LeavesThickness ("Leaves Thickness",   Range(0.01, 0.99)) = 0.5
        _AlphaSoftness   ("Alpha Edge Softness", Range(0.0,  0.5))  = 0.08

        [Header(Shadow)]
        _LeafShadowSoftness      ("Shadow Softness Bias", Range(0.0, 0.5)) = 0.15

        [Header(Color Tinting)]
        [Toggle] _CUSTOMCOLORSTINTING ("Enable Color Tinting", Float) = 1
        [HDR] _TopColor    ("Top Color",    Color) = (0.1, 0.55, 0.05, 1)
        [HDR] _GroundColor ("Bottom Color", Color) = (0.04, 0.25, 0.02, 1)
        _Gradient     ("Gradient Spread",  Range(0, 10)) = 1.4
        _GradientPower("Gradient Power",   Range(0, 10)) = 1.0
        _TintStrength ("Tint Strength",    Range(0,  1)) = 1.0
        _Brightness   ("Brightness",       Range(0,  3)) = 1.0

        [Header(Surface)]
        _Smoothness ("Smoothness", Range(0, 1)) = 0.0

        [Header(Wind Animation)]
        [Toggle(_CUSTOMWIND_ON)] _CUSTOMWIND ("Enable Wind", Float) = 1
        _WindMovement  ("Wind Speed",      Range(0, 10)) = 0.8
        _WindDensity   ("Wind Density",    Range(0,  5)) = 2.0
        _WindStrength  ("Wind Strength",   Range(0,  1)) = 0.25
        _WindTurbulence("Wind Turbulence", Range(0,  1)) = 0.4
        // Turbulence adds secondary high-freq noise for organic feel

        [Header(Translucency)]
        [Toggle(_TRANSLUCENCYONOFF_ON)] _TRANSLUCENCYONOFF ("Enable Translucency", Float) = 1
        _TransStrength  ("Strength",          Range(0, 50)) = 1.0
        _TransNormal    ("Normal Distortion", Range(0,  1)) = 0.5
        _TransScattering("Scattering",        Range(1, 50)) = 2.0
        _TransDirect    ("Direct",            Range(0,  1)) = 0.9
        _TransAmbient   ("Ambient",           Range(0,  1)) = 0.1
        _TransShadow    ("Shadow",            Range(0,  1)) = 0.5

        [HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
        [HideInInspector][ToggleOff] _SpecularHighlights    ("Specular Highlights",     Float) = 1
        [HideInInspector][ToggleOff] _EnvironmentReflections("Environment Reflections", Float) = 1
        [HideInInspector][ToggleOff] _ReceiveShadows        ("Receive Shadows",         Float) = 1.0
        [HideInInspector] _QueueOffset  ("_QueueOffset",  Float) = 0
        [HideInInspector] _QueueControl ("_QueueControl", Float) = -1
    }

    SubShader
    {
        LOD 0

        Tags
        {
            "RenderPipeline"="UniversalPipeline"
            "RenderType"="TransparentCutout"
            "Queue"="AlphaTest"
            "UniversalMaterialType"="Lit"
        }

        Cull Off
        ZWrite On
        ZTest LEqual
        AlphaToMask Off

        // ============================================================
        //  SHARED HELPERS — included in every pass via macro below
        // ============================================================

        // ============================================================
        //  PASS 1 — Forward Lit
        // ============================================================
        Pass
        {
            Name "Forward"
            Tags { "LightMode"="UniversalForward" }

            Blend SrcAlpha OneMinusSrcAlpha, One OneMinusSrcAlpha
            ZWrite On
            ColorMask RGBA

            HLSLPROGRAM
            #pragma target 3.5
            #pragma prefer_hlslcc gles

            #pragma shader_feature_local _CUSTOMWIND_ON
            #pragma shader_feature_local _TRANSLUCENCYONOFF_ON
            #pragma shader_feature_local _RECEIVE_SHADOWS_OFF

            #pragma multi_compile_instancing
            #pragma multi_compile_fog
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS
            #pragma multi_compile_fragment _ _ADDITIONAL_LIGHT_SHADOWS
            #pragma multi_compile_fragment _ _SHADOWS_SOFT
            #pragma multi_compile _ LIGHTMAP_SHADOW_MIXING
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON

            #pragma vertex   vert
            #pragma fragment frag

            #define SHADERPASS SHADERPASS_FORWARD
            #define _ALPHATEST_ON 1

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _TopColor;
                float4 _GroundColor;
                float  _Gradient;
                float  _GradientPower;
                float  _TintStrength;
                float  _Brightness;
                float  _CUSTOMCOLORSTINTING;
                float  _LeavesThickness;
                float  _AlphaSoftness;
                float  _LeafShadowSoftness;
                float  _Smoothness;
                float  _WindMovement;
                float  _WindDensity;
                float  _WindStrength;
                float  _WindTurbulence;
                float  _TransStrength;
                float  _TransNormal;
                float  _TransScattering;
                float  _TransDirect;
                float  _TransAmbient;
                float  _TransShadow;
            CBUFFER_END

            sampler2D _BaseTexture;

            // ── Simplex 2D noise ───────────────────────────────────────
            float3 mod289(float3 x){return x-floor(x*(1.0/289.0))*289.0;}
            float2 mod289(float2 x){return x-floor(x*(1.0/289.0))*289.0;}
            float3 permute(float3 x){return mod289(((x*34.0)+1.0)*x);}
            float snoise(float2 v)
            {
                const float4 C=float4(0.211324865405187,0.366025403784439,-0.577350269189626,0.024390243902439);
                float2 i=floor(v+dot(v,C.yy));
                float2 x0=v-i+dot(i,C.xx);
                float2 i1=(x0.x>x0.y)?float2(1,0):float2(0,1);
                float4 x12=x0.xyxy+C.xxzz; x12.xy-=i1; i=mod289(i);
                float3 p=permute(permute(i.y+float3(0,i1.y,1))+i.x+float3(0,i1.x,1));
                float3 m=max(0.5-float3(dot(x0,x0),dot(x12.xy,x12.xy),dot(x12.zw,x12.zw)),0.0);
                m=m*m; m=m*m;
                float3 x2=2.0*frac(p*C.www)-1.0;
                float3 h=abs(x2)-0.5; float3 a0=x2-floor(x2+0.5);
                m*=1.79284291400159-0.85373472095314*(a0*a0+h*h);
                float3 g; g.x=a0.x*x0.x+h.x*x0.y; g.yz=a0.yz*x12.xz+h.yz*x12.yw;
                return 130.0*dot(m,g);
            }

            // ── Wind: multi-axis, organic ──────────────────────────────
            // World-space position input so every vertex uses its own
            // world location → entire canopy moves naturally
            float3 ComputeWind(float3 posOS, float3 posWS)
            {
                float  t    = _TimeParameters.x * _WindMovement;
                float  h    = saturate(posOS.y * 1.5);  // height mask 0-1

                // Primary low-frequency sway — X and Z
                float2 uvP  = posWS.xz * _WindDensity * 0.5 + t;
                float  nX   = snoise(uvP);
                float  nZ   = snoise(uvP + float2(3.7, 1.3));

                // Secondary turbulence — higher frequency, smaller amplitude
                float2 uvT  = posWS.xz * _WindDensity * 2.0 + t * 1.7 + float2(5.1, 2.9);
                float  tX   = snoise(uvT)           * _WindTurbulence;
                float  tZ   = snoise(uvT+float2(4,2))* _WindTurbulence;

                float3 offset;
                offset.x = (nX + tX) * _WindStrength * h;
                offset.y = abs(nX)   * _WindStrength * h * 0.15; // tiny Y bob
                offset.z = (nZ + tZ) * _WindStrength * h * 0.6;

                return offset;
            }

            // ── Structs ────────────────────────────────────────────────
            struct VertexInput
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float4 tangentOS  : TANGENT;
                float4 texcoord   : TEXCOORD0;
                float4 texcoord1  : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct VertexOutput
            {
                float4 positionCS             : SV_POSITION;
                float4 lightmapUVOrVertexSH   : TEXCOORD0;
                half4  fogFactorAndVertexLight : TEXCOORD1;
                float4 tSpace0                : TEXCOORD2;
                float4 tSpace1                : TEXCOORD3;
                float4 tSpace2                : TEXCOORD4;
                float4 shadowCoord            : TEXCOORD5;
                float2 uv                     : TEXCOORD6;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
            };

            VertexOutput vert(VertexInput v)
            {
                VertexOutput o = (VertexOutput)0;
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                // Compute wind in world space first, apply in object space
                float3 posWS_pre = TransformObjectToWorld(v.positionOS.xyz);

                #ifdef _CUSTOMWIND_ON
                    float3 windOffset = ComputeWind(v.positionOS.xyz, posWS_pre);
                    // Convert world-space offset back to object space
                    float3 windOS = mul((float3x3)GetWorldToObjectMatrix(), windOffset);
                    v.positionOS.xyz += windOS;
                #endif

                VertexPositionInputs vpi = GetVertexPositionInputs(v.positionOS.xyz);
                VertexNormalInputs   vni = GetVertexNormalInputs(v.normalOS, v.tangentOS);

                o.tSpace0 = float4(vni.normalWS,    vpi.positionWS.x);
                o.tSpace1 = float4(vni.tangentWS,   vpi.positionWS.y);
                o.tSpace2 = float4(vni.bitangentWS, vpi.positionWS.z);
                o.uv      = v.texcoord.xy;

                #ifdef LIGHTMAP_ON
                    OUTPUT_LIGHTMAP_UV(v.texcoord1, unity_LightmapST, o.lightmapUVOrVertexSH.xy);
                #else
                    OUTPUT_SH(vni.normalWS, o.lightmapUVOrVertexSH.xyz);
                #endif

                o.fogFactorAndVertexLight = half4(
                    ComputeFogFactor(vpi.positionCS.z),
                    VertexLighting(vpi.positionWS, vni.normalWS)
                );
                o.shadowCoord = GetShadowCoord(vpi);
                o.positionCS  = vpi.positionCS;
                return o;
            }

            // ── Ordered dither table (4x4 Bayer) for smooth shadow ─────
            float BayerDither(float2 screenPos)
            {
                // 4x4 Bayer matrix, returns 0..1
                int2  p = int2(fmod(screenPos, 4.0));
                float4x4 bayer = float4x4(
                     0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
                    12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0,
                     3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
                    15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0
                );
                return bayer[p.x][p.y];
            }

            half4 frag(VertexOutput IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(IN);

                float3 WorldNormal  = normalize(IN.tSpace0.xyz);
                float3 WorldPos     = float3(IN.tSpace0.w, IN.tSpace1.w, IN.tSpace2.w);
                float3 WorldViewDir = SafeNormalize(_WorldSpaceCameraPos.xyz - WorldPos);
                float4 ShadowCoords = IN.shadowCoord;

                // ── Grayscale → luminance ──────────────────────────────
                float4 texSample = tex2D(_BaseTexture, IN.uv);
                float  gray      = dot(texSample.rgb, float3(0.299, 0.587, 0.114));

                // ── Smooth alpha edge (softer than hard step) ──────────
                float  thresh    = 1.0 - _LeavesThickness;
                float  Alpha     = smoothstep(thresh - _AlphaSoftness,
                                              thresh + _AlphaSoftness, gray);
                clip(Alpha - 0.01);

                // ── Gradient color tinting ─────────────────────────────
                float  t        = clamp(pow(clamp(IN.uv.y * _Gradient, 0.0, 1.0), _GradientPower), 0.0, 1.0);
                float3 gradient = lerp(_GroundColor.rgb, _TopColor.rgb, t);
                float3 tintedColor = gradient * gray * _Brightness;
                float3 rawColor    = gray * _Brightness;
                float3 BaseColor   = (_CUSTOMCOLORSTINTING > 0.5)
                                   ? lerp(rawColor, tintedColor, _TintStrength)
                                   : rawColor;

                #ifdef _TRANSLUCENCYONOFF_ON
                    float3 TransColor = BaseColor;
                #else
                    float3 TransColor = (float3)0;
                #endif

                // ── BakedGI ────────────────────────────────────────────
                #ifdef LIGHTMAP_ON
                    float3 bakedGI = SampleLightmap(IN.lightmapUVOrVertexSH.xy, WorldNormal);
                #else
                    float3 bakedGI = IN.lightmapUVOrVertexSH.xyz;
                #endif

                InputData inputData;
                inputData.positionWS              = WorldPos;
                inputData.normalWS                = WorldNormal;
                inputData.viewDirectionWS         = WorldViewDir;
                inputData.shadowCoord             = ShadowCoords;
                inputData.fogCoord                = IN.fogFactorAndVertexLight.x;
                inputData.vertexLighting           = IN.fogFactorAndVertexLight.yzw;
                inputData.bakedGI                 = bakedGI;
                inputData.normalizedScreenSpaceUV = float2(0,0);
                inputData.shadowMask              = unity_ProbesOcclusion;

                SurfaceData surf;
                surf.albedo              = BaseColor;
                surf.metallic            = 0;
                surf.specular            = 0.5;
                surf.smoothness          = saturate(_Smoothness);
                surf.occlusion           = 1;
                surf.emission            = 0;
                surf.alpha               = saturate(Alpha);
                surf.normalTS            = float3(0,0,1);
                surf.clearCoatMask       = 0;
                surf.clearCoatSmoothness = 1;

                half4 color = UniversalFragmentPBR(inputData, surf);

                // ── Translucency ───────────────────────────────────────
                #ifdef _TRANSLUCENCYONOFF_ON
                {
                    Light mainLight = GetMainLight(ShadowCoords);
                    float3 atten = mainLight.color * mainLight.distanceAttenuation;
                    atten = lerp(atten, atten * mainLight.shadowAttenuation, _TransShadow);
                    half3  lDir  = mainLight.direction + WorldNormal * _TransNormal;
                    half   VdotL = pow(saturate(dot(WorldViewDir, -lDir)), _TransScattering);
                    color.rgb   += BaseColor * atten
                                 * (VdotL * _TransDirect + bakedGI * _TransAmbient)
                                 * TransColor * _TransStrength;
                    #ifdef _ADDITIONAL_LIGHTS
                    {
                        int n = GetAdditionalLightsCount();
                        for (int li = 0; li < n; ++li)
                        {
                            Light l2  = GetAdditionalLight(li, WorldPos);
                            float3 la = l2.color * l2.distanceAttenuation;
                            la = lerp(la, la * l2.shadowAttenuation, _TransShadow);
                            half3  ld2 = l2.direction + WorldNormal * _TransNormal;
                            half   vl2 = pow(saturate(dot(WorldViewDir, -ld2)), _TransScattering);
                            color.rgb += BaseColor * la
                                       * (vl2 * _TransDirect + bakedGI * _TransAmbient)
                                       * TransColor * _TransStrength;
                        }
                    }
                    #endif
                }
                #endif

                color.rgb = MixFog(color.rgb, IN.fogFactorAndVertexLight.x);
                return color;
            }
            ENDHLSL
        }

        // ============================================================
        //  PASS 2 — Shadow Caster  (softer via dithered alpha)
        // ============================================================
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode"="ShadowCaster" }

            ZWrite On
            ZTest LEqual
            ColorMask 0
            Cull Off

            HLSLPROGRAM
            #pragma target 3.5
            #pragma prefer_hlslcc gles
            #pragma multi_compile_instancing
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma shader_feature_local _CUSTOMWIND_ON
            #pragma vertex   vert
            #pragma fragment frag
            #define SHADERPASS SHADERPASS_SHADOWCASTER

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _TopColor; float4 _GroundColor;
                float _Gradient; float _GradientPower; float _TintStrength; float _Brightness;
                float _CUSTOMCOLORSTINTING; float _LeavesThickness; float _AlphaSoftness; float _LeafShadowSoftness;
                float _Smoothness; float _WindMovement; float _WindDensity;
                float _WindStrength; float _WindTurbulence;
                float _TransStrength; float _TransNormal; float _TransScattering;
                float _TransDirect; float _TransAmbient; float _TransShadow;
            CBUFFER_END

            sampler2D _BaseTexture;

            // Simplex (copy for this pass)
            float3 mod289sc(float3 x){return x-floor(x*(1.0/289.0))*289.0;}
            float2 mod289sc(float2 x){return x-floor(x*(1.0/289.0))*289.0;}
            float3 permutesc(float3 x){return mod289sc(((x*34.0)+1.0)*x);}
            float snoisesc(float2 v)
            {
                const float4 C=float4(0.211324865405187,0.366025403784439,-0.577350269189626,0.024390243902439);
                float2 i=floor(v+dot(v,C.yy));float2 x0=v-i+dot(i,C.xx);
                float2 i1=(x0.x>x0.y)?float2(1,0):float2(0,1);
                float4 x12=x0.xyxy+C.xxzz;x12.xy-=i1;i=mod289sc(i);
                float3 p=permutesc(permutesc(i.y+float3(0,i1.y,1))+i.x+float3(0,i1.x,1));
                float3 m=max(0.5-float3(dot(x0,x0),dot(x12.xy,x12.xy),dot(x12.zw,x12.zw)),0.0);
                m=m*m;m=m*m;float3 x2=2.0*frac(p*C.www)-1.0;
                float3 h=abs(x2)-0.5;float3 a0=x2-floor(x2+0.5);
                m*=1.79284291400159-0.85373472095314*(a0*a0+h*h);
                float3 g;g.x=a0.x*x0.x+h.x*x0.y;g.yz=a0.yz*x12.xz+h.yz*x12.yw;
                return 130.0*dot(m,g);
            }

            float3 ComputeWindSC(float3 posOS, float3 posWS)
            {
                float t=_TimeParameters.x*_WindMovement;
                float h=saturate(posOS.y*1.5);
                float2 uvP=posWS.xz*_WindDensity*0.5+t;
                float nX=snoisesc(uvP); float nZ=snoisesc(uvP+float2(3.7,1.3));
                float2 uvT=posWS.xz*_WindDensity*2.0+t*1.7+float2(5.1,2.9);
                float tX=snoisesc(uvT)*_WindTurbulence; float tZ=snoisesc(uvT+float2(4,2))*_WindTurbulence;
                return float3((nX+tX)*_WindStrength*h, abs(nX)*_WindStrength*h*0.15, (nZ+tZ)*_WindStrength*h*0.6);
            }

            float3 _LightDirection;
            float3 _LightPosition;

            struct VSI { float4 posOS:POSITION; float3 normOS:NORMAL; float2 uv:TEXCOORD0; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct VSO { float4 posCS:SV_POSITION; float2 uv:TEXCOORD0; float4 screenPos:TEXCOORD1; UNITY_VERTEX_INPUT_INSTANCE_ID UNITY_VERTEX_OUTPUT_STEREO };

            VSO vert(VSI v)
            {
                VSO o;
                UNITY_SETUP_INSTANCE_ID(v); UNITY_TRANSFER_INSTANCE_ID(v,o); UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                #ifdef _CUSTOMWIND_ON
                    float3 posWSpre = TransformObjectToWorld(v.posOS.xyz);
                    float3 wOff     = ComputeWindSC(v.posOS.xyz, posWSpre);
                    float3 wOS      = mul((float3x3)GetWorldToObjectMatrix(), wOff);
                    v.posOS.xyz    += wOS;
                #endif
                o.uv = v.uv;
                float3 posWS = TransformObjectToWorld(v.posOS.xyz);
                float3 nWS   = TransformObjectToWorldDir(v.normOS);
                #if defined(_CASTING_PUNCTUAL_LIGHT_SHADOW)
                    float3 ld = normalize(_LightPosition-posWS);
                #else
                    float3 ld = _LightDirection;
                #endif
                float4 posCS = TransformWorldToHClip(ApplyShadowBias(posWS, nWS, ld));
                #if UNITY_REVERSED_Z
                    posCS.z = min(posCS.z, UNITY_NEAR_CLIP_VALUE);
                #else
                    posCS.z = max(posCS.z, UNITY_NEAR_CLIP_VALUE);
                #endif
                o.posCS     = posCS;
                o.screenPos = ComputeScreenPos(posCS);
                return o;
            }

            half4 frag(VSO IN) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                float4 t = tex2D(_BaseTexture, IN.uv);
                float  g = dot(t.rgb, float3(0.299,0.587,0.114));

                // Smooth shadow edge via dithered threshold
                // ShadowBias loosens the threshold so edges dissolve gradually
                float  thresh = 1.0 - _LeavesThickness + _LeafShadowSoftness;

                // Bayer 4x4 dither based on screen pixel position
                float2 screenPx = IN.screenPos.xy / IN.screenPos.w
                                  * _ScreenParams.xy;
                int2   pi       = int2(fmod(screenPx, 4.0));
                const float bayer[16] = {
                     0.0/16.0,  8.0/16.0,  2.0/16.0, 10.0/16.0,
                    12.0/16.0,  4.0/16.0, 14.0/16.0,  6.0/16.0,
                     3.0/16.0, 11.0/16.0,  1.0/16.0,  9.0/16.0,
                    15.0/16.0,  7.0/16.0, 13.0/16.0,  5.0/16.0
                };
                float dither = bayer[pi.y * 4 + pi.x] * 0.2; // subtle scatter

                // Dissolve shadow at edges → softer self-shadow on canopy
                clip(g - (thresh - dither));
                return 0;
            }
            ENDHLSL
        }

        // ============================================================
        //  PASS 3 — Depth Only
        // ============================================================
        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode"="DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull Off

            HLSLPROGRAM
            #pragma target 3.5
            #pragma prefer_hlslcc gles
            #pragma multi_compile_instancing
            #pragma vertex   vert
            #pragma fragment frag
            #define SHADERPASS SHADERPASS_DEPTHONLY

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _TopColor; float4 _GroundColor;
                float _Gradient; float _GradientPower; float _TintStrength; float _Brightness;
                float _CUSTOMCOLORSTINTING; float _LeavesThickness; float _AlphaSoftness; float _LeafShadowSoftness;
                float _Smoothness; float _WindMovement; float _WindDensity;
                float _WindStrength; float _WindTurbulence;
                float _TransStrength; float _TransNormal; float _TransScattering;
                float _TransDirect; float _TransAmbient; float _TransShadow;
            CBUFFER_END

            sampler2D _BaseTexture;

            struct DVI { float4 posOS:POSITION; float2 uv:TEXCOORD0; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct DVO { float4 posCS:SV_POSITION; float2 uv:TEXCOORD0; UNITY_VERTEX_INPUT_INSTANCE_ID UNITY_VERTEX_OUTPUT_STEREO };

            DVO vert(DVI v)
            {
                DVO o;
                UNITY_SETUP_INSTANCE_ID(v); UNITY_TRANSFER_INSTANCE_ID(v,o); UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.uv    = v.uv;
                o.posCS = TransformObjectToHClip(v.posOS.xyz);
                return o;
            }
            half4 frag(DVO IN) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                float4 t = tex2D(_BaseTexture, IN.uv);
                float  g = dot(t.rgb, float3(0.299,0.587,0.114));
                clip((1.0 - step(g, 1.0 - _LeavesThickness)) - 0.1);
                return 0;
            }
            ENDHLSL
        }

        // ============================================================
        //  PASS 4 — DepthNormals
        // ============================================================
        Pass
        {
            Name "DepthNormals"
            Tags { "LightMode"="DepthNormals" }

            ZWrite On
            Blend One Zero
            ZTest LEqual
            Cull Off

            HLSLPROGRAM
            #pragma target 3.5
            #pragma prefer_hlslcc gles
            #pragma multi_compile_instancing
            #pragma vertex   vert
            #pragma fragment frag
            #define SHADERPASS SHADERPASS_DEPTHNORMALSONLY

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            CBUFFER_START(UnityPerMaterial)
                float4 _TopColor; float4 _GroundColor;
                float _Gradient; float _GradientPower; float _TintStrength; float _Brightness;
                float _CUSTOMCOLORSTINTING; float _LeavesThickness; float _AlphaSoftness; float _LeafShadowSoftness;
                float _Smoothness; float _WindMovement; float _WindDensity;
                float _WindStrength; float _WindTurbulence;
                float _TransStrength; float _TransNormal; float _TransScattering;
                float _TransDirect; float _TransAmbient; float _TransShadow;
            CBUFFER_END

            sampler2D _BaseTexture;

            struct NVI { float4 posOS:POSITION; float3 normOS:NORMAL; float2 uv:TEXCOORD0; UNITY_VERTEX_INPUT_INSTANCE_ID };
            struct NVO { float4 posCS:SV_POSITION; float3 wNorm:TEXCOORD0; float2 uv:TEXCOORD1; UNITY_VERTEX_INPUT_INSTANCE_ID UNITY_VERTEX_OUTPUT_STEREO };

            NVO vert(NVI v)
            {
                NVO o;
                UNITY_SETUP_INSTANCE_ID(v); UNITY_TRANSFER_INSTANCE_ID(v,o); UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.uv    = v.uv;
                o.wNorm = TransformObjectToWorldNormal(v.normOS);
                o.posCS = TransformObjectToHClip(v.posOS.xyz);
                return o;
            }
            half4 frag(NVO IN) : SV_TARGET
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                float4 t = tex2D(_BaseTexture, IN.uv);
                float  g = dot(t.rgb, float3(0.299,0.587,0.114));
                clip((1.0 - step(g, 1.0 - _LeavesThickness)) - 0.1);
                return half4(normalize(IN.wNorm), 0.0);
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/InternalErrorShader"
}
