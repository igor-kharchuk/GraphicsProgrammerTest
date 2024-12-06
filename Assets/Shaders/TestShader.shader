// Made with Amplify Shader Editor v1.9.7.1
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "TestShader"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HDR][Header(Diffuse)]_DiffuseTint("Diffuse Tint", Color) = (1,1,1,0)
		[SingleLineTexture]_DiffuseLightingGradient("Diffuse Lighting Gradient", 2D) = "white" {}
		[Header(Specular)]_Shininess("Shininess", Float) = 2
		[HDR]_SpecularTint("Specular Tint", Color) = (1,1,1,0)
		[SingleLineTexture]_SpecularLightingGradient("Specular Lighting Gradient", 2D) = "white" {}
		[Header(Rim Light Settings)]_Bias("Bias", Float) = 0
		_Scale("Scale", Float) = 1
		_Power("Power", Float) = 5
		_RimColor("Rim Color", Color) = (0.4412928,0.3859454,0.3546536,0)
		[Header(Cubemap)]_CubemapInfluince("Cubemap Influince", Range( 0 , 1)) = 1
		_Roughness("Roughness", Range( 0 , 1)) = 1
		_lodSteps("lodSteps", Float) = 0
		_CubemapTInt("Cubemap TInt", Color) = (1,1,1,0)
		[SingleLineTexture]_Cubemap("Cubemap", CUBE) = "white" {}
		[Header(FBM Settings)]_fbmoctaves("fbm octaves", Int) = 1
		_fbmlacunarity("fbm lacunarity", Float) = 0
		_fbmgain("fbm gain", Float) = 0
		_fbmamplitude("fbm amplitude", Float) = 1
		_fbmscale("fbm scale", Float) = 0
		_NormalGradient("Normal Gradient", Float) = 1


		[HideInInspector] _QueueOffset("_QueueOffset", Float) = 0
        [HideInInspector] _QueueControl("_QueueControl", Float) = -1

        [HideInInspector][NoScaleOffset] unity_Lightmaps("unity_Lightmaps", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_LightmapsInd("unity_LightmapsInd", 2DArray) = "" {}
        [HideInInspector][NoScaleOffset] unity_ShadowMasks("unity_ShadowMasks", 2DArray) = "" {}

		[HideInInspector][ToggleUI] _AddPrecomputedVelocity("Add Precomputed Velocity", Float) = 1
		[HideInInspector][ToggleOff] _ReceiveShadows("Receive Shadows", Float) = 1.0
	}

	SubShader
	{
		LOD 0

		

		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" "UniversalMaterialType"="Unlit" }

		Cull Back
		AlphaToMask Off

		

		HLSLINCLUDE
		#pragma target 4.5
		#pragma prefer_hlslcc gles
		#pragma only_renderers glcore gles gles3 metal vulkan // ensure rendering platforms toggle list is visible

		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
		#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Filtering.hlsl"
        ENDHLSL

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForwardOnly" }

			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA

			

			HLSLPROGRAM

			#define ASE_ABSOLUTE_VERTEX_POS 1
			#define ASE_VERSION 19701
			#define ASE_SRP_VERSION 170003


			#pragma multi_compile_fragment _ _SCREEN_SPACE_OCCLUSION
			#pragma multi_compile_fragment _ _DBUFFER_MRT1 _DBUFFER_MRT2 _DBUFFER_MRT3
			#pragma multi_compile_fragment _ _GBUFFER_NORMALS_OCT

			#pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
			#pragma multi_compile_fragment _ DEBUG_DISPLAY

			#pragma vertex vert
			#pragma fragment frag

			#define SHADERPASS SHADERPASS_UNLIT

			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DOTS.hlsl"
			#include_with_pragmas "Packages/com.unity.render-pipelines.universal/ShaderLibrary/RenderingLayers.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Texture.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Input.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/TextureStack.hlsl"
			#include_with_pragmas "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRenderingKeywords.hlsl"
            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/FoveatedRendering.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/DBuffer.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/Editor/ShaderGraph/Includes/ShaderPass.hlsl"

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Debug/Debugging3D.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/SurfaceData.hlsl"

			#if defined(LOD_FADE_CROSSFADE)
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/LODCrossFade.hlsl"
            #endif

			#include "FluidShaderLib.hlsl"
			#define ASE_NEEDS_VERT_POSITION
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_NORMAL


			struct Attributes
			{
				float4 positionOS : POSITION;
				float3 normalOS : NORMAL;
				float4 ase_tangent : TANGENT;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct PackedVaryings
			{
				float4 positionCS : SV_POSITION;
				float4 clipPosV : TEXCOORD0;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 positionWS : TEXCOORD1;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					float4 shadowCoord : TEXCOORD2;
				#endif
				#ifdef ASE_FOG
					float fogFactor : TEXCOORD3;
				#endif
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				float4 ase_texcoord7 : TEXCOORD7;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

            samplerCUBE _Cubemap;
            sampler2D _DiffuseLightingGradient;
            sampler2D _SpecularLightingGradient;
            CBUFFER_START( UnityPerMaterial )
            float4 _CubemapTInt;
            float4 _DiffuseTint;
            float4 _RimColor;
            float4 _SpecularTint;
            float _Shininess;
            float _Power;
            float _Scale;
            float _Bias;
            float _fbmscale;
            float _Roughness;
            float _NormalGradient;
            float _fbmgain;
            float _fbmlacunarity;
            int _fbmoctaves;
            float _fbmamplitude;
            float _lodSteps;
            float _CubemapInfluince;
            CBUFFER_END


			float3 ASESafeNormalize(float3 inVec)
			{
				float dp3 = max(1.175494351e-38, dot(inVec, inVec));
				return inVec* rsqrt(dp3);
			}
			

			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float3 ase_worldPos = TransformObjectToWorld( (input.positionOS).xyz );
				float2 temp_output_113_0 = (( ase_worldPos + _TimeParameters.x )).xz;
				float2 p111 = temp_output_113_0;
				float noisescale111 = _fbmscale;
				float amplitude111 = _fbmamplitude;
				int octaves111 = _fbmoctaves;
				float lacunarity111 = _fbmlacunarity;
				float gain111 = _fbmgain;
				float localfbm111 = fbm( p111 , noisescale111 , amplitude111 , octaves111 , lacunarity111 , gain111 );
				float3 temp_output_254_0 = ( ( localfbm111 * float3(0,0,1) ) + input.positionOS.xyz );
				
				float3 ase_worldTangent = TransformObjectToWorldDir(input.ase_tangent.xyz);
				output.ase_texcoord5.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(input.normalOS);
				output.ase_texcoord6.xyz = ase_worldNormal;
				float ase_vertexTangentSign = input.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				output.ase_texcoord7.xyz = ase_worldBitangent;
				
				output.ase_texcoord4 = input.positionOS;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord5.w = 0;
				output.ase_texcoord6.w = 0;
				output.ase_texcoord7.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = temp_output_254_0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					input.positionOS.xyz = vertexValue;
				#else
					input.positionOS.xyz += vertexValue;
				#endif

				input.normalOS = input.normalOS;

				VertexPositionInputs vertexInput = GetVertexPositionInputs( input.positionOS.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					output.positionWS = vertexInput.positionWS;
				#endif

				#ifdef ASE_FOG
					output.fogFactor = ComputeFogFactor( vertexInput.positionCS.z );
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					output.shadowCoord = GetShadowCoord( vertexInput );
				#endif

				output.positionCS = vertexInput.positionCS;
				output.clipPosV = vertexInput.positionCS;
				return output;
			}

			PackedVaryings vert ( Attributes input )
			{
				return VertexFunction( input );
			}

			half4 frag ( PackedVaryings input
				#ifdef _WRITE_RENDERING_LAYERS
				, out float4 outRenderingLayers : SV_Target1
				#endif
				 ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( input );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( input );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
					float3 WorldPosition = input.positionWS;
				#endif

				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				float4 ClipPos = input.clipPosV;
				float4 ScreenPos = ComputeScreenPos( input.clipPosV );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = input.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				float3 ase_viewVectorWS = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				float3 ase_viewDirWS = normalize( ase_viewVectorWS );
				float2 temp_output_113_0 = (( WorldPosition + _TimeParameters.x )).xz;
				float temp_output_274_0 = ( _NormalGradient * -1 );
				float2 appendResult275 = (float2(temp_output_274_0 , 0.0));
				float2 p244 = ( temp_output_113_0 + appendResult275 );
				float noisescale244 = _fbmscale;
				float amplitude244 = _fbmamplitude;
				int octaves244 = _fbmoctaves;
				float lacunarity244 = _fbmlacunarity;
				float gain244 = _fbmgain;
				float localfbm244 = fbm( p244 , noisescale244 , amplitude244 , octaves244 , lacunarity244 , gain244 );
				float2 p111 = temp_output_113_0;
				float noisescale111 = _fbmscale;
				float amplitude111 = _fbmamplitude;
				int octaves111 = _fbmoctaves;
				float lacunarity111 = _fbmlacunarity;
				float gain111 = _fbmgain;
				float localfbm111 = fbm( p111 , noisescale111 , amplitude111 , octaves111 , lacunarity111 , gain111 );
				float3 temp_output_254_0 = ( ( localfbm111 * float3(0,0,1) ) + input.ase_texcoord4.xyz );
				float3 displaced_vertex_pos224 = temp_output_254_0;
				float temp_output_226_0 = (displaced_vertex_pos224).z;
				float3 appendResult271 = (float3(1.0 , 0.0 , ( localfbm244 - temp_output_226_0 )));
				float2 appendResult276 = (float2(0.0 , temp_output_274_0));
				float2 p245 = ( temp_output_113_0 + appendResult276 );
				float noisescale245 = _fbmscale;
				float amplitude245 = _fbmamplitude;
				int octaves245 = _fbmoctaves;
				float lacunarity245 = _fbmlacunarity;
				float gain245 = _fbmgain;
				float localfbm245 = fbm( p245 , noisescale245 , amplitude245 , octaves245 , lacunarity245 , gain245 );
				float3 appendResult272 = (float3(0.0 , 1.0 , ( localfbm245 - temp_output_226_0 )));
				float3 normalizeResult264 = normalize( cross( appendResult271 , appendResult272 ) );
				float3 new_normal237 = normalizeResult264;
				float3 ase_worldTangent = input.ase_texcoord5.xyz;
				float3 ase_worldNormal = input.ase_texcoord6.xyz;
				float3 ase_worldBitangent = input.ase_texcoord7.xyz;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal136 = new_normal237;
				float3 worldNormal136 = float3(dot(tanToWorld0,tanNormal136), dot(tanToWorld1,tanNormal136), dot(tanToWorld2,tanNormal136));
				float roughness144 = _Roughness;
				int lodSteps144 = (int)_lodSteps;
				float localPerceptualRoughnessToMipmap144 = PerceptualRoughnessToMipmap( roughness144 , lodSteps144 );
				float3 desaturateInitialColor162 = texCUBElod( _Cubemap, float4( reflect( ( ase_viewDirWS * -1 ) , worldNormal136 ), localPerceptualRoughnessToMipmap144) ).rgb;
				float desaturateDot162 = dot( desaturateInitialColor162, float3( 0.299, 0.587, 0.114 ));
				float3 desaturateVar162 = lerp( desaturateInitialColor162, desaturateDot162.xxx, 1.0 );
				float3 cubemap_lighting199 = saturate( ( desaturateVar162 * _CubemapTInt.rgb ) );
				float3 tanNormal240 = new_normal237;
				float3 worldNormal240 = float3(dot(tanToWorld0,tanNormal240), dot(tanToWorld1,tanNormal240), dot(tanToWorld2,tanNormal240));
				float fresnelNdotV74 = dot( worldNormal240, ase_viewDirWS );
				float fresnelNode74 = ( _Bias + _Scale * pow( 1.0 - fresnelNdotV74, _Power ) );
				float clampResult166 = clamp( fresnelNode74 , 0.0 , 10.0 );
				float3 rim_light176 = ( _RimColor.rgb * clampResult166 );
				float3 tanNormal153 = new_normal237;
				float3 worldNormal153 = float3(dot(tanToWorld0,tanNormal153), dot(tanToWorld1,tanNormal153), dot(tanToWorld2,tanNormal153));
				float dotResult155 = dot( worldNormal153 , _MainLightPosition.xyz );
				float smoothstepResult157 = smoothstep( -1.0 , 1.0 , dotResult155);
				float2 appendResult159 = (float2(smoothstepResult157 , 0.0));
				float3 difusse_lighting170 = ( tex2D( _DiffuseLightingGradient, appendResult159 ).rgb * _DiffuseTint.rgb );
				float3 tanNormal184 = new_normal237;
				float3 worldNormal184 = float3(dot(tanToWorld0,tanNormal184), dot(tanToWorld1,tanNormal184), dot(tanToWorld2,tanNormal184));
				float3 normalizeResult182 = ASESafeNormalize( ( _MainLightPosition.xyz + ase_viewDirWS ) );
				float dotResult183 = dot( worldNormal184 , normalizeResult182 );
				float2 appendResult193 = (float2(pow( saturate( dotResult183 ) , _Shininess ) , 0.0));
				float3 specular188 = ( tex2D( _SpecularLightingGradient, appendResult193 ).rgb * _SpecularTint.rgb );
				float3 blendOpSrc161 = cubemap_lighting199;
				float3 blendOpDest161 = saturate( ( rim_light176 + difusse_lighting170 + specular188 ) );
				float3 lerpBlendMode161 = lerp(blendOpDest161,(( blendOpDest161 > 0.5 ) ? ( 1.0 - 2.0 * ( 1.0 - blendOpDest161 ) * ( 1.0 - blendOpSrc161 ) ) : ( 2.0 * blendOpDest161 * blendOpSrc161 ) ),_CubemapInfluince);
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( saturate( lerpBlendMode161 ));
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#if defined(_DBUFFER)
					ApplyDecalToBaseColor(input.positionCS, Color);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODFadeCrossFade( input.positionCS );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, input.fogFactor );
				#endif

				#ifdef _WRITE_RENDERING_LAYERS
					uint renderingLayers = GetMeshRenderingLayer();
					outRenderingLayers = float4( EncodeMeshRenderingLayer( renderingLayers ), 0, 0, 0 );
				#endif

				return half4( Color, Alpha );
			}
			ENDHLSL
		}

	
	}
	
	CustomEditor "UnityEditor.ShaderGraphUnlitGUI"
	FallBack "Hidden/Shader Graph/FallbackError"
	
	Fallback Off
}
/*ASEBEGIN
Version=19701
Node;AmplifyShaderEditor.WorldPosInputsNode;112;-1232,-224;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleTimeNode;278;-1072,-32;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;277;-944,-224;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;113;-832,-224;Inherit;False;True;False;True;True;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;125;-320,-192;Inherit;False;Property;_fbmamplitude;fbm amplitude;17;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;116;-304,-256;Inherit;False;Property;_fbmscale;fbm scale;18;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;120;-320,-48;Inherit;False;Property;_fbmlacunarity;fbm lacunarity;15;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;121;-288,32;Inherit;False;Property;_fbmgain;fbm gain;16;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;114;-336,-128;Inherit;False;Property;_fbmoctaves;fbm octaves;14;1;[Header];Create;True;1;FBM Settings;0;0;False;0;False;1;1;False;0;1;INT;0
Node;AmplifyShaderEditor.CustomExpressionNode;111;-96,-224;Inherit;False; ;1;File;6;True;p;FLOAT2;0,0;In;;Inherit;False;True;noisescale;FLOAT;0;In;;Inherit;False;True;amplitude;FLOAT;0;In;;Inherit;False;True;octaves;INT;1;In;;Inherit;False;True;lacunarity;FLOAT;1;In;;Inherit;False;True;gain;FLOAT;1;In;;Inherit;False;fbm;False;False;0;ac7e0432fb5fc2890bb112fdc36b1e60;False;6;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;INT;1;False;4;FLOAT;1;False;5;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;211;544,-144;Inherit;False;Constant;_Vector0;Vector 0;20;0;Create;True;0;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;202;800,-224;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;253;1088,-144;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;273;-1072,208;Inherit;False;Property;_NormalGradient;Normal Gradient;19;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;254;1488,-224;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ScaleNode;274;-848,208;Inherit;False;-1;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;275;-672,144;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;276;-688,288;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;224;1728,-224;Inherit;False;displaced vertex pos;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;225;432,80;Inherit;False;224;displaced vertex pos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;215;-448,128;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;216;-448,320;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CustomExpressionNode;244;-112,128;Inherit;False; ;1;File;6;True;p;FLOAT2;0,0;In;;Inherit;False;True;noisescale;FLOAT;0;In;;Inherit;False;True;amplitude;FLOAT;0;In;;Inherit;False;True;octaves;INT;1;In;;Inherit;False;True;lacunarity;FLOAT;1;In;;Inherit;False;True;gain;FLOAT;1;In;;Inherit;False;fbm;False;False;0;ac7e0432fb5fc2890bb112fdc36b1e60;False;6;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;INT;1;False;4;FLOAT;1;False;5;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;245;-112,320;Inherit;False; ;1;File;6;True;p;FLOAT2;0,0;In;;Inherit;False;True;noisescale;FLOAT;0;In;;Inherit;False;True;amplitude;FLOAT;0;In;;Inherit;False;True;octaves;INT;1;In;;Inherit;False;True;lacunarity;FLOAT;1;In;;Inherit;False;True;gain;FLOAT;1;In;;Inherit;False;fbm;False;False;0;ac7e0432fb5fc2890bb112fdc36b1e60;False;6;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;INT;1;False;4;FLOAT;1;False;5;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;226;704,80;Inherit;False;False;False;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;227;928,192;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;228;928,336;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;272;1168,288;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;271;1168,144;Inherit;False;FLOAT3;4;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CrossProductOpNode;231;1392,208;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;195;-5664,-512;Inherit;False;2980;586.8;;15;181;180;183;187;192;186;193;194;190;189;188;179;182;184;241;Specular;0,1,0.9353578,1;0;0
Node;AmplifyShaderEditor.NormalizeNode;264;1584,208;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;181;-5552,-96;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;179;-5616,-256;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RegisterLocalVarNode;237;1808,208;Inherit;False;new normal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;180;-5296,-256;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;241;-5264,-400;Inherit;False;237;new normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;171;-4912,-1616;Inherit;False;2164;410.8;;9;153;154;155;157;159;158;169;168;170;Diffuse Lighting;1,0.5743952,0.3039398,1;0;0
Node;AmplifyShaderEditor.NormalizeNode;182;-5120,-256;Inherit;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldNormalVector;184;-4944,-400;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;238;-5136,-1504;Inherit;False;237;new normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;201;-5584,208;Inherit;False;2964;546.95;;24;134;145;136;137;138;135;144;80;82;162;164;163;198;199;58;59;60;61;62;63;64;65;66;242;Cubemap;0.6532192,0.314175,0.9594928,1;0;0
Node;AmplifyShaderEditor.WorldNormalVector;153;-4800,-1536;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;154;-4864,-1376;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DotProductOpNode;183;-4736,-288;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;177;-4400,-1136;Inherit;False;1636;514.95;;9;75;76;77;74;166;172;173;56;176;Rim Lighting;0.5269378,0.5269378,0.5269378,1;0;0
Node;AmplifyShaderEditor.DotProductOpNode;155;-4560,-1536;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;192;-4528,-288;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;187;-4320,-384;Inherit;False;Property;_Shininess;Shininess;2;1;[Header];Create;True;1;Specular;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;134;-5536,416;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.GetLocalVarNode;242;-5344,560;Inherit;False;237;new normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;239;-4672,-976;Inherit;False;237;new normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SmoothstepOpNode;157;-4320,-1536;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;-1;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;76;-4352,-816;Inherit;False;Property;_Scale;Scale;6;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;77;-4352,-736;Inherit;False;Property;_Power;Power;7;0;Create;True;0;0;0;False;0;False;5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.PowerNode;186;-4144,-288;Inherit;False;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;75;-4352,-896;Inherit;False;Property;_Bias;Bias;5;1;[Header];Create;True;1;Rim Light Settings;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;145;-4656,640;Inherit;False;Property;_lodSteps;lodSteps;11;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;136;-5152,496;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ScaleNode;137;-5312,416;Inherit;False;-1;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;138;-4784,544;Inherit;False;Property;_Roughness;Roughness;10;0;Create;True;0;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;240;-4448,-992;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.FresnelNode;74;-4096,-944;Inherit;False;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;5;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;159;-3968,-1536;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;193;-3920,-288;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.ReflectOpNode;135;-4928,416;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CustomExpressionNode;144;-4464,544;Inherit;False; ;1;File;2;True;roughness;FLOAT;0;In;;Inherit;False;True;lodSteps;INT;0;In;;Inherit;False;PerceptualRoughnessToMipmap;False;False;0;ac7e0432fb5fc2890bb112fdc36b1e60;False;2;0;FLOAT;0;False;1;INT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;80;-4464,256;Inherit;True;Property;_Cubemap;Cubemap;13;1;[SingleLineTexture];Create;True;0;0;0;False;0;False;None;None;False;white;LockedToCube;Cube;-1;0;2;SAMPLERCUBE;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.ClampOpNode;166;-3792,-944;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;10;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;172;-3616,-1088;Inherit;False;Property;_RimColor;Rim Color;8;0;Create;True;0;0;0;False;0;False;0.4412928,0.3859454,0.3546536,0;0,0,0,0;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.ColorNode;190;-3392,-448;Inherit;False;Property;_SpecularTint;Specular Tint;3;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;0,0,0,0;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SamplerNode;194;-3712,-320;Inherit;True;Property;_SpecularLightingGradient;Specular Lighting Gradient;4;1;[SingleLineTexture];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SamplerNode;158;-3760,-1552;Inherit;True;Property;_DiffuseLightingGradient;Diffuse Lighting Gradient;1;1;[SingleLineTexture];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.ColorNode;169;-3440,-1456;Inherit;False;Property;_DiffuseTint;Diffuse Tint;0;2;[HDR];[Header];Create;True;1;Diffuse;0;0;False;0;False;1,1,1,0;0,0,0,0;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SamplerNode;82;-4144,400;Inherit;True;Property;_TextureSample0;Texture Sample 0;7;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;MipLevel;Cube;8;0;SAMPLERCUBE;;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;168;-3216,-1536;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;173;-3264,-976;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;189;-3136,-288;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DesaturateOpNode;162;-3760,432;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;164;-3568,512;Inherit;False;Property;_CubemapTInt;Cubemap TInt;12;0;Create;True;0;0;0;False;0;False;1,1,1,0;0,0,0,0;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.RegisterLocalVarNode;170;-2992,-1536;Inherit;False;difusse lighting;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;176;-3008,-976;Inherit;False;rim light;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;188;-2928,-288;Inherit;False;specular;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;163;-3328,432;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;174;-256,-944;Inherit;False;170;difusse lighting;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;178;-272,-1168;Inherit;False;176;rim light;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;191;-240,-768;Inherit;False;188;specular;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;198;-3072,432;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;175;32,-1072;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;199;-2864,432;Inherit;False;cubemap lighting;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;197;208,-1072;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;200;352,-1240;Inherit;False;199;cubemap lighting;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;148;272,-928;Inherit;False;Property;_CubemapInfluince;Cubemap Influince;9;1;[Header];Create;True;1;Cubemap;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.BlendOpsNode;161;592,-1088;Inherit;False;Overlay;True;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;56;-3664,-960;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;18;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;58;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;18;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;59;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;18;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;60;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;18;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;61;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;18;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;62;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;18;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;63;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;18;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;64;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;18;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;65;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;18;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;66;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;18;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;MotionVectors;0;10;MotionVectors;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;False;False;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=MotionVectors;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;57;1760,-720;Float;False;True;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;14;TestShader;60b6e374d24fe6feda8ee4144ab035b5;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;5;glcore;gles;gles3;metal;vulkan;0;False;True;1;1;False;;0;False;;1;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForwardOnly;False;False;0;;0;0;Standard;16;Surface;0;638689171320863090;  Blend;0;0;Two Sided;1;0;Forward Only;0;0;Alpha Clipping;0;638689166859858470;  Use Shadow Threshold;0;0;Cast Shadows;0;638689165561972940;Receive Shadows;0;638689165555580120;Motion Vectors;0;638689165527439720;  Add Precomputed Velocity;0;0;GPU Instancing;0;638689165587051310;LOD CrossFade;0;638689166818739890;Built-in Fog;0;638689166767420580;Meta Pass;0;0;Extra Pre Pass;0;0;Vertex Position,InvertActionOnDeselection;0;638690069308959490;0;11;False;True;False;False;False;False;False;False;False;False;False;False;;False;0
WireConnection;277;0;112;0
WireConnection;277;1;278;0
WireConnection;113;0;277;0
WireConnection;111;0;113;0
WireConnection;111;1;116;0
WireConnection;111;2;125;0
WireConnection;111;3;114;0
WireConnection;111;4;120;0
WireConnection;111;5;121;0
WireConnection;202;0;111;0
WireConnection;202;1;211;0
WireConnection;254;0;202;0
WireConnection;254;1;253;0
WireConnection;274;0;273;0
WireConnection;275;0;274;0
WireConnection;276;1;274;0
WireConnection;224;0;254;0
WireConnection;215;0;113;0
WireConnection;215;1;275;0
WireConnection;216;0;113;0
WireConnection;216;1;276;0
WireConnection;244;0;215;0
WireConnection;244;1;116;0
WireConnection;244;2;125;0
WireConnection;244;3;114;0
WireConnection;244;4;120;0
WireConnection;244;5;121;0
WireConnection;245;0;216;0
WireConnection;245;1;116;0
WireConnection;245;2;125;0
WireConnection;245;3;114;0
WireConnection;245;4;120;0
WireConnection;245;5;121;0
WireConnection;226;0;225;0
WireConnection;227;0;244;0
WireConnection;227;1;226;0
WireConnection;228;0;245;0
WireConnection;228;1;226;0
WireConnection;272;2;228;0
WireConnection;271;2;227;0
WireConnection;231;0;271;0
WireConnection;231;1;272;0
WireConnection;264;0;231;0
WireConnection;237;0;264;0
WireConnection;180;0;179;0
WireConnection;180;1;181;0
WireConnection;182;0;180;0
WireConnection;184;0;241;0
WireConnection;153;0;238;0
WireConnection;183;0;184;0
WireConnection;183;1;182;0
WireConnection;155;0;153;0
WireConnection;155;1;154;0
WireConnection;192;0;183;0
WireConnection;157;0;155;0
WireConnection;186;0;192;0
WireConnection;186;1;187;0
WireConnection;136;0;242;0
WireConnection;137;0;134;0
WireConnection;240;0;239;0
WireConnection;74;0;240;0
WireConnection;74;1;75;0
WireConnection;74;2;76;0
WireConnection;74;3;77;0
WireConnection;159;0;157;0
WireConnection;193;0;186;0
WireConnection;135;0;137;0
WireConnection;135;1;136;0
WireConnection;144;0;138;0
WireConnection;144;1;145;0
WireConnection;166;0;74;0
WireConnection;194;1;193;0
WireConnection;158;1;159;0
WireConnection;82;0;80;0
WireConnection;82;1;135;0
WireConnection;82;2;144;0
WireConnection;168;0;158;5
WireConnection;168;1;169;5
WireConnection;173;0;172;5
WireConnection;173;1;166;0
WireConnection;189;0;194;5
WireConnection;189;1;190;5
WireConnection;162;0;82;5
WireConnection;170;0;168;0
WireConnection;176;0;173;0
WireConnection;188;0;189;0
WireConnection;163;0;162;0
WireConnection;163;1;164;5
WireConnection;198;0;163;0
WireConnection;175;0;178;0
WireConnection;175;1;174;0
WireConnection;175;2;191;0
WireConnection;199;0;198;0
WireConnection;197;0;175;0
WireConnection;161;0;200;0
WireConnection;161;1;197;0
WireConnection;161;2;148;0
WireConnection;57;2;161;0
WireConnection;57;5;254;0
ASEEND*/
//CHKSM=CCF52DA7DF7D8B42B43ED92354FAF98102C9401E