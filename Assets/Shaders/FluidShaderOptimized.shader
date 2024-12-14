Shader "FluidShaderOptimized"
{
    Properties
    {
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
                half4 testColor : TEXCOORD1;
            };
            
            float _NoiseScale;
            float _NoiseAmplitude;
            float _NoiseAnimationSpeed;

            Varyings vert(Attributes input)
            {
                Varyings output;

                float displace = GetNoise(input.texcoord.xy, _NoiseScale, _NoiseAmplitude, _NoiseAnimationSpeed) + GetPaint(input.texcoord.xy);
                displace *= 2;

                input.positionOS += displace * float4(0,0,1,0);

                float displaceDDX = GetNoise(input.texcoord.xy + float2(0.01, 0), _NoiseScale, _NoiseAmplitude, _NoiseAnimationSpeed) 
                                    + GetPaint(input.texcoord.xy + float2(0.01, 0));
                float displaceDDY = GetNoise(input.texcoord.xy + float2(0, 0.01), _NoiseScale, _NoiseAmplitude, _NoiseAnimationSpeed) 
                                    + GetPaint(input.texcoord.xy + float2(0, 0.01));
                displaceDDX *= 2;
                displaceDDY *= 2;
                output.normalWS = normalize(cross(float3(1, 0, displaceDDX - input.positionOS.z), float3(0, 1, displaceDDY - input.positionOS.z)));

                output.positionHCS = TransformObjectToHClip(input.positionOS);
                output.testColor = half4(output.normalWS, 1);
                return output;
            }

            half4 frag(Varyings input) : SV_TARGET
            {
                return input.testColor; // Білий колір
            }

            ENDHLSL
        }
    }
}
