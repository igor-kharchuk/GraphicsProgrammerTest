Shader "FluidShaderOptimized"
{
    Properties
    {
        [HDR][Header(Diffuse)]_DiffuseTint("Diffuse Tint", Color) = (1,1,1,0)
		_DiffuseLightingGradient("Diffuse Lighting Gradient", 2D) = "white" {}

		[Header(Specular)]_Smoothness("Smoothness", Range( 0 , 1)) = 0.5
		[HDR]_GlosinessColor("Glosiness Color", Color) = (1,1,1,0)

		[Header(Cubemap)]_CubemapInfluince("Cubemap Influince", Range( 0 , 1)) = 1
		_Roughness("Roughness", Range( 0 , 1)) = 1
		_lodSteps("lodSteps", Float) = 0
		_CubemapTInt("Cubemap TInt", Color) = (1,1,1,0)
		[SingleLineTexture]_Cubemap("Cubemap", CUBE) = "white" {}
		_CubemapDesaturation("CubemapDesaturation", Range( 0 , 1)) = 0.58
		_CubemapFresnel("Cubemap Fresnel", Range( 0 , 1)) = 0

        [Header(Noise Settings)]_NoiseScale("NoiseScale", Float) = 3
		_NoiseAmplitude("Noise Amplitude", Float) = 0.2
        _NoiseAnimationSpeed("Noise Animation Speed", Float) = 0.1
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" }
        LOD 100

        Pass
        {
            Name "UnlitPass"
            Tags { "LightMode"="UniversalForward" }
            Blend One Zero
            Cull Off
            ZWrite On

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "FluidShaderLib.hlsl"
    

            struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
			};

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float3 normalWS : TEXCOORD0;
                float3 viewDir : TEXCOORD1;
            };

            float3 GetNormalsWS(float4 tangent, float3 vertexNormalOS, float3 normalTS)
            {
                real3x3 tangentToWorld = CreateTangentToWorld(vertexNormalOS.xyz, tangent.xyz, tangent.w);
                // Actualy this function transforms normals from tangent to object space
                real3 normalOS = TransformTangentToWorld(normalTS, tangentToWorld, true);
                return TransformObjectToWorldDir(normalOS);
            }
            
            float _NoiseScale;
            float _NoiseAmplitude;
            float _NoiseAnimationSpeed;

            Varyings vert(Attributes input)
            {
                Varyings output;

                // Calculate displacement
                float displace = GetNoise(input.texcoord.xy, _NoiseScale, _NoiseAmplitude, _NoiseAnimationSpeed) + GetPaint(input.texcoord.xy);
                displace *= 2;
                input.positionOS += displace * float4(0,0,1,0);
                output.positionHCS = TransformObjectToHClip(input.positionOS);
                
                // Calculate normals
                float displaceDDX = GetNoise(input.texcoord.xy + float2(0.01, 0), _NoiseScale, _NoiseAmplitude, _NoiseAnimationSpeed) 
                                    + GetPaint(input.texcoord.xy + float2(0.01, 0));
                float displaceDDY = GetNoise(input.texcoord.xy + float2(0, 0.01), _NoiseScale, _NoiseAmplitude, _NoiseAnimationSpeed) 
                                    + GetPaint(input.texcoord.xy + float2(0, 0.01));
                displaceDDX *= 2;
                displaceDDY *= 2;
                float3 normalTS = SafeNormalize(cross(float3(1, 0, displaceDDX - input.positionOS.z), float3(0, 1, displaceDDY - input.positionOS.z)));
                output.normalWS = GetNormalsWS(input.tangent, input.normalOS, normalTS);

                //Calculate view direction
                float3 positionWS = TransformObjectToWorld(input.positionOS);
                float3 cameraPosWS = _WorldSpaceCameraPos;
                output.viewDir = normalize(cameraPosWS - positionWS);

                return output;
            }
            
            sampler2D _DiffuseLightingGradient;
            half3 _DiffuseTint;
            half3 _GlosinessColor;
            float _Smoothness; 

            samplerCUBE _Cubemap;
            half _Roughness;
            float _lodSteps;
            half _CubemapDesaturation;
            half3 _CubemapTInt;
            half _CubemapInfluince;

            half4 frag(Varyings input) : SV_TARGET
            {
                // Get Light Direction
                Light mainLight = GetMainLight();
                float3 mainLightDir = normalize(mainLight.direction);

                // Calculate basic lighting
                half3 lighting = CalculateLighting(_DiffuseLightingGradient, _DiffuseTint, _GlosinessColor,
                                                _Smoothness, input.normalWS, mainLightDir, input.viewDir);
                
                // Calculate specular environment                                                
                half3 specEnv = SpecularEnvironment(_Cubemap, _Roughness, _lodSteps, input.viewDir, input.normalWS);
                specEnv = Desaturation(specEnv, _CubemapDesaturation);
                specEnv *= _CubemapTInt;

                half4 result = half4(BlendSoftLight(lighting, specEnv, _CubemapInfluince), 1);

                return result;
            }

            ENDHLSL
        }
    }
}
