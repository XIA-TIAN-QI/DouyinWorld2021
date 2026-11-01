// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Douyin/AI/Cartoon/ItemNPR_AIHaiHai"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[ASEBegin]_BaseTex("BaseTex", 2D) = "white" {}
		_BaseColor("BaseColor", Color) = (1,1,1,0)
		_ColorPower("ColorPower", Range( 0 , 10)) = 1
		_DarkColor("DarkColor", Color) = (1,1,1,0)
		_DarkColorPower("DarkColorPower", Range( 0 , 10)) = 1
		_DarkRange("DarkRange", Range( -1 , 1)) = 1
		_DarkSoft("DarkSoft", Range( 0 , 5)) = 0.1
		[Header(__________________Outline____________________________________________________________________________________________)]_OutlineWidth("OutlineWidth", Range( 0 , 100)) = 0.1
		_WidthScaleFix("WidthScaleFix", Float) = 0.05
		_OutlineColor("OutlineColor", Color) = (0.2075472,0.2075472,0.2075472,0)
		_OutlineColorBlendIntensity("OutlineColorBlendIntensity", Range( 0 , 1)) = 0
		_OutlineZoffset("OutlineZoffset", Float) = 0
		_Saturation("Saturation", Float) = 0
		_ColorGamut("ColorGamut", Float) = 0
		_Brightness("Brightness", Float) = 0
		[Header(__________________Normal____________________________________________________________________________________________)]_Normalmap("Normalmap", 2D) = "bump" {}
		_NormalScale("NormalScale", Range( 0 , 10)) = 1
		[Header(__________________Specular____________________________________________________________________________________________)][Toggle]_UseSpecular("UseSpecular", Float) = 0
		_SpecularPower("SpecularPower", Range( 0 , 5)) = 1
		_SpecularMask2("SpecularMask(G)", 2D) = "white" {}
		_SpecularColor("SpecularColor", Color) = (0.2358491,0.2358491,0.2358491,0)
		_SpecularRange("SpecularRange", Range( -1 , 0)) = -0.75
		_SpecularSoft("SpecularSoft", Range( 0 , 50)) = 5
		_SpecularColor01("SpecularColor01", Color) = (0.6132076,0.6132076,0.6132076,0)
		_SpecularMaskRange01("SpecularMaskRange01", Range( -1 , 0)) = -0.2
		_SpecularSoft01("SpecularSoft01", Range( 0 , 100)) = 50
		_SpecularColor02("SpecularColor02", Color) = (0.9150943,0.9150943,0.9150943,0)
		_SpecularMaskRange02("SpecularMaskRange02", Range( -1 , 0)) = -0.1
		_SpecularSoft02("SpecularSoft02", Range( 0 , 100)) = 50
		[Header(___________________Matcap_________________________________________________________________________________________________)][Toggle(_USEMATCAP_ON)] _UseMatcap("UseMatcap", Float) = 0
		[NoScaleOffset]_MatcapTex2("MatcapTex", 2D) = "white" {}
		_MatcapColor2("MatcapColor", Color) = (1,1,1,0)
		_MatcapPower2("MatcapPower", Range( 0 , 14)) = 1
		_MatcapBlend2("MatcapBlend", Range( 0 , 1)) = 1
		[Header(__________________RimLight____________________________________________________________________________________________)][Header()]_RimLightColor("RimLightColor", Color) = (0,0,0,0)
		_RimLightRange("RimLightRange", Range( 0 , 2)) = 0.9
		_RimLightSoft("RimLightSoft", Range( 0 , 5)) = 0.2
		_RimOffset("RimOffset", Float) = 0.16
		[ASEEnd]_RimPower("RimPower", Range( 0 , 20)) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector] _CullMode("Cull Mode", Float) = 2
	}

	SubShader
	{
		LOD 0

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		
		Cull Back
		AlphaToMask Off
		HLSLINCLUDE
		#pragma target 2.0

		#pragma prefer_hlslcc gles
		#pragma only_renderers d3d9 d3d11_9x d3d11 glcore gles gles3 metal vulkan 

		#ifndef ASE_TESS_FUNCS
		#define ASE_TESS_FUNCS
		float4 FixedTess( float tessValue )
		{
			return tessValue;
		}
		
		float CalcDistanceTessFactor (float4 vertex, float minDist, float maxDist, float tess, float4x4 o2w, float3 cameraPos )
		{
			float3 wpos = mul(o2w,vertex).xyz;
			float dist = distance (wpos, cameraPos);
			float f = clamp(1.0 - (dist - minDist) / (maxDist - minDist), 0.01, 1.0) * tess;
			return f;
		}

		float4 CalcTriEdgeTessFactors (float3 triVertexFactors)
		{
			float4 tess;
			tess.x = 0.5 * (triVertexFactors.y + triVertexFactors.z);
			tess.y = 0.5 * (triVertexFactors.x + triVertexFactors.z);
			tess.z = 0.5 * (triVertexFactors.x + triVertexFactors.y);
			tess.w = (triVertexFactors.x + triVertexFactors.y + triVertexFactors.z) / 3.0f;
			return tess;
		}

		float CalcEdgeTessFactor (float3 wpos0, float3 wpos1, float edgeLen, float3 cameraPos, float4 scParams )
		{
			float dist = distance (0.5 * (wpos0+wpos1), cameraPos);
			float len = distance(wpos0, wpos1);
			float f = max(len * scParams.y / (edgeLen * dist), 1.0);
			return f;
		}

		float DistanceFromPlane (float3 pos, float4 plane)
		{
			float d = dot (float4(pos,1.0f), plane);
			return d;
		}

		bool WorldViewFrustumCull (float3 wpos0, float3 wpos1, float3 wpos2, float cullEps, float4 planes[6] )
		{
			float4 planeTest;
			planeTest.x = (( DistanceFromPlane(wpos0, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[0]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[0]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.y = (( DistanceFromPlane(wpos0, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[1]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[1]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.z = (( DistanceFromPlane(wpos0, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[2]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[2]) > -cullEps) ? 1.0f : 0.0f );
			planeTest.w = (( DistanceFromPlane(wpos0, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos1, planes[3]) > -cullEps) ? 1.0f : 0.0f ) +
						  (( DistanceFromPlane(wpos2, planes[3]) > -cullEps) ? 1.0f : 0.0f );
			return !all (planeTest);
		}

		float4 DistanceBasedTess( float4 v0, float4 v1, float4 v2, float tess, float minDist, float maxDist, float4x4 o2w, float3 cameraPos )
		{
			float3 f;
			f.x = CalcDistanceTessFactor (v0,minDist,maxDist,tess,o2w,cameraPos);
			f.y = CalcDistanceTessFactor (v1,minDist,maxDist,tess,o2w,cameraPos);
			f.z = CalcDistanceTessFactor (v2,minDist,maxDist,tess,o2w,cameraPos);

			return CalcTriEdgeTessFactors (f);
		}

		float4 EdgeLengthBasedTess( float4 v0, float4 v1, float4 v2, float edgeLength, float4x4 o2w, float3 cameraPos, float4 scParams )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;
			tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
			tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
			tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
			tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			return tess;
		}

		float4 EdgeLengthBasedTessCull( float4 v0, float4 v1, float4 v2, float edgeLength, float maxDisplacement, float4x4 o2w, float3 cameraPos, float4 scParams, float4 planes[6] )
		{
			float3 pos0 = mul(o2w,v0).xyz;
			float3 pos1 = mul(o2w,v1).xyz;
			float3 pos2 = mul(o2w,v2).xyz;
			float4 tess;

			if (WorldViewFrustumCull(pos0, pos1, pos2, maxDisplacement, planes))
			{
				tess = 0.0f;
			}
			else
			{
				tess.x = CalcEdgeTessFactor (pos1, pos2, edgeLength, cameraPos, scParams);
				tess.y = CalcEdgeTessFactor (pos2, pos0, edgeLength, cameraPos, scParams);
				tess.z = CalcEdgeTessFactor (pos0, pos1, edgeLength, cameraPos, scParams);
				tess.w = (tess.x + tess.y + tess.z) / 3.0f;
			}
			return tess;
		}
		#endif //ASE_TESS_FUNCS

		ENDHLSL

		
		Pass
		{
			Name "ExtraPrePass"
			Tags { "LightMode"="SRPDefaultUnlit" }
			
			Blend One Zero
			Cull Front
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 999999

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
				float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _SpecularColor;
			float4 _SpecularMask2_ST;
			float4 _RimLightColor;
			float4 _DarkColor;
			float4 _SpecularColor01;
			float4 _Normalmap_ST;
			float4 _MatcapColor2;
			float4 _BaseTex_ST;
			float4 _BaseColor;
			float4 _OutlineColor;
			float4 _SpecularColor02;
			float _Brightness;
			float _RimOffset;
			float _Saturation;
			float _ColorGamut;
			float _DarkSoft;
			float _DarkRange;
			float _SpecularPower;
			float _SpecularSoft02;
			float _SpecularMaskRange02;
			float _RimLightRange;
			float _RimLightSoft;
			float _OutlineWidth;
			float _SpecularMaskRange01;
			float _SpecularSoft;
			float _SpecularRange;
			float _UseSpecular;
			float _DarkColorPower;
			float _MatcapBlend2;
			float _MatcapPower2;
			float _NormalScale;
			float _OutlineColorBlendIntensity;
			float _ColorPower;
			float _OutlineZoffset;
			float _WidthScaleFix;
			float _SpecularSoft01;
			float _RimPower;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			CBUFFER_START(AvatarLightingPreFrame)
				half4 _MainLightPosition2;
				half4 _MainLightColor2;			// x,y,z : ��ʶ̫�������ɫ
				half _SliptEnvmentConfig;
			CBUFFER_END

			float4 GetMainLightDir()
			{
				return _MainLightColor2.a <= 0.001 ? _MainLightPosition : _MainLightPosition2;
			}

			float4 GetMainLightColor()
			{
				return _MainLightColor2.a <= 0.001 ? _MainLightColor : _MainLightColor2;
			}

			float GetEnvSplitFlag()
			{
				return _SliptEnvmentConfig;
			}

			sampler2D _BaseTex;


			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_objectScale = float3( length( GetObjectToWorldMatrix()[ 0 ].xyz ), length( GetObjectToWorldMatrix()[ 1 ].xyz ), length( GetObjectToWorldMatrix()[ 2 ].xyz ) );
				float3 objToWorld157 = mul( GetObjectToWorldMatrix(), float4( v.vertex.xyz, 1 ) ).xyz;
				float3 normalizeResult160 = normalize( ( _WorldSpaceCameraPos - objToWorld157 ) );
				float3 worldToObjDir161 = normalize( mul( GetWorldToObjectMatrix(), float4( normalizeResult160, 0 ) ).xyz );
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( ( v.ase_normal * ( _OutlineWidth / 1000.0 ) * ( ( 1.0 / ase_objectScale ) + _WidthScaleFix ) ) + ( worldToObjDir161 * _OutlineZoffset ) );
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				#ifdef ASE_FOG
				o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif
				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{

				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif
				float2 uv_BaseTex = IN.ase_texcoord3.xy * _BaseTex_ST.xy + _BaseTex_ST.zw;
				float4 temp_output_95_0 = ( _BaseColor * tex2D( _BaseTex, uv_BaseTex ) * _ColorPower );
				float4 lerpResult125 = lerp( ( temp_output_95_0 * _OutlineColor ) , _OutlineColor , _OutlineColorBlendIntensity);
				
				float3 Color = saturate( lerpResult125 ).rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#ifdef _ALPHAACTOR_ON
					clip(-1.0);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				return half4( Color, Alpha );
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			Cull [_CullMode]
			

			HLSLPROGRAM

			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 999999


			#pragma multi_compile _ SHADOWS_SHADOWMASK
			#pragma multi_compile _ LIGHTMAP_SHADOW_MIXING

			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS
			#pragma multi_compile _ _MAIN_LIGHT_SHADOWS_CASCADE
			#pragma multi_compile _ _ADDITIONAL_LIGHTS_VERTEX _ADDITIONAL_LIGHTS _ADDITIONAL_OFF
			#pragma multi_compile _ LIGHTMAP_ON
			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/UnityInstancing.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"

			#if ASE_SRP_VERSION <= 70108
			#define REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR
			#endif

			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#define ASE_NEEDS_VERT_NORMAL
			#pragma shader_feature _USEMATCAP_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord1 : TEXCOORD1;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				#ifdef ASE_FOG
				float fogFactor : TEXCOORD2;
				#endif
				float4 ase_texcoord3 : TEXCOORD3;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				float4 ase_texcoord6 : TEXCOORD6;
				float4 ase_texcoord7 : TEXCOORD7;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _SpecularColor;
			float4 _SpecularMask2_ST;
			float4 _RimLightColor;
			float4 _DarkColor;
			float4 _SpecularColor01;
			float4 _Normalmap_ST;
			float4 _MatcapColor2;
			float4 _BaseTex_ST;
			float4 _BaseColor;
			float4 _OutlineColor;
			float4 _SpecularColor02;
			float _Brightness;
			float _RimOffset;
			float _Saturation;
			float _ColorGamut;
			float _DarkSoft;
			float _DarkRange;
			float _SpecularPower;
			float _SpecularSoft02;
			float _SpecularMaskRange02;
			float _RimLightRange;
			float _RimLightSoft;
			float _OutlineWidth;
			float _SpecularMaskRange01;
			float _SpecularSoft;
			float _SpecularRange;
			float _UseSpecular;
			float _DarkColorPower;
			float _MatcapBlend2;
			float _MatcapPower2;
			float _NormalScale;
			float _OutlineColorBlendIntensity;
			float _ColorPower;
			float _OutlineZoffset;
			float _WidthScaleFix;
			float _SpecularSoft01;
			float _RimPower;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			CBUFFER_START(AvatarLightingPreFrame)
				half4 _MainLightPosition2;
				half4 _MainLightColor2;			// x,y,z : ��ʶ̫�������ɫ
				half _SliptEnvmentConfig;
			CBUFFER_END

			float4 GetMainLightDir()
			{
				return _MainLightColor2.a <= 0.001 ? _MainLightPosition : _MainLightPosition2;
			}

			float4 GetMainLightColor()
			{
				return _MainLightColor2.a <= 0.001 ? _MainLightColor : _MainLightColor2;
			}

			float GetEnvSplitFlag()
			{
				return _SliptEnvmentConfig;
			}
			sampler2D _BaseTex;
			sampler2D _MatcapTex2;
			sampler2D _Normalmap;
			sampler2D _SpecularMask2;


			real3 ASESafeNormalize(float3 inVec)
			{
				real dp3 = max(FLT_MIN, dot(inVec, inVec));
				return inVec* rsqrt( dp3);
			}
			
			float3 ShadowMask72( float3 ClipSpacePos, float3 WorldPos, float IlluminationModel, float2 lightmapUV, out float finalShadow )
			{
				float4 shadowCoord;
				        #if SHADOWS_SCREEN
				            shadowCoord = ComputeScreenPos(ClipSpacePos);
				        #else
				            shadowCoord = TransformWorldToShadowCoord(WorldPos);
				        #endif
				        // 获取主光源
				        Light light;
				        #if _MAIN_LIGHT_SHADOWS_CASCADE || _MAIN_LIGHT_SHADOWS
				            light = GetMainLight(shadowCoord);
				        #else
				            light = GetMainLight();
				        #endif
				// 1. 采样静态阴影（Shadowmask）
				float staticShadow = 1.0;  // 默认无静态阴影
				#ifdef SHADOWS_SHADOWMASK
				    // 静态阴影存储在unity_ShadowMask纹理中，主光源通常对应r通道
				    float2 adjustedLightmapUV = lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw;
				    float4 shadowmask = SAMPLE_TEXTURE2D(unity_ShadowMask, samplerunity_ShadowMask, adjustedLightmapUV);
				    staticShadow = shadowmask.r;  // 取主光源的静态阴影衰减
				#endif
				// 2. 计算动态与静态阴影的混合因子（基于距离）
				float shadowMixFactor = GetMainLightShadowFade(WorldPos);
				float _ShadowDistance = GetMainLightShadowStrength();
				// 3. 混合动态阴影和静态阴影（lerp(动态, 静态, 混合因子)）
				float dynamicShadow = light.shadowAttenuation;  // 动态阴影衰减
				finalShadow = lerp(dynamicShadow, staticShadow, shadowMixFactor);
				// 4. 将混合后的阴影应用到卡通渐变
				return IlluminationModel * finalShadow;
			}
			
			float4 SampleLightmapHD11_g177( float2 UV )
			{
				return SAMPLE_TEXTURE2D( unity_Lightmap, samplerunity_Lightmap, UV );
			}
			
			float4 URPDecodeInstruction19_g177(  )
			{
				return float4(LIGHTMAP_HDR_MULTIPLIER, LIGHTMAP_HDR_EXPONENT, 0, 0);
			}
			
			float3 HSVToRGB( float3 c )
			{
				float4 K = float4( 1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0 );
				float3 p = abs( frac( c.xxx + K.xyz ) * 6.0 - K.www );
				return c.z * lerp( K.xxx, saturate( p - K.xxx ), c.y );
			}
			
			float3 RGBToHSV(float3 c)
			{
				float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
				float4 p = lerp( float4( c.bg, K.wz ), float4( c.gb, K.xy ), step( c.b, c.g ) );
				float4 q = lerp( float4( p.xyw, c.r ), float4( c.r, p.yzx ), step( p.x, c.r ) );
				float d = q.x - min( q.w, q.y );
				float e = 1.0e-10;
				return float3( abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
			}
			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord4.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord5.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * unity_WorldTransformParams.w;
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord6.xyz = ase_worldBitangent;
				float2 texCoord2_g177 = v.ase_texcoord1.xy * float2( 1,1 ) + float2( 0,0 );
				float2 vertexToFrag10_g177 = ( ( texCoord2_g177 * (unity_LightmapST).xy ) + (unity_LightmapST).zw );
				o.ase_texcoord7.xy = vertexToFrag10_g177;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_texcoord3.zw = v.ase_texcoord1.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;
				o.ase_texcoord6.w = 0;
				o.ase_texcoord7.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif
				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );
				float4 positionCS = TransformWorldToHClip( positionWS );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				VertexPositionInputs vertexInput = (VertexPositionInputs)0;
				vertexInput.positionWS = positionWS;
				vertexInput.positionCS = positionCS;
				o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				#ifdef ASE_FOG
				o.fogFactor = ComputeFogFactor( positionCS.z );
				#endif
				o.clipPos = positionCS;
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;
				float4 ase_texcoord1 : TEXCOORD1;

				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				o.ase_texcoord = v.ase_texcoord;
				o.ase_tangent = v.ase_tangent;
				o.ase_texcoord1 = v.ase_texcoord1;
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				o.ase_texcoord = patch[0].ase_texcoord * bary.x + patch[1].ase_texcoord * bary.y + patch[2].ase_texcoord * bary.z;
				o.ase_tangent = patch[0].ase_tangent * bary.x + patch[1].ase_tangent * bary.y + patch[2].ase_tangent * bary.z;
				o.ase_texcoord1 = patch[0].ase_texcoord1 * bary.x + patch[1].ase_texcoord1 * bary.y + patch[2].ase_texcoord1 * bary.z;
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag ( VertexOutput IN  ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif
				float2 uv_BaseTex = IN.ase_texcoord3.xy * _BaseTex_ST.xy + _BaseTex_ST.zw;
				float4 temp_output_95_0 = ( _BaseColor * tex2D( _BaseTex, uv_BaseTex ) * _ColorPower );
				float3 normalizeResult5_g176 = normalize( ( _WorldSpaceCameraPos - WorldPosition ) );
				float2 uv_Normalmap = IN.ase_texcoord3.xy * _Normalmap_ST.xy + _Normalmap_ST.zw;
				float3 unpack83 = UnpackNormalScale( tex2D( _Normalmap, uv_Normalmap ), _NormalScale );
				unpack83.z = lerp( 1, unpack83.z, saturate(_NormalScale) );
				float3 normalizeResult20 = ASESafeNormalize( unpack83 );
				float3 ase_worldTangent = IN.ase_texcoord4.xyz;
				float3 ase_worldNormal = IN.ase_texcoord5.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord6.xyz;
				float3x3 ase_tangentToWorldFast = float3x3(ase_worldTangent.x,ase_worldBitangent.x,ase_worldNormal.x,ase_worldTangent.y,ase_worldBitangent.y,ase_worldNormal.y,ase_worldTangent.z,ase_worldBitangent.z,ase_worldNormal.z);
				float3 tangentToWorldDir13 = normalize( mul( ase_tangentToWorldFast, normalizeResult20 ) );
				float4 appendResult8_g176 = (float4(reflect( normalizeResult5_g176 , tangentToWorldDir13 ) , 0.0));
				float3 normalizeResult11_g176 = normalize( (mul( unity_WorldToCamera, appendResult8_g176 )).xyz );
				float3 break12_g176 = normalizeResult11_g176;
				float2 appendResult16_g176 = (float2(break12_g176.x , break12_g176.y));
				float4 temp_output_30_0 = ( tex2D( _MatcapTex2, ( 1.0 - ( ( appendResult16_g176 / ( sqrt( ( break12_g176.z + 1.0 ) ) * 2.828427 ) ) + float2( 0.5,0.5 ) ) ) ) * _MatcapColor2 * ( _MatcapPower2 * 0.4 ) );
				float4 temp_cast_1 = (0.5).xxxx;
				float4 temp_output_8_0 = step( temp_output_30_0 , temp_cast_1 );
				float4 temp_cast_2 = (0.5).xxxx;
				float4 lerpResult66 = lerp( temp_output_95_0 , ( ( ( temp_output_95_0 * temp_output_30_0 * 2.0 ) * temp_output_8_0 ) + ( ( 1.0 - ( ( 1.0 - temp_output_95_0 ) * ( 1.0 - temp_output_30_0 ) * 2.0 ) ) * ( 1.0 - temp_output_8_0 ) ) ) , _MatcapBlend2);
				#ifdef _USEMATCAP_ON
				float4 staticSwitch23 = lerpResult66;
				#else
				float4 staticSwitch23 = temp_output_95_0;
				#endif
				float3 tanToWorld0 = float3( ase_worldTangent.x, ase_worldBitangent.x, ase_worldNormal.x );
				float3 tanToWorld1 = float3( ase_worldTangent.y, ase_worldBitangent.y, ase_worldNormal.y );
				float3 tanToWorld2 = float3( ase_worldTangent.z, ase_worldBitangent.z, ase_worldNormal.z );
				float3 tanNormal85 = normalizeResult20;
				float3 worldNormal85 = normalize( float3(dot(tanToWorld0,tanNormal85), dot(tanToWorld1,tanNormal85), dot(tanToWorld2,tanNormal85)) );
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = SafeNormalize( ase_worldViewDir );
				float3 normalizeResult27 = normalize( ( SafeNormalize(_MainLightPosition.xyz) + ase_worldViewDir ) );
				float dotResult89 = dot( worldNormal85 , normalizeResult27 );
				float temp_output_56_0 = ( dotResult89 + _SpecularRange );
				float2 uv_SpecularMask2 = IN.ase_texcoord3.xy * _SpecularMask2_ST.xy + _SpecularMask2_ST.zw;
				float4 tex2DNode47 = tex2D( _SpecularMask2, uv_SpecularMask2 );
				float temp_output_58_0 = ( temp_output_56_0 + _SpecularMaskRange01 );
				float4 lerpResult59 = lerp( ( saturate( ( temp_output_56_0 * _SpecularSoft ) ) * _SpecularColor * tex2DNode47.g ) , _SpecularColor01 , ( tex2DNode47.g * saturate( ( temp_output_58_0 * _SpecularSoft01 ) ) ));
				float4 lerpResult67 = lerp( lerpResult59 , _SpecularColor02 , ( tex2DNode47.g * saturate( ( ( temp_output_58_0 + _SpecularMaskRange02 ) * _SpecularSoft02 ) ) ));
				float4 unityObjectToClipPos82 = TransformWorldToHClip(TransformObjectToWorld(float3( 0,0,0 )));
				float4 computeScreenPos71 = ComputeScreenPos( unityObjectToClipPos82 );
				computeScreenPos71 = computeScreenPos71 / computeScreenPos71.w;
				computeScreenPos71.z = ( UNITY_NEAR_CLIP_VALUE >= 0 ) ? computeScreenPos71.z : computeScreenPos71.z* 0.5 + 0.5;
				float3 ClipSpacePos72 = computeScreenPos71.xyz;
				float3 WorldPos72 = WorldPosition;
				float dotResult74 = dot( worldNormal85 , SafeNormalize(_MainLightPosition.xyz) );
				float temp_output_11_0 = saturate( ( ( dotResult74 + _DarkRange ) / _DarkSoft ) );
				float IlluminationModel72 = temp_output_11_0;
				float2 texCoord75 = IN.ase_texcoord3.zw * float2( 1,1 ) + float2( 0,0 );
				float2 lightmapUV72 = texCoord75;
				float finalShadow72 = 0.0;
				float3 localShadowMask72 = ShadowMask72( ClipSpacePos72 , WorldPos72 , IlluminationModel72 , lightmapUV72 , finalShadow72 );
				float temp_output_149_0 = ( finalShadow72 * temp_output_11_0 );
				float4 lerpResult61 = lerp( ( staticSwitch23 * _DarkColor * _DarkColorPower ) , ( staticSwitch23 + ( _UseSpecular * lerpResult67 * _SpecularPower ) ) , temp_output_149_0);
				float2 vertexToFrag10_g177 = IN.ase_texcoord7.xy;
				float2 UV11_g177 = vertexToFrag10_g177;
				float4 localSampleLightmapHD11_g177 = SampleLightmapHD11_g177( UV11_g177 );
				float4 localURPDecodeInstruction19_g177 = URPDecodeInstruction19_g177();
				float3 decodeLightMap6_g177 = DecodeLightmap(localSampleLightmapHD11_g177,localURPDecodeInstruction19_g177);
				float4 temp_output_60_0 = ( lerpResult61 * float4( ( _MainLightColor.rgb + decodeLightMap6_g177 ) , 0.0 ) );
				float3 hsvTorgb109 = RGBToHSV( temp_output_60_0.rgb );
				float3 hsvTorgb117 = HSVToRGB( float3(saturate( ( hsvTorgb109.x + _ColorGamut ) ),saturate( ( hsvTorgb109.y + _Saturation ) ),saturate( ( _Brightness + hsvTorgb109.z ) )) );
				float4 lerpResult118 = lerp( temp_output_60_0 , float4( hsvTorgb117 , 0.0 ) , ( 1.0 - temp_output_149_0 ));
				ase_worldViewDir = normalize(ase_worldViewDir);
				float dotResult138 = dot( worldNormal85 , (ase_worldViewDir*1.0 + _RimOffset) );
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( lerpResult118 + ( saturate( ( ( 1.0 - ( dotResult138 + _RimLightRange ) ) / _RimLightSoft ) ) * _RimLightColor * _RimPower ) ).rgb;
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					clip( Alpha - AlphaClipThreshold );
				#endif

				#ifdef _ALPHAACTOR_ON
					clip( Alpha - 0.05 );
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif

				#ifdef ASE_FOG
					Color = MixFog( Color, IN.fogFactor );
				#endif

				return half4( Color, Alpha );
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "ShadowCaster"
			Tags { "LightMode"="ShadowCaster" }

			ZWrite On
			ZTest LEqual
			AlphaToMask Off

			HLSLPROGRAM
			
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 999999

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _SpecularColor;
			float4 _SpecularMask2_ST;
			float4 _RimLightColor;
			float4 _DarkColor;
			float4 _SpecularColor01;
			float4 _Normalmap_ST;
			float4 _MatcapColor2;
			float4 _BaseTex_ST;
			float4 _BaseColor;
			float4 _OutlineColor;
			float4 _SpecularColor02;
			float _Brightness;
			float _RimOffset;
			float _Saturation;
			float _ColorGamut;
			float _DarkSoft;
			float _DarkRange;
			float _SpecularPower;
			float _SpecularSoft02;
			float _SpecularMaskRange02;
			float _RimLightRange;
			float _RimLightSoft;
			float _OutlineWidth;
			float _SpecularMaskRange01;
			float _SpecularSoft;
			float _SpecularRange;
			float _UseSpecular;
			float _DarkColorPower;
			float _MatcapBlend2;
			float _MatcapPower2;
			float _NormalScale;
			float _OutlineColorBlendIntensity;
			float _ColorPower;
			float _OutlineZoffset;
			float _WidthScaleFix;
			float _SpecularSoft01;
			float _RimPower;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			CBUFFER_START(AvatarLightingPreFrame)
				half4 _MainLightPosition2;
				half4 _MainLightColor2;			// x,y,z : ��ʶ̫�������ɫ
				half _SliptEnvmentConfig;
			CBUFFER_END

			float4 GetMainLightDir()
			{
				return _MainLightColor2.a <= 0.001 ? _MainLightPosition : _MainLightPosition2;
			}

			float4 GetMainLightColor()
			{
				return _MainLightColor2.a <= 0.001 ? _MainLightColor : _MainLightColor2;
			}

			float GetEnvSplitFlag()
			{
				return _SliptEnvmentConfig;
			}

			

			
			float3 _LightDirection;

			VertexOutput VertexFunction( VertexInput v )
			{
				VertexOutput o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO( o );

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				float3 normalWS = TransformObjectToWorldDir( v.ase_normal );

				float4 clipPos = TransformWorldToHClip( ApplyShadowBias( positionWS, normalWS, _LightDirection ) );

				#if UNITY_REVERSED_Z
					clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#else
					clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
				#endif

				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				o.clipPos = clipPos;

				return o;
			}
			
			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID( IN );
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;
				float AlphaClipThresholdShadow = 0.5;

				#ifdef _ALPHATEST_ON
					#ifdef _ALPHATEST_SHADOW_ON
						clip(Alpha - AlphaClipThresholdShadow);
					#else
						clip(Alpha - AlphaClipThreshold);
					#endif
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}

			ENDHLSL
		}

		
		Pass
		{
			
			Name "DepthOnly"
			Tags { "LightMode"="DepthOnly" }

			ZWrite On
			ColorMask 0
			AlphaToMask Off

			HLSLPROGRAM
			
			#pragma multi_compile_instancing
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 999999

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			

			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct VertexOutput
			{
				float4 clipPos : SV_POSITION;
				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 worldPos : TEXCOORD0;
				#endif
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
				float4 shadowCoord : TEXCOORD1;
				#endif
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _SpecularColor;
			float4 _SpecularMask2_ST;
			float4 _RimLightColor;
			float4 _DarkColor;
			float4 _SpecularColor01;
			float4 _Normalmap_ST;
			float4 _MatcapColor2;
			float4 _BaseTex_ST;
			float4 _BaseColor;
			float4 _OutlineColor;
			float4 _SpecularColor02;
			float _Brightness;
			float _RimOffset;
			float _Saturation;
			float _ColorGamut;
			float _DarkSoft;
			float _DarkRange;
			float _SpecularPower;
			float _SpecularSoft02;
			float _SpecularMaskRange02;
			float _RimLightRange;
			float _RimLightSoft;
			float _OutlineWidth;
			float _SpecularMaskRange01;
			float _SpecularSoft;
			float _SpecularRange;
			float _UseSpecular;
			float _DarkColorPower;
			float _MatcapBlend2;
			float _MatcapPower2;
			float _NormalScale;
			float _OutlineColorBlendIntensity;
			float _ColorPower;
			float _OutlineZoffset;
			float _WidthScaleFix;
			float _SpecularSoft01;
			float _RimPower;
			#ifdef TESSELLATION_ON
				float _TessPhongStrength;
				float _TessValue;
				float _TessMin;
				float _TessMax;
				float _TessEdgeLength;
				float _TessMaxDisp;
			#endif
			CBUFFER_END

			CBUFFER_START(AvatarLightingPreFrame)
				half4 _MainLightPosition2;
				half4 _MainLightColor2;			// x,y,z : ��ʶ̫�������ɫ
				half _SliptEnvmentConfig;
			CBUFFER_END

			float4 GetMainLightDir()
			{
				return _MainLightColor2.a <= 0.001 ? _MainLightPosition : _MainLightPosition2;
			}

			float4 GetMainLightColor()
			{
				return _MainLightColor2.a <= 0.001 ? _MainLightColor : _MainLightColor2;
			}

			float GetEnvSplitFlag()
			{
				return _SliptEnvmentConfig;
			}
			

			
			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = defaultVertexValue;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					v.vertex.xyz = vertexValue;
				#else
					v.vertex.xyz += vertexValue;
				#endif

				v.ase_normal = v.ase_normal;

				float3 positionWS = TransformObjectToWorld( v.vertex.xyz );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				o.worldPos = positionWS;
				#endif

				o.clipPos = TransformWorldToHClip( positionWS );
				#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR) && defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					VertexPositionInputs vertexInput = (VertexPositionInputs)0;
					vertexInput.positionWS = positionWS;
					vertexInput.positionCS = o.clipPos;
					o.shadowCoord = GetShadowCoord( vertexInput );
				#endif
				return o;
			}

			#if defined(TESSELLATION_ON)
			struct VertexControl
			{
				float4 vertex : INTERNALTESSPOS;
				float3 ase_normal : NORMAL;
				
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct TessellationFactors
			{
				float edge[3] : SV_TessFactor;
				float inside : SV_InsideTessFactor;
			};

			VertexControl vert ( VertexInput v )
			{
				VertexControl o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				o.vertex = v.vertex;
				o.ase_normal = v.ase_normal;
				
				return o;
			}

			TessellationFactors TessellationFunction (InputPatch<VertexControl,3> v)
			{
				TessellationFactors o;
				float4 tf = 1;
				float tessValue = _TessValue; float tessMin = _TessMin; float tessMax = _TessMax;
				float edgeLength = _TessEdgeLength; float tessMaxDisp = _TessMaxDisp;
				#if defined(ASE_FIXED_TESSELLATION)
				tf = FixedTess( tessValue );
				#elif defined(ASE_DISTANCE_TESSELLATION)
				tf = DistanceBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, tessValue, tessMin, tessMax, GetObjectToWorldMatrix(), _WorldSpaceCameraPos );
				#elif defined(ASE_LENGTH_TESSELLATION)
				tf = EdgeLengthBasedTess(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams );
				#elif defined(ASE_LENGTH_CULL_TESSELLATION)
				tf = EdgeLengthBasedTessCull(v[0].vertex, v[1].vertex, v[2].vertex, edgeLength, tessMaxDisp, GetObjectToWorldMatrix(), _WorldSpaceCameraPos, _ScreenParams, unity_CameraWorldClipPlanes );
				#endif
				o.edge[0] = tf.x; o.edge[1] = tf.y; o.edge[2] = tf.z; o.inside = tf.w;
				return o;
			}

			[domain("tri")]
			[partitioning("fractional_odd")]
			[outputtopology("triangle_cw")]
			[patchconstantfunc("TessellationFunction")]
			[outputcontrolpoints(3)]
			VertexControl HullFunction(InputPatch<VertexControl, 3> patch, uint id : SV_OutputControlPointID)
			{
			   return patch[id];
			}

			[domain("tri")]
			VertexOutput DomainFunction(TessellationFactors factors, OutputPatch<VertexControl, 3> patch, float3 bary : SV_DomainLocation)
			{
				VertexInput o = (VertexInput) 0;
				o.vertex = patch[0].vertex * bary.x + patch[1].vertex * bary.y + patch[2].vertex * bary.z;
				o.ase_normal = patch[0].ase_normal * bary.x + patch[1].ase_normal * bary.y + patch[2].ase_normal * bary.z;
				
				#if defined(ASE_PHONG_TESSELLATION)
				float3 pp[3];
				for (int i = 0; i < 3; ++i)
					pp[i] = o.vertex.xyz - patch[i].ase_normal * (dot(o.vertex.xyz, patch[i].ase_normal) - dot(patch[i].vertex.xyz, patch[i].ase_normal));
				float phongStrength = _TessPhongStrength;
				o.vertex.xyz = phongStrength * (pp[0]*bary.x + pp[1]*bary.y + pp[2]*bary.z) + (1.0f-phongStrength) * o.vertex.xyz;
				#endif
				UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
				return VertexFunction(o);
			}
			#else
			VertexOutput vert ( VertexInput v )
			{
				return VertexFunction( v );
			}
			#endif

			half4 frag(VertexOutput IN  ) : SV_TARGET
			{
				UNITY_SETUP_INSTANCE_ID(IN);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX( IN );

				#if defined(ASE_NEEDS_FRAG_WORLD_POSITION)
				float3 WorldPosition = IN.worldPos;
				#endif
				float4 ShadowCoords = float4( 0, 0, 0, 0 );

				#if defined(ASE_NEEDS_FRAG_SHADOWCOORDS)
					#if defined(REQUIRES_VERTEX_SHADOW_COORD_INTERPOLATOR)
						ShadowCoords = IN.shadowCoord;
					#elif defined(MAIN_LIGHT_CALCULATE_SHADOWS)
						ShadowCoords = TransformWorldToShadowCoord( WorldPosition );
					#endif
				#endif

				
				float Alpha = 1;
				float AlphaClipThreshold = 0.5;

				#ifdef _ALPHATEST_ON
					clip(Alpha - AlphaClipThreshold);
				#endif

				#ifdef LOD_FADE_CROSSFADE
					LODDitheringTransition( IN.clipPos.xyz, unity_LODFade.x );
				#endif
				return 0;
			}
			ENDHLSL
		}

	
	}
	/*ase_lod*/
	CustomEditor "UnityEditor.ShaderGraph.PBRMasterGUI"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18912
26;205;2560;1057;1739.232;-213.4973;1;True;True
Node;AmplifyShaderEditor.CommentaryNode;101;-2415.928,-1778.199;Inherit;False;1849.716;529.4584;RampMask;21;106;109;115;117;114;98;97;108;107;105;104;102;116;100;103;96;99;110;111;112;113;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;6;-3859.691,1018.214;Inherit;False;2714.043;803.4395;matcap;24;79;73;70;66;54;41;38;36;35;33;30;28;26;24;23;22;21;18;17;12;10;9;8;13;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;133;-2698.242,1901.116;Inherit;False;1766.055;541.3859;RimLight;13;147;146;145;144;143;142;141;139;138;137;136;135;134;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;5;-2659.69,-101.786;Inherit;False;1291.941;1035.656;Specular;28;92;90;88;86;76;69;67;65;64;63;62;59;58;56;55;53;52;49;48;47;45;44;43;40;39;31;29;15;;1,1,1,1;0;0
Node;AmplifyShaderEditor.ColorNode;91;-1731.69,-1157.786;Inherit;False;Property;_DarkColor;DarkColor;5;0;Create;True;0;0;0;False;0;False;1,1,1,0;0.5896226,0.8573634,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;110;-1317.196,-1672.444;Inherit;False;Property;_ColorGamut;ColorGamut;18;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;95;-2467.69,-1189.786;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;69;-2083.69,490.2141;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;109;-1300.04,-1595.602;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;121;-439.6904,89.2141;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;98;-2177.25,-1446.096;Inherit;False;Property;_RampMaskRange;RampMaskRange;15;0;Create;True;0;0;0;False;0;False;0.8;0.8;0.1;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;60;-933.6904,-649.786;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.CustomExpressionNode;72;-1491.69,-757.7859;Inherit;False;float4 shadowCoord@$        #if SHADOWS_SCREEN$            shadowCoord = ComputeScreenPos(ClipSpacePos)@$        #else$            shadowCoord = TransformWorldToShadowCoord(WorldPos)@$        #endif$$        // 获取主光源$        Light light@$        #if _MAIN_LIGHT_SHADOWS_CASCADE || _MAIN_LIGHT_SHADOWS$            light = GetMainLight(shadowCoord)@$        #else$            light = GetMainLight()@$        #endif$$// 1. 采样静态阴影（Shadowmask）$float staticShadow = 1.0@  // 默认无静态阴影$#ifdef SHADOWS_SHADOWMASK$    // 静态阴影存储在unity_ShadowMask纹理中，主光源通常对应r通道$    float2 adjustedLightmapUV = lightmapUV * unity_LightmapST.xy + unity_LightmapST.zw@$    float4 shadowmask = SAMPLE_TEXTURE2D(unity_ShadowMask, samplerunity_ShadowMask, adjustedLightmapUV)@$    staticShadow = shadowmask.r@  // 取主光源的静态阴影衰减$#endif$$// 2. 计算动态与静态阴影的混合因子（基于距离）$float shadowMixFactor = GetMainLightShadowFade(WorldPos)@$float _ShadowDistance = GetMainLightShadowStrength()@$$// 3. 混合动态阴影和静态阴影（lerp(动态, 静态, 混合因子)）$float dynamicShadow = light.shadowAttenuation@  // 动态阴影衰减$finalShadow = lerp(dynamicShadow, staticShadow, shadowMixFactor)@$$// 4. 将混合后的阴影应用到卡通渐变$return IlluminationModel * finalShadow@;3;Create;5;True;ClipSpacePos;FLOAT3;0,0,0;In;;Inherit;False;True;WorldPos;FLOAT3;0,0,0;In;;Inherit;False;True;IlluminationModel;FLOAT;0;In;;Inherit;False;True;lightmapUV;FLOAT2;0,0;In;;Inherit;False;True;finalShadow;FLOAT;0;Out;;Inherit;False;ShadowMask;True;False;0;;False;5;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT;0;False;2;FLOAT3;0;FLOAT;5
Node;AmplifyShaderEditor.TextureCoordinatesNode;75;-1731.69,-421.786;Inherit;False;1;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;113;-1015.196,-1730.444;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;108;-1089.251,-1526.096;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;66;-1539.69,1098.214;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;26;-2259.69,1274.214;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldSpaceLightDirHlpNode;84;-3059.69,-405.7859;Inherit;False;True;1;0;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;77;-1763.69,-949.7859;Inherit;False;Property;_DarkColorPower;DarkColorPower;6;0;Create;True;0;0;0;False;0;False;1;1.32;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;87;-3011.69,-245.786;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;21;-1587.69,1370.214;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.UnpackScaleNormalNode;83;-2883.69,-757.7859;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;112;-1126.196,-1734.444;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;111;-1307.196,-1751.444;Inherit;False;Property;_Brightness;Brightness;19;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;80;-1491.69,-1093.786;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;22;-2083.69,1482.214;Inherit;False;Constant;_Float2;Float 2;46;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;86;-2099.69,554.214;Inherit;False;Property;_SpecularColor01;SpecularColor01;28;0;Create;True;0;0;0;False;0;False;0.6132076,0.6132076,0.6132076,0;0.490566,0.490566,0.490566,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.WorldPosInputsNode;81;-1715.69,-693.786;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;106;-1281.251,-1462.096;Inherit;False;Property;_Saturation;Saturation;17;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;92;-1875.69,90.214;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;97;-2241.25,-1510.096;Inherit;False;Constant;_Float4;Float 4;10;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;154;-345.4224,692.6882;Inherit;False;Property;_WidthScaleFix;WidthScaleFix;10;0;Create;True;0;0;0;False;0;False;0.05;0.05;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;61;-1100.331,-772.0132;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalizeNode;27;-2691.69,-277.7859;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;115;-977.2512,-1606.096;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;131;-3214.677,-900.2181;Inherit;True;Property;_Normalmap;Normalmap;20;1;[Header];Create;True;1;__________________Normal____________________________________________________________________________________________;0;0;False;0;False;-1;None;None;True;0;False;bump;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;151;-323.4224,559.6882;Inherit;False;2;0;FLOAT;1;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;105;-1525.435,-1360.59;Inherit;False;Property;_RampMaskIntensity;RampMaskIntensity;16;0;Create;True;0;0;0;False;0;False;1;1;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;149;-1066.919,-448.0251;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;163;-200.7461,1037.373;Inherit;False;Property;_OutlineZoffset;OutlineZoffset;13;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;104;-1585.251,-1571.096;Inherit;True;Property;_RampMask;RampMask;14;1;[Header];Create;True;1;__________________RampHSV____________________________________________________________________________________________;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;122;-559.6906,431.214;Inherit;False;Property;_OutlineWidth;OutlineWidth;9;1;[Header];Create;True;1;__________________Outline____________________________________________________________________________________________;0;0;False;0;False;0.1;0;0;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;76;-2579.69,794.214;Inherit;False;Property;_SpecularSoft02;SpecularSoft02;33;0;Create;True;0;0;0;False;0;False;50;2.5;0;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;89;-2563.69,-309.7859;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.HSVToRGBNode;117;-833.2512,-1606.096;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SaturateNode;116;-977.2512,-1526.096;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;70;-2083.69,1402.214;Inherit;False;Constant;_Float1;Float 1;46;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;119;-768.6906,119.2141;Inherit;False;Property;_OutlineColor;OutlineColor;11;0;Create;True;0;0;0;False;0;False;0.2075472,0.2075472,0.2075472,0;0.3396226,0.2791984,0.229085,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TransformPositionNode;157;-746.7461,916.3734;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceCameraPos;158;-833.7461,770.3734;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleSubtractOpNode;159;-545.7461,853.3734;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.NormalizeNode;160;-411.7461,851.3734;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.TransformDirectionNode;161;-273.7461,847.3734;Inherit;False;World;Object;True;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;162;-18.74609,885.3734;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.PosVertexDataNode;156;-927.7461,923.3734;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;90;-1731.69,138.214;Inherit;False;Property;_UseSpecular;UseSpecular;22;2;[Header];[Toggle];Create;True;1;__________________Specular____________________________________________________________________________________________;0;0;False;0;False;0;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;11;-1651.69,-549.786;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;67;-1603.69,442.2141;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;79;-1459.69,1338.214;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.UnityObjToClipPosHlpNode;82;-1987.69,-869.7859;Inherit;False;1;0;FLOAT3;0,0,0;False;5;FLOAT4;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;15;-1507.69,10.21402;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;120;-549.6906,201.2141;Inherit;False;Property;_OutlineColorBlendIntensity;OutlineColorBlendIntensity;12;0;Create;True;0;0;0;False;0;False;0;0.361;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;100;-2193.25,-1606.096;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;65;-2627.69,730.214;Inherit;False;Property;_SpecularMaskRange02;SpecularMaskRange02;32;0;Create;True;0;0;0;False;0;False;-0.1;-0.053;-1;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;64;-2643.69,506.2141;Inherit;False;Property;_SpecularMaskRange01;SpecularMaskRange01;29;0;Create;True;0;0;0;False;0;False;-0.2;-0.427;-1;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;74;-2179.69,-757.7859;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;56;-2339.69,-53.78598;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;127;-132.0175,367.7868;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;2;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ObjectScaleNode;150;-556.4224,602.6882;Inherit;False;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;24;-1875.69,1306.214;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;114;-1089.251,-1622.096;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;30;-2195.69,1130.214;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.NormalizeNode;20;-2659.69,-757.7859;Inherit;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;99;-2065.25,-1558.096;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;123;-341.6904,292.214;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;88;-2115.69,714.214;Inherit;False;Property;_SpecularColor02;SpecularColor02;31;0;Create;True;0;0;0;False;0;False;0.9150943,0.9150943,0.9150943,0;0.8679245,0.8679245,0.8679245,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;125;-277.6904,121.2141;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;54;-2035.69,1226.214;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;148;-223.1653,-1116.64;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;48;-1567.69,147.214;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;43;-1907.69,378.2141;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;142;-1725.564,1954.243;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;58;-2387.69,522.2141;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;73;-2547.69,1274.214;Inherit;False;Property;_MatcapPower2;MatcapPower;37;0;Create;False;0;0;0;False;0;False;1;0.98;0;14;0;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;102;-1905.251,-1544.096;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;25;-3187.69,-708.786;Inherit;False;Property;_NormalScale;NormalScale;21;0;Create;True;0;0;0;False;0;False;1;1;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;51;-1891.69,-549.786;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;29;-2243.69,538.214;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;63;-2627.69,602.2141;Inherit;False;Property;_SpecularSoft01;SpecularSoft01;30;0;Create;True;0;0;0;False;0;False;50;3.1;0;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;46;-1379.69,-485.7859;Inherit;False;FetchLightmapValue;0;;177;43de3d4ae59f645418fdd020d1b8e78e;0;0;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;155;-99.42236,563.6882;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;9;-1779.69,1466.214;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;52;-1891.69,762.214;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;55;-2613.69,-37.78598;Inherit;False;Property;_SpecularRange;SpecularRange;26;0;Create;True;0;0;0;False;0;False;-0.75;-0.505;-1;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;49;-2547.69,58.214;Inherit;False;Property;_SpecularSoft;SpecularSoft;27;0;Create;True;0;0;0;False;0;False;5;2.8;0;50;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;94;-2779.785,-992.6506;Inherit;False;Property;_ColorPower;ColorPower;4;0;Create;True;0;0;0;False;0;False;1;1;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;143;-1523.567,1957.243;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;147;-1842.564,2268.244;Inherit;False;Property;_RimLightSoft;RimLightSoft;41;0;Create;True;0;0;0;False;0;False;0.2;0.101;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;17;-2899.69,1098.214;Inherit;False;BentMatcapNormal;-1;;176;111106acccbe7a249888e78d98d12562;0;1;1;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;28;-2515.69,1066.214;Inherit;True;Property;_MatcapTex2;MatcapTex;35;1;[NoScaleOffset];Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;59;-1763.69,378.2141;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;33;-2067.69,1322.214;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;57;-2067.69,-437.786;Inherit;False;Property;_DarkSoft;DarkSoft;8;0;Create;True;0;0;0;False;0;False;0.1;0.16;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;38;-2659.69,1098.214;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;19;-2195.69,-533.786;Inherit;False;Property;_DarkRange;DarkRange;7;0;Create;True;0;0;0;False;0;False;1;0.052;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ComputeScreenPosHlpNode;71;-1779.69,-789.7859;Inherit;False;True;1;0;FLOAT4;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;35;-1827.69,1226.214;Inherit;False;Property;_MatcapBlend2;MatcapBlend;38;0;Create;False;0;0;0;False;0;False;1;0.434;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;134;-1336.566,2046.244;Inherit;False;Property;_RimLightColor;RimLightColor;39;1;[Header];Create;True;2;__________________RimLight____________________________________________________________________________________________;;0;0;False;0;False;0,0,0,0;0.4708971,0.6365787,0.6981132,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;96;-2337.25,-1590.096;Inherit;False;Constant;_Float6;Float 6;48;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;36;-1923.69,1098.214;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;47;-2216.69,292.2141;Inherit;True;Property;_SpecularMask2;SpecularMask(G);24;0;Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleDivideOpNode;50;-1763.69,-549.786;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;118;-530.1321,-1195.44;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;146;-2612.962,2164.973;Inherit;False;Property;_RimOffset;RimOffset;42;0;Create;True;0;0;0;False;0;False;0.16;0.19;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;16;-1139.69,-581.786;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;40;-1651.69,650.214;Inherit;False;Property;_SpecularPower;SpecularPower;23;0;Create;True;0;0;0;False;0;False;1;0.82;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;124;-286.6904,436.214;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1000;False;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;8;-1923.69,1466.214;Inherit;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0.5;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;153;-547.4224,513.6882;Inherit;False;Constant;_Float3;Float 3;41;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;45;-2259.69,778.214;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;145;-1307.465,1958.375;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;12;-1779.69,1114.214;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;31;-2355.69,698.214;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;138;-2163.564,1957.243;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;53;-2019.69,-21.78598;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;126;-117.6905,121.2141;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;107;-1137.251,-1398.096;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;10;-2739.69,1194.214;Inherit;False;Property;_MatcapColor2;MatcapColor;36;0;Create;False;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LightColorNode;68;-1315.69,-597.786;Inherit;False;0;3;COLOR;0;FLOAT3;1;FLOAT;2
Node;AmplifyShaderEditor.OneMinusNode;41;-1747.69,1306.214;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;39;-2163.69,90.214;Inherit;False;Property;_SpecularColor;SpecularColor;25;0;Create;True;0;0;0;False;0;False;0.2358491,0.2358491,0.2358491,0;0.2264151,0.2264151,0.2264151,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;103;-1729.251,-1544.096;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.01;False;2;FLOAT;0.99;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;34;-2792.244,-1185.489;Inherit;True;Property;_BaseTex;BaseTex;2;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;93;-2744.244,-1345.489;Inherit;False;Property;_BaseColor;BaseColor;3;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleAddOpNode;144;-1939.698,2042.309;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;23;-1379.69,1066.214;Inherit;False;Property;_UseMatcap;UseMatcap;34;0;Create;True;0;0;0;False;1;Header(___________________Matcap_________________________________________________________________________________________________);False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;62;-2179.69,-37.78598;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;135;-2197.564,2211.244;Inherit;False;Property;_RimLightRange;RimLightRange;40;0;Create;True;0;0;0;False;0;False;0.9;0.984;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;18;-2467.69,1354.214;Inherit;False;Constant;_Float0;Float 0;57;0;Create;True;0;0;0;False;0;False;0.4;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;136;-1409.17,2406.187;Inherit;False;Property;_RimPower;RimPower;43;0;Create;True;0;0;0;False;0;False;1;1;0;20;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;164;91.25391,527.3734;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;141;-2447.154,2031.038;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.OneMinusNode;132;-1017.068,-954.8338;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;85;-2435.69,-757.7859;Inherit;False;True;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;42;-2835.69,-293.7859;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;139;-2646.475,2015.776;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TransformDirectionNode;13;-3120.824,1093.497;Inherit;False;Tangent;World;True;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;44;-1875.69,538.214;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;137;-1119.47,2009.643;Inherit;False;3;3;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;4;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;0;71.47522,114.8177;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=SRPDefaultUnlit;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;1;89.30512,-874.9081;Float;False;True;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;Douyin/AI/Cartoon/ItemNPR_AIHaiHai;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;8;d3d9;d3d11_9x;d3d11;glcore;gles;gles3;metal;vulkan;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;True;-8;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;1;LOD CrossFade;0;Built-in Fog;1;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;1;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;True;True;True;True;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;2;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;3;0,0;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;1;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;95;0;93;0
WireConnection;95;1;34;0
WireConnection;95;2;94;0
WireConnection;69;0;29;0
WireConnection;109;0;60;0
WireConnection;121;0;95;0
WireConnection;121;1;119;0
WireConnection;60;0;61;0
WireConnection;60;1;16;0
WireConnection;72;0;71;0
WireConnection;72;1;81;0
WireConnection;72;2;11;0
WireConnection;72;3;75;0
WireConnection;113;0;112;0
WireConnection;108;0;109;2
WireConnection;108;1;106;0
WireConnection;66;0;95;0
WireConnection;66;1;79;0
WireConnection;66;2;35;0
WireConnection;26;0;73;0
WireConnection;26;1;18;0
WireConnection;21;0;41;0
WireConnection;21;1;9;0
WireConnection;83;0;131;0
WireConnection;83;1;25;0
WireConnection;112;0;111;0
WireConnection;112;1;109;3
WireConnection;80;0;23;0
WireConnection;80;1;91;0
WireConnection;80;2;77;0
WireConnection;92;0;53;0
WireConnection;92;1;39;0
WireConnection;92;2;47;2
WireConnection;61;0;80;0
WireConnection;61;1;15;0
WireConnection;61;2;149;0
WireConnection;27;0;42;0
WireConnection;115;0;114;0
WireConnection;151;0;153;0
WireConnection;151;1;150;0
WireConnection;149;0;72;5
WireConnection;149;1;11;0
WireConnection;104;1;103;0
WireConnection;89;0;85;0
WireConnection;89;1;27;0
WireConnection;117;0;115;0
WireConnection;117;1;116;0
WireConnection;117;2;113;0
WireConnection;116;0;108;0
WireConnection;157;0;156;0
WireConnection;159;0;158;0
WireConnection;159;1;157;0
WireConnection;160;0;159;0
WireConnection;161;0;160;0
WireConnection;162;0;161;0
WireConnection;162;1;163;0
WireConnection;11;0;50;0
WireConnection;67;0;59;0
WireConnection;67;1;88;0
WireConnection;67;2;44;0
WireConnection;79;0;12;0
WireConnection;79;1;21;0
WireConnection;15;0;23;0
WireConnection;15;1;48;0
WireConnection;100;0;74;0
WireConnection;100;1;96;0
WireConnection;74;0;85;0
WireConnection;74;1;84;0
WireConnection;56;0;89;0
WireConnection;56;1;55;0
WireConnection;127;0;123;0
WireConnection;127;1;124;0
WireConnection;127;2;155;0
WireConnection;24;0;54;0
WireConnection;24;1;33;0
WireConnection;24;2;70;0
WireConnection;114;0;109;1
WireConnection;114;1;110;0
WireConnection;30;0;28;0
WireConnection;30;1;10;0
WireConnection;30;2;26;0
WireConnection;20;0;83;0
WireConnection;99;0;100;0
WireConnection;99;1;97;0
WireConnection;125;0;121;0
WireConnection;125;1;119;0
WireConnection;125;2;120;0
WireConnection;54;0;95;0
WireConnection;148;0;118;0
WireConnection;148;1;137;0
WireConnection;48;0;90;0
WireConnection;48;1;67;0
WireConnection;48;2;40;0
WireConnection;43;0;47;2
WireConnection;43;1;69;0
WireConnection;142;0;144;0
WireConnection;58;0;56;0
WireConnection;58;1;64;0
WireConnection;102;0;99;0
WireConnection;102;1;98;0
WireConnection;51;0;74;0
WireConnection;51;1;19;0
WireConnection;29;0;58;0
WireConnection;29;1;63;0
WireConnection;155;0;151;0
WireConnection;155;1;154;0
WireConnection;9;0;8;0
WireConnection;52;0;45;0
WireConnection;143;0;142;0
WireConnection;143;1;147;0
WireConnection;17;1;13;0
WireConnection;28;1;38;0
WireConnection;59;0;92;0
WireConnection;59;1;86;0
WireConnection;59;2;43;0
WireConnection;33;0;30;0
WireConnection;38;0;17;0
WireConnection;71;0;82;0
WireConnection;36;0;95;0
WireConnection;36;1;30;0
WireConnection;36;2;70;0
WireConnection;50;0;51;0
WireConnection;50;1;57;0
WireConnection;118;0;60;0
WireConnection;118;1;117;0
WireConnection;118;2;132;0
WireConnection;16;0;68;1
WireConnection;16;1;46;0
WireConnection;124;0;122;0
WireConnection;8;0;30;0
WireConnection;8;1;22;0
WireConnection;45;0;31;0
WireConnection;45;1;76;0
WireConnection;145;0;143;0
WireConnection;12;0;36;0
WireConnection;12;1;8;0
WireConnection;31;0;58;0
WireConnection;31;1;65;0
WireConnection;138;0;85;0
WireConnection;138;1;141;0
WireConnection;53;0;62;0
WireConnection;126;0;125;0
WireConnection;107;0;104;1
WireConnection;107;1;105;0
WireConnection;41;0;24;0
WireConnection;103;0;102;0
WireConnection;144;0;138;0
WireConnection;144;1;135;0
WireConnection;23;1;95;0
WireConnection;23;0;66;0
WireConnection;62;0;56;0
WireConnection;62;1;49;0
WireConnection;164;0;127;0
WireConnection;164;1;162;0
WireConnection;141;0;139;0
WireConnection;141;2;146;0
WireConnection;132;0;149;0
WireConnection;85;0;20;0
WireConnection;42;0;84;0
WireConnection;42;1;87;0
WireConnection;13;0;20;0
WireConnection;44;0;47;2
WireConnection;44;1;52;0
WireConnection;137;0;145;0
WireConnection;137;1;134;0
WireConnection;137;2;136;0
WireConnection;0;0;126;0
WireConnection;0;3;164;0
WireConnection;1;2;148;0
ASEEND*/
//CHKSM=39FF4FD3D8C0B04D94F0D03E260CF3BB6C0E334B