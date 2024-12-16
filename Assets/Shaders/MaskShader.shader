// Made with Amplify Shader Editor v1.9.7.1
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Hidden/PaintShader"
{
	Properties
	{
		_BrushSettings("BrushSettings", Vector) = (0,0,0,0)
		_DeltaTime("DeltaTime", Float) = 0
		_PreviousTexture("_PreviousTexture", 2D) = "white" {}
		_Paint("Paint", Float) = 0
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

	}
	
	SubShader
	{
		
		
		Tags { "RenderType"="Opaque" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend Off
		AlphaToMask Off
		Cull Back
		ColorMask RGBA
		ZWrite On
		ZTest LEqual
		Offset 0 , 0
		
		
		
		Pass
		{
			Name "Unlit"

			CGPROGRAM

			#define ASE_VERSION 19701


			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX
			//only defining to not throw compilation error over Unity 5.5
			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};
			
			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			uniform sampler2D _PreviousTexture;
			uniform float4 _PreviousTexture_ST;
			uniform float3 _BrushSettings;
			uniform float _Paint;
			uniform float _DeltaTime;

			
			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_texcoord1.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord1.zw = 0;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);

				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				return o;
			}
			
			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				float2 uv_PreviousTexture = i.ase_texcoord1.xy * _PreviousTexture_ST.xy + _PreviousTexture_ST.zw;
				float4 tex2DNode15 = tex2D( _PreviousTexture, uv_PreviousTexture );
				float2 appendResult5 = (float2(_BrushSettings.x , _BrushSettings.y));
				float2 texCoord1 = i.ase_texcoord1.xy * float2( 1,1 ) + ( appendResult5 - float2( 1,1 ) );
				float temp_output_49_0 = length( texCoord1 );
				float smoothstepResult50 = smoothstep( 0.2 , 0.0 , temp_output_49_0);
				float smoothstepResult55 = smoothstep( 0.1 , 0.02 , temp_output_49_0);
				float mask_258 = ( smoothstepResult50 - smoothstepResult55 );
				float temp_output_29_0 = ( _DeltaTime * 1 );
				float lerpResult26 = lerp( ( saturate( tex2DNode15.r ) + ( mask_258 * _Paint ) ) , 0.0 , temp_output_29_0);
				float smoothstepResult87 = smoothstep( 0.2 , 0.0 , temp_output_49_0);
				float mask_145 = ( smoothstepResult87 * smoothstepResult87 * smoothstepResult87 );
				float lerpResult83 = lerp( sin( ( ( saturate( tex2DNode15.g ) + ( ( mask_145 * 0.3 ) * _Paint ) ) * 1 ) ) , 0.0 , temp_output_29_0);
				float2 appendResult85 = (float2(lerpResult26 , lerpResult83));
				
				
				finalColor = float4( saturate( appendResult85 ), 0.0 , 0.0 );
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"
	
	Fallback Off
}
/*ASEBEGIN
Version=19701
Node;AmplifyShaderEditor.CommentaryNode;98;-1250,206;Inherit;False;2724;530.85;;12;1;45;94;87;55;50;49;5;58;65;4;107;Procedural Brush Alpha;0.3686541,0.3686541,0.3686541,1;0;0
Node;AmplifyShaderEditor.Vector3Node;4;-1232,272;Inherit;False;Property;_BrushSettings;BrushSettings;0;0;Create;True;0;0;0;False;0;False;0,0,0;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.DynamicAppendNode;5;-960,304;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;107;-752,304;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;1,1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TextureCoordinatesNode;1;-480,256;Inherit;True;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LengthOpNode;49;-80,256;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;87;640,256;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.2;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;94;960,256;Inherit;False;3;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CommentaryNode;99;-1266,-770;Inherit;False;2468;729.1905;;19;15;70;71;89;93;74;96;88;95;46;91;92;20;83;85;26;29;17;97;Blend with previous frame;0.4532527,0.6854984,0.9690454,1;0;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;45;1232,256;Inherit;False;mask_1;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;55;224,576;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.1;False;2;FLOAT;0.02;False;1;FLOAT;0
Node;AmplifyShaderEditor.SmoothstepOpNode;50;224,448;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.2;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;46;-592,-176;Inherit;False;45;mask_1;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;65;672,448;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleNode;91;-400,-176;Inherit;False;0.3;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;20;-448,-416;Inherit;False;Property;_Paint;Paint;3;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;15;-1216,-448;Inherit;True;Property;_PreviousTexture;_PreviousTexture;2;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;6;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4;FLOAT3;5
Node;AmplifyShaderEditor.RegisterLocalVarNode;58;1232,448;Inherit;False;mask_2;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;70;-196.5664,-177.7095;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;92;-176,-368;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;71;-416,-560;Inherit;False;58;mask_2;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;89;16,-368;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WireNode;97;-880,-624;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;93;-416,-720;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;74;-192,-560;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleNode;96;160,-368;Inherit;False;1;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;17;464,-272;Inherit;False;Property;_DeltaTime;DeltaTime;1;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;88;64,-720;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SinOpNode;95;336,-368;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleNode;29;624,-272;Inherit;False;1;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;83;832,-368;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0.2;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;26;800,-720;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;85;1024,-480;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SaturateNode;108;1264,-480;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;1504,-480;Float;False;True;-1;2;ASEMaterialInspector;100;5;Hidden/PaintShader;0770190933193b94aaa3065e307002fa;True;Unlit;0;0;Unlit;2;False;True;0;1;False;;0;False;;0;1;False;;0;False;;True;0;False;;0;False;;False;False;False;False;False;False;False;False;False;True;0;False;;False;True;0;False;;False;True;True;True;True;True;0;False;;False;False;False;False;False;False;False;True;False;0;False;;255;False;;255;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;0;False;;False;True;1;False;;True;3;False;;True;True;0;False;;0;False;;True;1;RenderType=Opaque=RenderType;True;2;False;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;False;0;;0;0;Standard;1;Vertex Position,InvertActionOnDeselection;1;0;0;1;True;False;;False;0
WireConnection;5;0;4;1
WireConnection;5;1;4;2
WireConnection;107;0;5;0
WireConnection;1;1;107;0
WireConnection;49;0;1;0
WireConnection;87;0;49;0
WireConnection;94;0;87;0
WireConnection;94;1;87;0
WireConnection;94;2;87;0
WireConnection;45;0;94;0
WireConnection;55;0;49;0
WireConnection;50;0;49;0
WireConnection;65;0;50;0
WireConnection;65;1;55;0
WireConnection;91;0;46;0
WireConnection;58;0;65;0
WireConnection;70;0;91;0
WireConnection;70;1;20;0
WireConnection;92;0;15;2
WireConnection;89;0;92;0
WireConnection;89;1;70;0
WireConnection;97;0;15;1
WireConnection;93;0;97;0
WireConnection;74;0;71;0
WireConnection;74;1;20;0
WireConnection;96;0;89;0
WireConnection;88;0;93;0
WireConnection;88;1;74;0
WireConnection;95;0;96;0
WireConnection;29;0;17;0
WireConnection;83;0;95;0
WireConnection;83;2;29;0
WireConnection;26;0;88;0
WireConnection;26;2;29;0
WireConnection;85;0;26;0
WireConnection;85;1;83;0
WireConnection;108;0;85;0
WireConnection;3;0;108;0
ASEEND*/
//CHKSM=D57109F758AD02F465C3691FD66240A5C694F0E8