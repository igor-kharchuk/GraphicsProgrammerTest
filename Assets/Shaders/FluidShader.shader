// Made with Amplify Shader Editor v1.9.7.1
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "FluidShader"
{
	Properties
	{
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
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
		// ensure rendering platforms toggle list is visible

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
				float4 ase_texcoord : TEXCOORD0;
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
				float4 ase_texcoord8 : TEXCOORD8;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

            sampler2D _PaintTexture;
            samplerCUBE _Cubemap;
            sampler2D _DiffuseLightingGradient;
            CBUFFER_START( UnityPerMaterial )
            float4 _CubemapTInt;
            float4 _DiffuseTint;
            float4 _GlosinessColor;
            float _NoiseScale;
            float _NoiseAmplitude;
            float _Roughness;
            float _lodSteps;
            float _CubemapDesaturation;
            float _CubemapFresnel;
            float _CubemapInfluince;
            float _Smoothness;
            CBUFFER_END


			float3 mod3D289( float3 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 mod3D289( float4 x ) { return x - floor( x / 289.0 ) * 289.0; }
			float4 permute( float4 x ) { return mod3D289( ( x * 34.0 + 1.0 ) * x ); }
			float4 taylorInvSqrt( float4 r ) { return 1.79284291400159 - r * 0.85373472095314; }
			float snoise( float3 v )
			{
				const float2 C = float2( 1.0 / 6.0, 1.0 / 3.0 );
				float3 i = floor( v + dot( v, C.yyy ) );
				float3 x0 = v - i + dot( i, C.xxx );
				float3 g = step( x0.yzx, x0.xyz );
				float3 l = 1.0 - g;
				float3 i1 = min( g.xyz, l.zxy );
				float3 i2 = max( g.xyz, l.zxy );
				float3 x1 = x0 - i1 + C.xxx;
				float3 x2 = x0 - i2 + C.yyy;
				float3 x3 = x0 - 0.5;
				i = mod3D289( i);
				float4 p = permute( permute( permute( i.z + float4( 0.0, i1.z, i2.z, 1.0 ) ) + i.y + float4( 0.0, i1.y, i2.y, 1.0 ) ) + i.x + float4( 0.0, i1.x, i2.x, 1.0 ) );
				float4 j = p - 49.0 * floor( p / 49.0 );  // mod(p,7*7)
				float4 x_ = floor( j / 7.0 );
				float4 y_ = floor( j - 7.0 * x_ );  // mod(j,N)
				float4 x = ( x_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 y = ( y_ * 2.0 + 0.5 ) / 7.0 - 1.0;
				float4 h = 1.0 - abs( x ) - abs( y );
				float4 b0 = float4( x.xy, y.xy );
				float4 b1 = float4( x.zw, y.zw );
				float4 s0 = floor( b0 ) * 2.0 + 1.0;
				float4 s1 = floor( b1 ) * 2.0 + 1.0;
				float4 sh = -step( h, 0.0 );
				float4 a0 = b0.xzyw + s0.xzyw * sh.xxyy;
				float4 a1 = b1.xzyw + s1.xzyw * sh.zzww;
				float3 g0 = float3( a0.xy, h.x );
				float3 g1 = float3( a0.zw, h.y );
				float3 g2 = float3( a1.xy, h.z );
				float3 g3 = float3( a1.zw, h.w );
				float4 norm = taylorInvSqrt( float4( dot( g0, g0 ), dot( g1, g1 ), dot( g2, g2 ), dot( g3, g3 ) ) );
				g0 *= norm.x;
				g1 *= norm.y;
				g2 *= norm.z;
				g3 *= norm.w;
				float4 m = max( 0.6 - float4( dot( x0, x0 ), dot( x1, x1 ), dot( x2, x2 ), dot( x3, x3 ) ), 0.0 );
				m = m* m;
				m = m* m;
				float4 px = float4( dot( x0, g0 ), dot( x1, g1 ), dot( x2, g2 ), dot( x3, g3 ) );
				return 42.0 * dot( m, px);
			}
			

			PackedVaryings VertexFunction( Attributes input  )
			{
				PackedVaryings output = (PackedVaryings)0;
				UNITY_SETUP_INSTANCE_ID(input);
				UNITY_TRANSFER_INSTANCE_ID(input, output);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);

				float mulTime9_g22 = _TimeParameters.x * 0.1;
				float3 appendResult8_g22 = (float3(input.ase_texcoord.xy , mulTime9_g22));
				float simplePerlin3D4_g22 = snoise( appendResult8_g22*_NoiseScale );
				float4 tex2DNode2_g21 = tex2Dlod( _PaintTexture, float4( input.ase_texcoord.xy, 0, 0.0) );
				float3 displaced_vertex_pos224 = ( ( ( ( ( simplePerlin3D4_g22 * _NoiseAmplitude ) + ( ( ( tex2DNode2_g21.r + 0.5 ) * ( 1.0 - ( tex2DNode2_g21.g + 0.5 ) ) ) - 0.5 ) ) * 2.0 ) * float3(0,0,1) ) + input.positionOS.xyz );
				
				float3 ase_worldTangent = TransformObjectToWorldDir(input.ase_tangent.xyz);
				output.ase_texcoord6.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(input.normalOS);
				output.ase_texcoord7.xyz = ase_worldNormal;
				float ase_vertexTangentSign = input.ase_tangent.w * ( unity_WorldTransformParams.w >= 0.0 ? 1.0 : -1.0 );
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				output.ase_texcoord8.xyz = ase_worldBitangent;
				
				output.ase_texcoord4.xy = input.ase_texcoord.xy;
				output.ase_texcoord5 = input.positionOS;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				output.ase_texcoord4.zw = 0;
				output.ase_texcoord6.w = 0;
				output.ase_texcoord7.w = 0;
				output.ase_texcoord8.w = 0;

				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = input.positionOS.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif

				float3 vertexValue = displaced_vertex_pos224;

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

				samplerCUBE Cubemap376 = _Cubemap;
				float Roughness376 = _Roughness;
				float LodSteps376 = _lodSteps;
				float3 ase_viewVectorWS = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				float3 ase_viewDirWS = normalize( ase_viewVectorWS );
				float3 ViewDirection376 = ase_viewDirWS;
				float2 temp_output_422_0 = ( float2( 0.01,0 ) + input.ase_texcoord4.xy );
				float mulTime9_g27 = _TimeParameters.x * 0.1;
				float3 appendResult8_g27 = (float3(temp_output_422_0 , mulTime9_g27));
				float simplePerlin3D4_g27 = snoise( appendResult8_g27*_NoiseScale );
				float4 tex2DNode2_g25 = tex2D( _PaintTexture, temp_output_422_0 );
				float mulTime9_g22 = _TimeParameters.x * 0.1;
				float3 appendResult8_g22 = (float3(input.ase_texcoord4.xy , mulTime9_g22));
				float simplePerlin3D4_g22 = snoise( appendResult8_g22*_NoiseScale );
				float4 tex2DNode2_g21 = tex2D( _PaintTexture, input.ase_texcoord4.xy );
				float3 displaced_vertex_pos224 = ( ( ( ( ( simplePerlin3D4_g22 * _NoiseAmplitude ) + ( ( ( tex2DNode2_g21.r + 0.5 ) * ( 1.0 - ( tex2DNode2_g21.g + 0.5 ) ) ) - 0.5 ) ) * 2.0 ) * float3(0,0,1) ) + input.ase_texcoord5.xyz );
				float temp_output_333_0 = (displaced_vertex_pos224).z;
				float3 appendResult336 = (float3(1.0 , 0.0 , ( ( ( ( simplePerlin3D4_g27 * _NoiseAmplitude ) + ( ( ( tex2DNode2_g25.r + 0.5 ) * ( 1.0 - ( tex2DNode2_g25.g + 0.5 ) ) ) - 0.5 ) ) * 2.0 ) - temp_output_333_0 )));
				float2 temp_output_424_0 = ( float2( 0,0.01 ) + input.ase_texcoord4.xy );
				float mulTime9_g28 = _TimeParameters.x * 0.1;
				float3 appendResult8_g28 = (float3(temp_output_424_0 , mulTime9_g28));
				float simplePerlin3D4_g28 = snoise( appendResult8_g28*_NoiseScale );
				float4 tex2DNode2_g26 = tex2D( _PaintTexture, temp_output_424_0 );
				float3 appendResult335 = (float3(0.0 , 1.0 , ( ( ( ( simplePerlin3D4_g28 * _NoiseAmplitude ) + ( ( ( tex2DNode2_g26.r + 0.5 ) * ( 1.0 - ( tex2DNode2_g26.g + 0.5 ) ) ) - 0.5 ) ) * 2.0 ) - temp_output_333_0 )));
				float3 normalizeResult338 = normalize( cross( appendResult336 , appendResult335 ) );
				float3 new_normal237 = normalizeResult338;
				float3 ase_worldTangent = input.ase_texcoord6.xyz;
				float3 ase_worldNormal = input.ase_texcoord7.xyz;
				float3 ase_worldBitangent = input.ase_texcoord8.xyz;
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal378 = new_normal237;
				float3 worldNormal378 = float3(dot(tanToWorld0,tanNormal378), dot(tanToWorld1,tanNormal378), dot(tanToWorld2,tanNormal378));
				float3 WNormal376 = worldNormal378;
				float3 localSpecularEnvironment376 = SpecularEnvironment( Cubemap376 , Roughness376 , LodSteps376 , ViewDirection376 , WNormal376 );
				float3 desaturateInitialColor382 = localSpecularEnvironment376;
				float desaturateDot382 = dot( desaturateInitialColor382, float3( 0.299, 0.587, 0.114 ));
				float3 desaturateVar382 = lerp( desaturateInitialColor382, desaturateDot382.xxx, _CubemapDesaturation );
				float fresnelNdotV385 = dot( new_normal237, ase_viewDirWS );
				float fresnelNode385 = ( ( 1.0 - _CubemapFresnel ) + 1.0 * pow( 1.0 - fresnelNdotV385, 1.46 ) );
				sampler2D DiffuseGradientTex371 = _DiffuseLightingGradient;
				float3 DiffuseTint371 = _DiffuseTint.rgb;
				float3 GlosinessColor371 = _GlosinessColor.rgb;
				float Smoothness371 = _Smoothness;
				float3 tanNormal373 = new_normal237;
				float3 worldNormal373 = float3(dot(tanToWorld0,tanNormal373), dot(tanToWorld1,tanNormal373), dot(tanToWorld2,tanNormal373));
				float3 WorldNormal371 = worldNormal373;
				float3 WSLightDirection371 = _MainLightPosition.xyz;
				float3 ViewDirection371 = ase_viewDirWS;
				float3 localCalculateLighting371 = CalculateLighting( DiffuseGradientTex371 , DiffuseTint371 , GlosinessColor371 , Smoothness371 , WorldNormal371 , WSLightDirection371 , ViewDirection371 );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( ( ( ( desaturateVar382 * _CubemapTInt.rgb ) * saturate( fresnelNode385 ) ) * _CubemapInfluince ) + localCalculateLighting371 );
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
Node;AmplifyShaderEditor.CommentaryNode;490;-1872,-48;Inherit;False;4132;1298.85;;39;448;458;294;401;457;432;489;483;442;420;413;439;414;411;412;224;423;422;424;438;440;333;331;334;332;430;436;441;456;425;460;459;336;338;237;337;335;484;485;Paint and Noise Displacement;1,0.6276534,0.2859483,1;0;0
Node;AmplifyShaderEditor.RangedFloatNode;448;-1536,384;Inherit;False;Property;_NoiseScale;NoiseScale;18;1;[Header];Create;True;1;Noise Settings;0;0;False;0;False;3;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;458;-944,400;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;294;-1824,480;Inherit;True;Global;_PaintTexture;_PaintTexture;17;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.TexCoordVertexDataNode;401;-928,144;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WireNode;457;-656,336;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;432;-1504,96;Inherit;False;1;0;SAMPLER2D;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.RangedFloatNode;489;-880,832;Inherit;False;Property;_NoiseAmplitude;Noise Amplitude;19;0;Create;True;0;0;0;False;0;False;0.2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;483;-624,0;Inherit;False;UnpackPaintMask;-1;;21;bbbb801d2064e7b8ea9b3d172aef4446;0;2;3;SAMPLER2D;0;False;1;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;502;-640,144;Inherit;False;GetNoise;-1;;22;69c321155b7140acba5e38f500e431b2;0;3;11;FLOAT;0.2;False;5;FLOAT2;0,0;False;6;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;420;-288,144;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;442;112,752;Inherit;False;Constant;_Float1;Float 0;21;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;413;480,240;Inherit;False;Constant;_Vector2;Vector 1;20;0;Create;True;0;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;439;272,144;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;414;704,144;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;411;896,240;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;423;-1152,608;Inherit;False;Constant;_DDX1;DDX;20;0;Create;True;0;0;0;False;0;False;0.01,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TexCoordVertexDataNode;438;-1120,864;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.Vector2Node;425;-1152,1088;Inherit;False;Constant;_DDY1;DDY;20;0;Create;True;0;0;0;False;0;False;0,0.01;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SimpleAddOpNode;412;1104,144;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;422;-848,608;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;424;-880,1088;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.WireNode;456;-1472,896;Inherit;False;1;0;SAMPLER2D;;False;1;SAMPLER2D;0
Node;AmplifyShaderEditor.WireNode;460;-1328,1120;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;459;-1264,672;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;224;1280,144;Inherit;False;displaced_vertex_pos;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FunctionNode;484;-624,464;Inherit;False;UnpackPaintMask;-1;;25;bbbb801d2064e7b8ea9b3d172aef4446;0;2;3;SAMPLER2D;0;False;1;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;485;-592,944;Inherit;False;UnpackPaintMask;-1;;26;bbbb801d2064e7b8ea9b3d172aef4446;0;2;3;SAMPLER2D;0;False;1;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;503;-656,608;Inherit;False;GetNoise;-1;;27;69c321155b7140acba5e38f500e431b2;0;3;11;FLOAT;0.2;False;5;FLOAT2;0,0;False;6;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;504;-624,1088;Inherit;False;GetNoise;-1;;28;69c321155b7140acba5e38f500e431b2;0;3;11;FLOAT;0.2;False;5;FLOAT2;0,0;False;6;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;430;-288,608;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;436;-256,1088;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;332;512,832;Inherit;False;224;displaced_vertex_pos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;440;288,608;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;333;784,832;Inherit;False;False;False;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;441;288,1088;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;331;1008,608;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;334;992,1088;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;336;1280,560;Inherit;False;FLOAT3;4;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;335;1264,1040;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CrossProductOpNode;337;1536,560;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;338;1744,560;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CommentaryNode;492;-978,-2262.83;Inherit;False;3524;959.6301;;19;376;164;392;382;383;384;385;391;394;393;389;148;138;145;377;395;80;378;443;Specular Environment (Cubemap);0.339517,0.6818106,1,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;237;2016,560;Inherit;False;new normal;-1;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;395;-928,-1488;Inherit;False;237;new normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;393;704,-2096;Inherit;False;Property;_CubemapFresnel;Cubemap Fresnel;10;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;138;-816,-1808;Inherit;False;Property;_Roughness;Roughness;5;0;Create;True;0;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;145;-720,-1728;Inherit;False;Property;_lodSteps;lodSteps;6;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;377;-752,-1648;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TexturePropertyNode;80;-768,-2032;Inherit;True;Property;_Cubemap;Cubemap;8;1;[SingleLineTexture];Create;True;0;0;0;False;0;False;None;None;False;white;LockedToCube;Cube;-1;0;2;SAMPLERCUBE;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.WorldNormalVector;378;-736,-1488;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.CommentaryNode;491;-2418,-1842;Inherit;False;1172;1258.8;;9;169;190;375;374;373;187;372;371;238;Base Lighting;0.549215,0.4527188,1,1;0;0
Node;AmplifyShaderEditor.CustomExpressionNode;376;-320,-1824;Inherit;False; ;3;File;5;True;Cubemap;SAMPLERCUBE;;In;;Inherit;False;True;Roughness;FLOAT;0;In;;Inherit;False;True;LodSteps;FLOAT;0;In;;Inherit;False;True;ViewDirection;FLOAT3;0,0,0;In;;Inherit;False;True;WNormal;FLOAT3;0,0,0;In;;Inherit;False;SpecularEnvironment;False;False;0;ac7e0432fb5fc2890bb112fdc36b1e60;False;5;0;SAMPLERCUBE;;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT3;0,0,0;False;4;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;392;-96,-1744;Inherit;False;Property;_CubemapDesaturation;CubemapDesaturation;9;0;Create;True;0;0;0;False;0;False;0.58;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;394;992,-2080;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;443;864.4808,-2212.83;Inherit;False;237;new normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;238;-2368,-1104;Inherit;False;237;new normal;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;164;128,-2016;Inherit;False;Property;_CubemapTInt;Cubemap TInt;7;0;Create;True;0;0;0;False;0;False;1,1,1,0;0,0,0,0;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.DesaturateOpNode;382;160,-1824;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;1;FLOAT3;0
Node;AmplifyShaderEditor.FresnelNode;385;1168,-2112;Inherit;True;Standard;WorldNormal;ViewDir;False;False;5;0;FLOAT3;0,0,1;False;4;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT;1;False;3;FLOAT;1.46;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;169;-2000,-1584;Inherit;False;Property;_DiffuseTint;Diffuse Tint;0;2;[HDR];[Header];Create;True;1;Diffuse;0;0;False;0;False;1,1,1,0;0,0,0,0;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.ColorNode;190;-2000,-1360;Inherit;False;Property;_GlosinessColor;Glosiness Color;3;1;[HDR];Create;True;0;0;0;False;0;False;1,1,1,0;0,0,0,0;True;True;0;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;375;-2000,-768;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;374;-2048,-928;Inherit;False;False;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldNormalVector;373;-1984,-1072;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;187;-1984,-1152;Inherit;False;Property;_Smoothness;Smoothness;2;1;[Header];Create;True;1;Specular;0;0;False;0;False;0.5;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.TexturePropertyNode;372;-2032,-1792;Inherit;True;Property;_DiffuseLightingGradient;Diffuse Lighting Gradient;1;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;383;416,-1824;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;391;1568,-2112;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;384;1728,-1840;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;148;2048,-1920;Inherit;False;Property;_CubemapInfluince;Cubemap Influince;4;1;[Header];Create;True;1;Cubemap;0;0;False;0;False;1;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;371;-1552,-1248;Inherit;False; ;3;File;7;True;DiffuseGradientTex;SAMPLER2D;;In;;Inherit;False;True;DiffuseTint;FLOAT3;0,0,0;In;;Inherit;False;True;GlosinessColor;FLOAT3;0,0,0;In;;Inherit;False;True;Smoothness;FLOAT;0;In;;Inherit;False;True;WorldNormal;FLOAT3;0,0,0;In;;Inherit;False;True;WSLightDirection;FLOAT3;0,0,0;In;;Inherit;False;True;ViewDirection;FLOAT3;0,0,0;In;;Inherit;False;CalculateLighting;False;False;0;ac7e0432fb5fc2890bb112fdc36b1e60;False;7;0;SAMPLER2D;;False;1;FLOAT3;0,0,0;False;2;FLOAT3;0,0,0;False;3;FLOAT;0;False;4;FLOAT3;0,0,0;False;5;FLOAT3;0,0,0;False;6;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WireNode;388;96,-1200;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;389;2368,-1840;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;386;2736,-1248;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.WorldPosInputsNode;112;-3056,2864;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleTimeNode;278;-2896,3056;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;273;-2896,3296;Inherit;False;Property;_NormalGradient;Normal Gradient;16;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;277;-2768,2864;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;116;-2128,2832;Inherit;False;Property;_fbmscale;fbm scale;15;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ComponentMaskNode;113;-2656,2864;Inherit;False;True;False;True;True;1;0;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;125;-2144,2896;Inherit;False;Property;_fbmamplitude;fbm amplitude;14;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;120;-2144,3040;Inherit;False;Property;_fbmlacunarity;fbm lacunarity;12;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;121;-2112,3120;Inherit;False;Property;_fbmgain;fbm gain;13;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.IntNode;114;-2160,2960;Inherit;False;Property;_fbmoctaves;fbm octaves;11;1;[Header];Create;True;1;FBM Settings;0;0;False;0;False;1;1;False;0;1;INT;0
Node;AmplifyShaderEditor.CustomExpressionNode;111;-1920,2864;Inherit;False; ;1;File;6;True;p;FLOAT2;0,0;In;;Inherit;False;True;noisescale;FLOAT;0;In;;Inherit;False;True;amplitude;FLOAT;0;In;;Inherit;False;True;octaves;INT;1;In;;Inherit;False;True;lacunarity;FLOAT;1;In;;Inherit;False;True;gain;FLOAT;1;In;;Inherit;False;fbm;False;False;0;ac7e0432fb5fc2890bb112fdc36b1e60;False;6;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;INT;1;False;4;FLOAT;1;False;5;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;397;-1520,2832;Inherit;False;noise;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector3Node;211;-1280,2944;Inherit;False;Constant;_Vector0;Vector 0;20;0;Create;True;0;0;0;False;0;False;0,0,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;202;-1024,2864;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;253;-736,2944;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;254;-336,2864;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ScaleNode;274;-2672,3296;Inherit;False;-1;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;275;-2496,3232;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DynamicAppendNode;276;-2512,3376;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;215;-2272,3216;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;216;-2272,3408;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.CustomExpressionNode;244;-1936,3216;Inherit;False; ;1;File;6;True;p;FLOAT2;0,0;In;;Inherit;False;True;noisescale;FLOAT;0;In;;Inherit;False;True;amplitude;FLOAT;0;In;;Inherit;False;True;octaves;INT;1;In;;Inherit;False;True;lacunarity;FLOAT;1;In;;Inherit;False;True;gain;FLOAT;1;In;;Inherit;False;fbm;False;False;0;ac7e0432fb5fc2890bb112fdc36b1e60;False;6;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;INT;1;False;4;FLOAT;1;False;5;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;245;-1936,3408;Inherit;False; ;1;File;6;True;p;FLOAT2;0,0;In;;Inherit;False;True;noisescale;FLOAT;0;In;;Inherit;False;True;amplitude;FLOAT;0;In;;Inherit;False;True;octaves;INT;1;In;;Inherit;False;True;lacunarity;FLOAT;1;In;;Inherit;False;True;gain;FLOAT;1;In;;Inherit;False;fbm;False;False;0;ac7e0432fb5fc2890bb112fdc36b1e60;False;6;0;FLOAT2;0,0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;INT;1;False;4;FLOAT;1;False;5;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;227;-896,3280;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;228;-896,3424;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;225;-1392,3168;Inherit;False;224;displaced_vertex_pos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ComponentMaskNode;226;-1120,3168;Inherit;False;False;False;True;False;1;0;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;272;-656,3376;Inherit;False;FLOAT3;4;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.DynamicAppendNode;271;-656,3232;Inherit;False;FLOAT3;4;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.CrossProductOpNode;231;-432,3296;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;264;-240,3296;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.GetLocalVarNode;415;3056,-1120;Inherit;False;224;displaced_vertex_pos;1;0;OBJECT;;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;315;1744,-656;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;17;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;0;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;317;1744,-656;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;17;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=ShadowCaster;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;318;1744,-656;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;17;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;True;False;False;False;False;0;False;;False;False;False;False;False;False;False;False;False;True;1;False;;False;False;True;1;LightMode=DepthOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;319;1744,-656;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;17;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;320;1744,-656;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;17;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;Universal2D;0;5;Universal2D;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;0;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=Universal2D;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;321;1744,-656;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;17;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;SceneSelectionPass;0;6;SceneSelectionPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;2;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=SceneSelectionPass;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;322;1744,-656;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;17;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;ScenePickingPass;0;7;ScenePickingPass;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Picking;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;323;1744,-656;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;17;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;DepthNormals;0;8;DepthNormals;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;324;1744,-656;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;17;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;DepthNormalsOnly;0;9;DepthNormalsOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;;True;3;False;;False;True;1;LightMode=DepthNormalsOnly;False;True;9;d3d11;metal;vulkan;xboxone;xboxseries;playstation;ps4;ps5;switch;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;325;1744,-656;Float;False;False;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;17;New Amplify Shader;60b6e374d24fe6feda8ee4144ab035b5;True;MotionVectors;0;10;MotionVectors;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;False;False;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=MotionVectors;False;False;0;;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;316;3392,-1248;Float;False;True;-1;2;UnityEditor.ShaderGraphUnlitGUI;0;17;FluidShader;60b6e374d24fe6feda8ee4144ab035b5;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;False;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;False;False;False;True;4;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;UniversalMaterialType=Unlit;True;5;True;12;all;0;False;True;1;1;False;;0;False;;1;1;False;;0;False;;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;LightMode=UniversalForwardOnly;False;False;0;;0;0;Standard;16;Surface;0;0;  Blend;0;0;Two Sided;1;0;Forward Only;0;0;Alpha Clipping;0;638696082551683540;  Use Shadow Threshold;0;0;Cast Shadows;0;638696082459278180;Receive Shadows;0;638696082474223740;Motion Vectors;0;638696082495127220;  Add Precomputed Velocity;0;0;GPU Instancing;0;638696082519373310;LOD CrossFade;0;638696082530054650;Built-in Fog;0;638696082534355920;Meta Pass;0;0;Extra Pre Pass;0;0;Vertex Position,InvertActionOnDeselection;0;638692760323141090;0;11;False;True;False;False;False;False;False;False;False;False;False;False;;False;0
WireConnection;458;0;448;0
WireConnection;457;0;458;0
WireConnection;432;0;294;0
WireConnection;483;3;432;0
WireConnection;483;1;401;0
WireConnection;502;11;489;0
WireConnection;502;5;401;0
WireConnection;502;6;457;0
WireConnection;420;0;502;0
WireConnection;420;1;483;0
WireConnection;439;0;420;0
WireConnection;439;1;442;0
WireConnection;414;0;439;0
WireConnection;414;1;413;0
WireConnection;412;0;414;0
WireConnection;412;1;411;0
WireConnection;422;0;423;0
WireConnection;422;1;438;0
WireConnection;424;0;425;0
WireConnection;424;1;438;0
WireConnection;456;0;294;0
WireConnection;460;0;448;0
WireConnection;459;0;448;0
WireConnection;224;0;412;0
WireConnection;484;3;294;0
WireConnection;484;1;422;0
WireConnection;485;3;456;0
WireConnection;485;1;424;0
WireConnection;503;11;489;0
WireConnection;503;5;422;0
WireConnection;503;6;459;0
WireConnection;504;11;489;0
WireConnection;504;5;424;0
WireConnection;504;6;460;0
WireConnection;430;0;503;0
WireConnection;430;1;484;0
WireConnection;436;0;504;0
WireConnection;436;1;485;0
WireConnection;440;0;430;0
WireConnection;440;1;442;0
WireConnection;333;0;332;0
WireConnection;441;0;436;0
WireConnection;441;1;442;0
WireConnection;331;0;440;0
WireConnection;331;1;333;0
WireConnection;334;0;441;0
WireConnection;334;1;333;0
WireConnection;336;2;331;0
WireConnection;335;2;334;0
WireConnection;337;0;336;0
WireConnection;337;1;335;0
WireConnection;338;0;337;0
WireConnection;237;0;338;0
WireConnection;378;0;395;0
WireConnection;376;0;80;0
WireConnection;376;1;138;0
WireConnection;376;2;145;0
WireConnection;376;3;377;0
WireConnection;376;4;378;0
WireConnection;394;0;393;0
WireConnection;382;0;376;0
WireConnection;382;1;392;0
WireConnection;385;0;443;0
WireConnection;385;1;394;0
WireConnection;373;0;238;0
WireConnection;383;0;382;0
WireConnection;383;1;164;5
WireConnection;391;0;385;0
WireConnection;384;0;383;0
WireConnection;384;1;391;0
WireConnection;371;0;372;0
WireConnection;371;1;169;5
WireConnection;371;2;190;5
WireConnection;371;3;187;0
WireConnection;371;4;373;0
WireConnection;371;5;374;0
WireConnection;371;6;375;0
WireConnection;388;0;371;0
WireConnection;389;0;384;0
WireConnection;389;1;148;0
WireConnection;386;0;389;0
WireConnection;386;1;388;0
WireConnection;277;0;112;0
WireConnection;277;1;278;0
WireConnection;113;0;277;0
WireConnection;111;0;113;0
WireConnection;111;1;116;0
WireConnection;111;2;125;0
WireConnection;111;3;114;0
WireConnection;111;4;120;0
WireConnection;111;5;121;0
WireConnection;397;0;111;0
WireConnection;202;0;111;0
WireConnection;202;1;211;0
WireConnection;254;0;202;0
WireConnection;254;1;253;0
WireConnection;274;0;273;0
WireConnection;275;0;274;0
WireConnection;276;1;274;0
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
WireConnection;227;0;244;0
WireConnection;227;1;226;0
WireConnection;228;0;245;0
WireConnection;228;1;226;0
WireConnection;226;0;225;0
WireConnection;272;2;228;0
WireConnection;271;2;227;0
WireConnection;231;0;271;0
WireConnection;231;1;272;0
WireConnection;264;0;231;0
WireConnection;316;2;386;0
WireConnection;316;5;415;0
ASEEND*/
//CHKSM=279CEE6DE01BD2E8319F526533E4F843EB36AE7E