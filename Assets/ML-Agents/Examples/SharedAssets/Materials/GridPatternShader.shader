// Converted from Built-in to URP (Unity 6.3 LTS / URP 17)
Shader "ML-Agents/GridPattern"
{
    Properties
    {
        _LineColor ("Line Color", Color) = (1,1,1,1)
        _CellColor ("Cell Color", Color) = (0,0,0,0)
        [PerRendererData] _MainTex ("Albedo (RGB)", 2D) = "white" {}
        [IntRange] _GridSize("Grid Size", Range(1,100)) = 10
        _LineSize("Line Size", Range(0,1)) = 0.15
        [IntRange] _DrawU("Draw U Toggle ( 0 = False , 1 = True )", Range(0,1)) = 1
        [IntRange] _DrawV("Draw V Toggle ( 0 = False , 1 = True )", Range(0,1)) = 1
    }

    SubShader
    {
        Tags
        {
            "RenderType"     = "TransparentCutout"
            "Queue"          = "AlphaTest"
            "RenderPipeline" = "UniversalPipeline"
        }
        LOD 200

        HLSLINCLUDE
        #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

        TEXTURE2D(_MainTex);
        SAMPLER(sampler_MainTex);

        CBUFFER_START(UnityPerMaterial)
            float4 _MainTex_ST;
            float4 _LineColor;
            float4 _CellColor;
            float  _GridSize;
            float  _LineSize;
            float  _DrawU;
            float  _DrawV;
        CBUFFER_END

        float4 ComputeGridColor(float2 uv)
        {
            float gsize   = floor(_GridSize) + _LineSize;
            float4 color  = _CellColor;
            float brightness = _CellColor.w;

            if (round(_DrawU) == 1.0)
            {
                if (frac(uv.x * gsize) <= _LineSize)
                {
                    brightness = _LineColor.w;
                    color      = _LineColor;
                }
            }
            if (round(_DrawV) == 1.0)
            {
                if (frac(uv.y * gsize) <= _LineSize)
                {
                    brightness = _LineColor.w;
                    color      = _LineColor;
                }
            }

            clip(brightness - 1e-5);

            return float4(color.rgb * brightness, brightness);
        }
        ENDHLSL

        Pass
        {
            Name "UniversalForward"
            Tags { "LightMode" = "UniversalForward" }

            Cull Back
            ZWrite On

            HLSLPROGRAM
            #pragma vertex   Vert
            #pragma fragment Frag
            #pragma multi_compile_instancing
            #pragma target 3.0

            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            Varyings Vert(Attributes IN)
            {
                Varyings OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv          = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            half4 Frag(Varyings IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                return ComputeGridColor(IN.uv);
            }
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }

            ZWrite On
            ZTest  LEqual
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex   ShadowVert
            #pragma fragment ShadowFrag
            #pragma multi_compile_instancing
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW
            #pragma target 3.0

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Shadows.hlsl"

            float3 _LightDirection;
            float3 _LightPosition;

            struct ShadowAttribs
            {
                float4 positionOS : POSITION;
                float3 normalOS   : NORMAL;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct ShadowVaryings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            ShadowVaryings ShadowVert(ShadowAttribs IN)
            {
                ShadowVaryings OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);

                float3 posWS  = TransformObjectToWorld(IN.positionOS.xyz);
                float3 normWS = TransformObjectToWorldNormal(IN.normalOS);

                #if _CASTING_PUNCTUAL_LIGHT_SHADOW
                    float3 lightDir = normalize(_LightPosition - posWS);
                #else
                    float3 lightDir = _LightDirection;
                #endif

                float4 posCS    = TransformWorldToHClip(ApplyShadowBias(posWS, normWS, lightDir));
                OUT.positionHCS = ApplyShadowClamping(posCS);
                OUT.uv          = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            half4 ShadowFrag(ShadowVaryings IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                ComputeGridColor(IN.uv);
                return 0;
            }
            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags { "LightMode" = "DepthOnly" }

            ZWrite On
            ColorMask 0
            Cull Back

            HLSLPROGRAM
            #pragma vertex   DepthVert
            #pragma fragment DepthFrag
            #pragma multi_compile_instancing
            #pragma target 3.0

            struct DepthAttribs
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct DepthVaryings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            DepthVaryings DepthVert(DepthAttribs IN)
            {
                DepthVaryings OUT;
                UNITY_SETUP_INSTANCE_ID(IN);
                UNITY_TRANSFER_INSTANCE_ID(IN, OUT);
                OUT.positionHCS = TransformObjectToHClip(IN.positionOS.xyz);
                OUT.uv          = TRANSFORM_TEX(IN.uv, _MainTex);
                return OUT;
            }

            half4 DepthFrag(DepthVaryings IN) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(IN);
                ComputeGridColor(IN.uv);
                return 0;
            }
            ENDHLSL
        }
    }

    FallBack "Universal Render Pipeline/Lit"
}