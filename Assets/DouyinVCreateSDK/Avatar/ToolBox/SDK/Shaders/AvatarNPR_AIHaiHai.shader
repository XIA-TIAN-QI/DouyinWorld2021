// Made with Amplify Shader Editor
// Available at the Unity Asset Store - http://u3d.as/y3X 
Shader "Douyin/AI/Cartoon/AvatarNPR_AIHaiHai"
{
	Properties
	{
		[HideInInspector] _EmissionColor("Emission Color", Color) = (1,1,1,1)
		[HideInInspector] _AlphaCutoff("Alpha Cutoff ", Range(0, 1)) = 0.5
		[HideInInspector][Toggle(_ALPHAACTOR_ON)] _ALPHAACTOR("_ALPHAACTOR", Float) = 0
		[HideInInspector]_ActorRadius("ActorRadius", Range( 0 , 1)) = 0.4
		[Header(___________________BaseTex____________________________________________________________________________________________)]_BaseTex("BaseTex", 2D) = "white" {}
		_BaseColor("BaseColor", Color) = (1,1,1,0)
		_ColorPower("ColorPower", Range( 0 , 20)) = 1
		_DarkColor("DarkColor", Color) = (0.9056604,0.8330367,0.8330367,0)
		_DarkRange("DarkRange", Range( -1 , 1)) = 0.2
		_DarkSoft("DarkSoft", Range( 0 , 5)) = 0.1
		_VertexColorAlphaFixDarkRange("VertexColorAlphaFixDarkRange", Range( 0 , 1)) = 0
		[Toggle]_UseLUT("UseLUT", Float) = 0
		_LutTexture("LutTexture", 2D) = "white" {}
		_LutBrightnessFix("LutBrightnessFix", Float) = 0.98
		[Header(___________________SequentialTex____________________________________________________________________________________________)][Toggle]_UseExpression("UseExpression", Float) = 0
		[Toggle]_UseSequential("UseSequential", Float) = 0
		_SequentialTex("SequentialTex", 2D) = "white" {}
		_Colums("Colums", Float) = 4
		_Rows("Rows", Float) = 4
		_StartFrame("StartFrame", Float) = 0
		_FrameSpeed("FrameSpeed", Float) = 1
		[Toggle]_UseSetKey("UseSetKey", Float) = 0
		_SetKey("SetKey", Float) = 0
		[Header(__________________Outline____________________________________________________________________________________________)]_OutlineColor("OutlineColor", Color) = (0.2075472,0.2075472,0.2075472,0)
		_OutlineColorBlendIntensity("OutlineColorBlendIntensity", Range( 0 , 1)) = 0
		_OutlineWidth("OutlineWidth", Range( 0 , 100)) = 0.1
		_OutlineZoffset("OutlineZoffset", Float) = 0
		[Header(__________________Normalmap____________________________________________________________________________________________)][Normal]_Normalmap("Normalmap", 2D) = "bump" {}
		_NormalIntensity("NormalIntensity", Range( 0 , 10)) = 1
		[Header(__________________Ramp____________________________________________________________________________________________)][NoScaleOffset]_RampTex("RampTex", 2D) = "white" {}
		_RampColor("RampColor", Color) = (1,1,1,0)
		_RampRange("RampRange", Range( 0.1 , 5)) = 0.8
		_RampBlend("RampBlend", Range( 0 , 1)) = 1
		[Header(__________________RampHSV____________________________________________________________________________________________)]_RampMask("RampMask", 2D) = "white" {}
		_RampMaskRange("RampMaskRange", Range( 0.1 , 5)) = 0.8
		_RampMaskIntensity("RampMaskIntensity", Range( 0 , 10)) = 1
		_ColorGamut("ColorGamut", Float) = 0
		_Saturation("Saturation", Float) = 0
		_Brightness("Brightness", Float) = 0
		[Header(__________________ShadowMask____________________________________________________________________________________________)][Toggle(_USESHADOWMASK_ON)] _UseShadowMask("UseShadowMask", Float) = 0
		_ShadowMask("ShadowMask(R)", 2D) = "black" {}
		[Toggle(_FILPSHADOWMASK_ON)] _FilpShadowMask("FlipShadowMask", Float) = 0
		_ShadowMaskPower("ShadowMaskPower", Range( 0 , 5)) = 1
		[Header(___________________Matcap_________________________________________________________________________________________________)][Toggle(_USEMATCAP_ON)] _UseMatcap("UseMatcap", Float) = 0
		[NoScaleOffset]_MatcapTex("MatcapTex", 2D) = "white" {}
		_MatcapColor("MatcapColor", Color) = (1,1,1,0)
		_MatcapPower("MatcapPower", Range( 0 , 35)) = 1
		_MatcapBlend("MatcapBlend", Range( 0 , 10)) = 1
		_MatcapMask("MatcapMask(R)", 2D) = "white" {}
		[Header(__________________Emissive____________________________________________________________________________________________)]_EmissiveTex("EmissiveTex", 2D) = "black" {}
		_EmissiveColor("EmissiveColor", Color) = (1,1,1,1)
		_EmissivePower("EmissivePower", Range( 0 , 20)) = 1
		[NoScaleOffset]_EmissiveBlendTex("EmissiveBlendTex", 2D) = "white" {}
		_EmiBlendTiling("EmiBlendTiling", Vector) = (1,1,0,0)
		_EmiBlendSpeed("EmiBlendSpeed", Vector) = (0,0,0,0)
		[Header(__________________Specular____________________________________________________________________________________________)][Toggle(_USESPECULAR_ON)] _UseSpecular("UseSpecular", Float) = 0
		_SpecularMask("SpecularMask(G)", 2D) = "white" {}
		_SpecularColor("SpecularColor", Color) = (1,1,1,0)
		_SpecularRange("SpecularRange", Range( -1 , 0)) = -0.75
		_SpecularSoft("SpecularSoft", Range( 0 , 50)) = 5
		_SpecularPower("SpecularPower", Range( 0 , 3)) = 1
		_SpecularColor01("SpecularColor01", Color) = (0,0,0,0)
		_SpecularMaskRange01("SpecularMaskRange01", Range( -1 , 0)) = -0.2
		_SpecularSoft01("SpecularSoft01", Range( 0 , 100)) = 50
		_SpecularColor02("SpecularColor02", Color) = (0,0,0,0)
		_SpecularMaskRange02("SpecularMaskRange02", Range( -1 , 0)) = -0.1
		_SpecularSoft02("SpecularSoft02", Range( 0 , 100)) = 50
		[Header(__________________RimLight____________________________________________________________________________________________)]_RimMask("RimMask(B)", 2D) = "white" {}
		_RimLightColor("RimLightColor", Color) = (0,0,0,0)
		_RimLightRange("RimLightRange", Range( 0 , 2)) = 0.9
		_RimLightSoft("RimLightSoft", Range( 0 , 5)) = 0.2
		_RimOffset("RimOffset", Float) = 0.16
		_RimPower("RimPower", Range( 0 , 20)) = 1
		[HideInInspector] _texcoord( "", 2D ) = "white" {}

		//_TessPhongStrength( "Tess Phong Strength", Range( 0, 1 ) ) = 0.5
		//_TessValue( "Tess Max Tessellation", Range( 1, 32 ) ) = 16
		//_TessMin( "Tess Min Distance", Float ) = 10
		//_TessMax( "Tess Max Distance", Float ) = 25
		//_TessEdgeLength ( "Tess Edge length", Range( 2, 50 ) ) = 16
		//_TessMaxDisp( "Tess Max Displacement", Float ) = 25

		[HideInInspector] _CullMode("Cull Mode", Float) = 2
		[HideInInspector] _GpuSkinningBoneTexture("GPU Skinning Bone Texture", 2D) = "black" {}
		[HideInInspector] _GpuSkinningBoneTextureSize("GPU Skinning Bone Texture Size", Vector) = (0.33333334,1,3,1)
		[HideInInspector] _GpuSkinningBoneOffset("GPU Skinning Bone Offset", Float) = 0
		[HideInInspector] _GpuSkinningWeightCount("GPU Skinning Weight Count", Float) = 4
	}

	SubShader
	{
		LOD 500

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		
		Cull Back
		AlphaToMask On
		HLSLINCLUDE
		#pragma target 3.0

		#pragma prefer_hlslcc gles
		#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal vulkan 
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
			Tags { "LightMode"="AvatarOutline" "RenderType"="Opaque" "Queue"="AlphaTest" }
			
			Blend One Zero
			Cull Front
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			

			HLSLPROGRAM
			#pragma multi_compile_local _ HAMLET_GPU_SKINNING
			
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

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_VERT_POSITION
			#pragma multi_compile __ _ALPHAACTOR_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 hamlet_gpu_boneWeights : BLENDWEIGHTS;
				uint4 hamlet_gpu_boneIndices : BLENDINDICES;
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
				float4 ase_texcoord4 : TEXCOORD4;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _GpuSkinningBoneTextureSize;
			float _GpuSkinningBoneOffset;
			float _GpuSkinningWeightCount;
			float4 _BaseTex_ST;
			float4 _RimLightColor;
			float4 _SpecularColor02;
			float4 _SpecularColor01;
			float4 _SpecularMask_ST;
			float4 _SpecularColor;
			float4 _MatcapMask_ST;
			float4 _MatcapColor;
			float4 _RampColor;
			float4 _RimMask_ST;
			float4 _OutlineColor;
			float4 _Normalmap_ST;
			float4 _BaseColor;
			float4 _DarkColor;
			float4 _ShadowMask_ST;
			float4 _EmissiveTex_ST;
			float4 _EmissiveColor;
			float2 _EmiBlendSpeed;
			float2 _EmiBlendTiling;
			float _StartFrame;
			float _SpecularRange;
			float _SpecularSoft;
			float _SpecularPower;
			float _SpecularMaskRange01;
			float _SpecularSoft01;
			float _SpecularMaskRange02;
			float _ColorGamut;
			float _Saturation;
			float _Brightness;
			float _RampMaskRange;
			float _RampMaskIntensity;
			float _RimOffset;
			float _RimLightRange;
			float _RimLightSoft;
			float _SpecularSoft02;
			float _MatcapBlend;
			float _MatcapPower;
			float _RampBlend;
			float _SetKey;
			float _UseSetKey;
			float _DarkRange;
			float _UseExpression;
			float _UseLUT;
			float _LutBrightnessFix;
			float _VertexColorAlphaFixDarkRange;
			float _DarkSoft;
			float _ShadowMaskPower;
			float _FrameSpeed;
			float _EmissivePower;
			float _ActorRadius;
			float _OutlineWidth;
			float _OutlineZoffset;
			float _Rows;
			float _OutlineColorBlendIntensity;
			float _Colums;
			float _NormalIntensity;
			float _RampRange;
			float _ColorPower;
			float _UseSequential;
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
			#include "HamletGpuSkinning.hlsl"

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
			sampler2D _SequentialTex;
			sampler2D _LutTexture;


			real3 ASESafeNormalize(float3 inVec)
			{
				real dp3 = max(FLT_MIN, dot(inVec, inVec));
				return inVec* rsqrt( dp3);
			}
			
			float4 MyCustomExpression1035( float4 Texcolor, sampler2D LutTex, float _BrightnessCompensation, float _LutEnable )
			{
				// 采样原图
				float4 col = Texcolor;
				// 初始化最终颜色（默认返回原图，开关为1时再替换为校色后颜色）
				float3 finalColor = col.rgb;
				// 仅当开关为1时，执行LUT校色逻辑（开关为0时跳过，直接输出原图）
				if (_LutEnable > 0.5) 
				{
				    // 通道映射（R→U, G→V, B→W）
				    float u = col.r;
				    float v = col.g;
				    float w = col.b;
				    // LUT采样计算
				    const int LUT_SIZE = 16;
				    float scaleZ = LUT_SIZE - 1.0;
				    // 安全边界处理
				    float halfPixel = 0.5 / (LUT_SIZE * LUT_SIZE);
				    float maxSafeU = 1.0 - (1.0 / LUT_SIZE) - halfPixel;
				    u = saturate(u);
				    u = min(u, maxSafeU);
				    v = saturate(v);
				    v = clamp(v, halfPixel, 1.0 - halfPixel);
				    w = saturate(w);
				    // 计算LUT坐标
				    w *= scaleZ;
				    float stripIndex = floor(w);
				    stripIndex = clamp(stripIndex, 0.0, LUT_SIZE - 1.0);
				    float stripOffset = stripIndex * LUT_SIZE;
				    // 当前条带采样坐标
				    float x = (stripOffset + u * LUT_SIZE) / (LUT_SIZE * LUT_SIZE);
				    x = clamp(x, stripOffset / (LUT_SIZE * LUT_SIZE) + halfPixel, 
				              (stripOffset + LUT_SIZE) / (LUT_SIZE * LUT_SIZE) - halfPixel);
				    float y = v;
				    // 下一条带采样坐标（用于插值）
				    float nextStripIndex = min(stripIndex + 1.0, LUT_SIZE - 1.0);
				    float nextStripOffset = nextStripIndex * LUT_SIZE;
				    float x2 = (nextStripOffset + u * LUT_SIZE) / (LUT_SIZE * LUT_SIZE);
				    x2 = clamp(x2, nextStripOffset / (LUT_SIZE * LUT_SIZE) + halfPixel, 
				               (nextStripOffset + LUT_SIZE) / (LUT_SIZE * LUT_SIZE) - halfPixel);
				    // LUT双线性插值采样
				    float4 color1 = tex2D(LutTex, float2(x, y));
				    float4 color2 = tex2D(LutTex, float2(x2, y));
				    float t = saturate(w - stripIndex);
				    float4 correctedColor = lerp(color1, color2, t);
				    // 亮度补偿（仅校色时生效）
				    finalColor = correctedColor.rgb * _BrightnessCompensation;
				    // 颜色范围钳位（仅校色时生效）
				    finalColor.r = clamp(finalColor.r, 0.0, 1.0);
				    finalColor.g = clamp(finalColor.g, 0.0, 1.0);
				    finalColor.b = clamp(finalColor.b, 0.0, 1.0);
				}
				// 输出最终颜色（开关0=原图，1=校色后；始终保留原图Alpha）
				return float4(finalColor, col.a);
			}
			

			VertexOutput VertexFunction( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				#if defined(HAMLET_GPU_SKINNING)
				HamletApplyGpuSkinning(v.vertex, v.ase_normal, v.hamlet_gpu_boneWeights, v.hamlet_gpu_boneIndices);
				#endif

				float3 objToWorld1120 = mul( GetObjectToWorldMatrix(), float4( v.vertex.xyz, 1 ) ).xyz;
				float3 normalizeResult1121 = ASESafeNormalize( ( _WorldSpaceCameraPos - objToWorld1120 ) );
				float3 worldToObjDir1127 = normalize( mul( GetWorldToObjectMatrix(), float4( normalizeResult1121, 0 ) ).xyz );
				
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord4 = screenPos;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				#ifdef ASE_ABSOLUTE_VERTEX_POS
					float3 defaultVertexValue = v.vertex.xyz;
				#else
					float3 defaultVertexValue = float3(0, 0, 0);
				#endif
				float3 vertexValue = ( ( v.ase_normal * ( _OutlineWidth / 1000.0 ) ) + ( worldToObjDir1127 * _OutlineZoffset ) );
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
				float4 temp_output_1030_0 = saturate( ( tex2D( _BaseTex, uv_BaseTex ) * _BaseColor * _ColorPower ) );
				float2 appendResult1083 = (float2(_Colums , _Rows));
				float totalFrames1084 = ( _Colums * _Rows );
				float2 appendResult1075 = (float2(totalFrames1084 , _Rows));
				float mulTime1081 = _TimeParameters.x * _FrameSpeed;
				float clampResult1072 = clamp( _StartFrame , 0.0001 , ( totalFrames1084 - 1.0 ) );
				float lerpResult1094 = lerp( ( mulTime1081 + clampResult1072 ) , ( ( _SetKey - 1.0 ) + 0.1 ) , _UseSetKey);
				float temp_output_1077_0 = frac( ( lerpResult1094 / totalFrames1084 ) );
				float2 appendResult1068 = (float2(temp_output_1077_0 , ( 1.0 - temp_output_1077_0 )));
				float4 lerpResult1128 = lerp( temp_output_1030_0 , tex2D( _SequentialTex, ( ( IN.ase_texcoord3.xy / appendResult1083 ) + ( floor( ( appendResult1075 * appendResult1068 ) ) / appendResult1083 ) ) ) , _UseSequential);
				float4 lerpResult1132 = lerp( temp_output_1030_0 , lerpResult1128 , _UseExpression);
				float3 linearToGamma1028 = FastLinearToSRGB( lerpResult1132.rgb );
				float4 Texcolor1035 = float4( linearToGamma1028 , 0.0 );
				sampler2D LutTex1035 = _LutTexture;
				float _BrightnessCompensation1035 = _LutBrightnessFix;
				float _LutEnable1035 = _UseLUT;
				float4 localMyCustomExpression1035 = MyCustomExpression1035( Texcolor1035 , LutTex1035 , _BrightnessCompensation1035 , _LutEnable1035 );
				float3 gammaToLinear1027 = FastSRGBToLinear( localMyCustomExpression1035.xyz );
				float4 lerpResult977 = lerp( ( float4( gammaToLinear1027 , 0.0 ) * _OutlineColor ) , _OutlineColor , _OutlineColorBlendIntensity);
				
				float4 screenPos = IN.ase_texcoord4;
				float2 appendResult5_g229 = (float2(_ScreenParams.x , _ScreenParams.y));
				float smoothstepResult21_g229 = smoothstep( ( _ActorRadius - 0.2 ) , _ActorRadius , length( ( frac( ( ( (screenPos).xy / screenPos.w ) * appendResult5_g229 * float2( 0.25,0.25 ) ) ) - float2( 0.5,0.5 ) ) ));
				#ifdef _ALPHAACTOR_ON
				float staticSwitch13_g229 = ( 1.0 - smoothstepResult21_g229 );
				#else
				float staticSwitch13_g229 = 1.0;
				#endif
				float temp_output_854_0 = staticSwitch13_g229;
				
				float3 Color = saturate( lerpResult977 ).rgb;
				float Alpha = temp_output_854_0;
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
			Tags { "LightMode"="UniversalForward" "RenderPipeline"="UniversalRenderPipeline" "RenderType"="Opaque" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			Cull [_CullMode]
			

			HLSLPROGRAM
			#pragma multi_compile_local _ HAMLET_GPU_SKINNING

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

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#define ASE_NEEDS_VERT_NORMAL
			#define ASE_NEEDS_FRAG_WORLD_POSITION
			#pragma shader_feature_local _USESPECULAR_ON
			#pragma shader_feature _USEMATCAP_ON
			#pragma shader_feature_local _USESHADOWMASK_ON
			#pragma shader_feature_local _FILPSHADOWMASK_ON
			#pragma multi_compile __ _ALPHAACTOR_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 hamlet_gpu_boneWeights : BLENDWEIGHTS;
				uint4 hamlet_gpu_boneIndices : BLENDINDICES;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_tangent : TANGENT;
				float4 ase_color : COLOR;
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
				float4 ase_color : COLOR;
				float4 ase_texcoord7 : TEXCOORD7;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _GpuSkinningBoneTextureSize;
			float _GpuSkinningBoneOffset;
			float _GpuSkinningWeightCount;
			float4 _BaseTex_ST;
			float4 _RimLightColor;
			float4 _SpecularColor02;
			float4 _SpecularColor01;
			float4 _SpecularMask_ST;
			float4 _SpecularColor;
			float4 _MatcapMask_ST;
			float4 _MatcapColor;
			float4 _RampColor;
			float4 _RimMask_ST;
			float4 _OutlineColor;
			float4 _Normalmap_ST;
			float4 _BaseColor;
			float4 _DarkColor;
			float4 _ShadowMask_ST;
			float4 _EmissiveTex_ST;
			float4 _EmissiveColor;
			float2 _EmiBlendSpeed;
			float2 _EmiBlendTiling;
			float _StartFrame;
			float _SpecularRange;
			float _SpecularSoft;
			float _SpecularPower;
			float _SpecularMaskRange01;
			float _SpecularSoft01;
			float _SpecularMaskRange02;
			float _ColorGamut;
			float _Saturation;
			float _Brightness;
			float _RampMaskRange;
			float _RampMaskIntensity;
			float _RimOffset;
			float _RimLightRange;
			float _RimLightSoft;
			float _SpecularSoft02;
			float _MatcapBlend;
			float _MatcapPower;
			float _RampBlend;
			float _SetKey;
			float _UseSetKey;
			float _DarkRange;
			float _UseExpression;
			float _UseLUT;
			float _LutBrightnessFix;
			float _VertexColorAlphaFixDarkRange;
			float _DarkSoft;
			float _ShadowMaskPower;
			float _FrameSpeed;
			float _EmissivePower;
			float _ActorRadius;
			float _OutlineWidth;
			float _OutlineZoffset;
			float _Rows;
			float _OutlineColorBlendIntensity;
			float _Colums;
			float _NormalIntensity;
			float _RampRange;
			float _ColorPower;
			float _UseSequential;
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
			#include "HamletGpuSkinning.hlsl"

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
			sampler2D _EmissiveTex;
			sampler2D _EmissiveBlendTex;
			sampler2D _RampTex;
			sampler2D _Normalmap;
			sampler2D _BaseTex;
			sampler2D _SequentialTex;
			sampler2D _LutTexture;
			sampler2D _MatcapTex;
			sampler2D _MatcapMask;
			sampler2D _SpecularMask;
			sampler2D _RampMask;
			sampler2D _ShadowMask;
			sampler2D _RimMask;


			float4 MyCustomExpression1035( float4 Texcolor, sampler2D LutTex, float _BrightnessCompensation, float _LutEnable )
			{
				// 采样原图
				float4 col = Texcolor;
				// 初始化最终颜色（默认返回原图，开关为1时再替换为校色后颜色）
				float3 finalColor = col.rgb;
				// 仅当开关为1时，执行LUT校色逻辑（开关为0时跳过，直接输出原图）
				if (_LutEnable > 0.5) 
				{
				    // 通道映射（R→U, G→V, B→W）
				    float u = col.r;
				    float v = col.g;
				    float w = col.b;
				    // LUT采样计算
				    const int LUT_SIZE = 16;
				    float scaleZ = LUT_SIZE - 1.0;
				    // 安全边界处理
				    float halfPixel = 0.5 / (LUT_SIZE * LUT_SIZE);
				    float maxSafeU = 1.0 - (1.0 / LUT_SIZE) - halfPixel;
				    u = saturate(u);
				    u = min(u, maxSafeU);
				    v = saturate(v);
				    v = clamp(v, halfPixel, 1.0 - halfPixel);
				    w = saturate(w);
				    // 计算LUT坐标
				    w *= scaleZ;
				    float stripIndex = floor(w);
				    stripIndex = clamp(stripIndex, 0.0, LUT_SIZE - 1.0);
				    float stripOffset = stripIndex * LUT_SIZE;
				    // 当前条带采样坐标
				    float x = (stripOffset + u * LUT_SIZE) / (LUT_SIZE * LUT_SIZE);
				    x = clamp(x, stripOffset / (LUT_SIZE * LUT_SIZE) + halfPixel, 
				              (stripOffset + LUT_SIZE) / (LUT_SIZE * LUT_SIZE) - halfPixel);
				    float y = v;
				    // 下一条带采样坐标（用于插值）
				    float nextStripIndex = min(stripIndex + 1.0, LUT_SIZE - 1.0);
				    float nextStripOffset = nextStripIndex * LUT_SIZE;
				    float x2 = (nextStripOffset + u * LUT_SIZE) / (LUT_SIZE * LUT_SIZE);
				    x2 = clamp(x2, nextStripOffset / (LUT_SIZE * LUT_SIZE) + halfPixel, 
				               (nextStripOffset + LUT_SIZE) / (LUT_SIZE * LUT_SIZE) - halfPixel);
				    // LUT双线性插值采样
				    float4 color1 = tex2D(LutTex, float2(x, y));
				    float4 color2 = tex2D(LutTex, float2(x2, y));
				    float t = saturate(w - stripIndex);
				    float4 correctedColor = lerp(color1, color2, t);
				    // 亮度补偿（仅校色时生效）
				    finalColor = correctedColor.rgb * _BrightnessCompensation;
				    // 颜色范围钳位（仅校色时生效）
				    finalColor.r = clamp(finalColor.r, 0.0, 1.0);
				    finalColor.g = clamp(finalColor.g, 0.0, 1.0);
				    finalColor.b = clamp(finalColor.b, 0.0, 1.0);
				}
				// 输出最终颜色（开关0=原图，1=校色后；始终保留原图Alpha）
				return float4(finalColor, col.a);
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

				#if defined(HAMLET_GPU_SKINNING)
				HamletApplyGpuSkinning(v.vertex, v.ase_normal, v.ase_tangent, v.hamlet_gpu_boneWeights, v.hamlet_gpu_boneIndices);
				#endif

				float3 ase_worldTangent = TransformObjectToWorldDir(v.ase_tangent.xyz);
				o.ase_texcoord4.xyz = ase_worldTangent;
				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord5.xyz = ase_worldNormal;
				float ase_vertexTangentSign = v.ase_tangent.w * unity_WorldTransformParams.w;
				float3 ase_worldBitangent = cross( ase_worldNormal, ase_worldTangent ) * ase_vertexTangentSign;
				o.ase_texcoord6.xyz = ase_worldBitangent;
				
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord7 = screenPos;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				o.ase_texcoord4.w = 0;
				o.ase_texcoord5.w = 0;
				o.ase_texcoord6.w = 0;
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
				float4 ase_color : COLOR;

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
				o.ase_color = v.ase_color;
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
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
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
				float2 uv_EmissiveTex = IN.ase_texcoord3.xy * _EmissiveTex_ST.xy + _EmissiveTex_ST.zw;
				float2 texCoord535 = IN.ase_texcoord3.xy * _EmiBlendTiling + float2( 0,0 );
				float2 panner524 = ( 1.0 * _Time.y * _EmiBlendSpeed + texCoord535);
				float4 temp_output_856_0 = ( ( tex2D( _EmissiveTex, uv_EmissiveTex ) * _EmissiveColor * _EmissivePower ) * tex2D( _EmissiveBlendTex, panner524 ) );
				float4 color824 = IsGammaSpace() ? float4(1,1,1,1) : float4(1,1,1,1);
				float2 uv_Normalmap = IN.ase_texcoord3.xy * _Normalmap_ST.xy + _Normalmap_ST.zw;
				float3 unpack952 = UnpackNormalScale( tex2D( _Normalmap, uv_Normalmap ), _NormalIntensity );
				unpack952.z = lerp( 1, unpack952.z, saturate(_NormalIntensity) );
				float3 normalizeResult776 = normalize( unpack952 );
				float3 ase_worldTangent = IN.ase_texcoord4.xyz;
				float3 ase_worldNormal = IN.ase_texcoord5.xyz;
				float3 ase_worldBitangent = IN.ase_texcoord6.xyz;
				float3x3 ase_tangentToWorldFast = float3x3(ase_worldTangent.x,ase_worldBitangent.x,ase_worldNormal.x,ase_worldTangent.y,ase_worldBitangent.y,ase_worldNormal.y,ase_worldTangent.z,ase_worldBitangent.z,ase_worldNormal.z);
				float3 tangentToWorldDir384 = normalize( mul( ase_tangentToWorldFast, normalizeResult776 ) );
				float4 mainlight894 = GetMainLightDir(  );
				float3 break6_g228 = (mainlight894).xyz;
				float3 appendResult8_g228 = (float3(break6_g228.x , 0.0 , break6_g228.z));
				float3 normalizeResult9_g228 = normalize( appendResult8_g228 );
				float temp_output_2_0_g228 = 0.6;
				float3 break12_g228 = ( normalizeResult9_g228 * sqrt( ( 1.0 - pow( temp_output_2_0_g228 , 2.0 ) ) ) );
				float3 appendResult11_g228 = (float3(break12_g228.x , temp_output_2_0_g228 , break12_g228.z));
				float dotResult299 = dot( tangentToWorldDir384 , appendResult11_g228 );
				float clampResult956 = clamp( (( ( dotResult299 + 1.0 ) * 0.5 )*_RampRange + 0.0) , 0.01 , 0.99 );
				float2 temp_cast_1 = (clampResult956).xx;
				float4 lerpResult565 = lerp( color824 , ( tex2D( _RampTex, temp_cast_1 ) * _RampColor ) , _RampBlend);
				float2 uv_BaseTex = IN.ase_texcoord3.xy * _BaseTex_ST.xy + _BaseTex_ST.zw;
				float4 temp_output_1030_0 = saturate( ( tex2D( _BaseTex, uv_BaseTex ) * _BaseColor * _ColorPower ) );
				float2 appendResult1083 = (float2(_Colums , _Rows));
				float totalFrames1084 = ( _Colums * _Rows );
				float2 appendResult1075 = (float2(totalFrames1084 , _Rows));
				float mulTime1081 = _TimeParameters.x * _FrameSpeed;
				float clampResult1072 = clamp( _StartFrame , 0.0001 , ( totalFrames1084 - 1.0 ) );
				float lerpResult1094 = lerp( ( mulTime1081 + clampResult1072 ) , ( ( _SetKey - 1.0 ) + 0.1 ) , _UseSetKey);
				float temp_output_1077_0 = frac( ( lerpResult1094 / totalFrames1084 ) );
				float2 appendResult1068 = (float2(temp_output_1077_0 , ( 1.0 - temp_output_1077_0 )));
				float4 lerpResult1128 = lerp( temp_output_1030_0 , tex2D( _SequentialTex, ( ( IN.ase_texcoord3.xy / appendResult1083 ) + ( floor( ( appendResult1075 * appendResult1068 ) ) / appendResult1083 ) ) ) , _UseSequential);
				float4 lerpResult1132 = lerp( temp_output_1030_0 , lerpResult1128 , _UseExpression);
				float3 linearToGamma1028 = FastLinearToSRGB( lerpResult1132.rgb );
				float4 Texcolor1035 = float4( linearToGamma1028 , 0.0 );
				sampler2D LutTex1035 = _LutTexture;
				float _BrightnessCompensation1035 = _LutBrightnessFix;
				float _LutEnable1035 = _UseLUT;
				float4 localMyCustomExpression1035 = MyCustomExpression1035( Texcolor1035 , LutTex1035 , _BrightnessCompensation1035 , _LutEnable1035 );
				float3 gammaToLinear1027 = FastSRGBToLinear( localMyCustomExpression1035.xyz );
				float3 normalizeResult5_g226 = normalize( ( _WorldSpaceCameraPos - WorldPosition ) );
				float4 appendResult8_g226 = (float4(reflect( normalizeResult5_g226 , tangentToWorldDir384 ) , 0.0));
				float3 normalizeResult11_g226 = normalize( (mul( unity_WorldToCamera, appendResult8_g226 )).xyz );
				float3 break12_g226 = normalizeResult11_g226;
				float2 appendResult16_g226 = (float2(break12_g226.x , break12_g226.y));
				float4 temp_output_489_0 = ( tex2D( _MatcapTex, ( 1.0 - ( ( appendResult16_g226 / ( sqrt( ( break12_g226.z + 1.0 ) ) * 2.828427 ) ) + float2( 0.5,0.5 ) ) ) ) * _MatcapColor * ( _MatcapPower * 0.4 ) );
				float4 temp_cast_12 = (0.5).xxxx;
				float4 temp_output_941_0 = step( temp_output_489_0 , temp_cast_12 );
				float4 temp_cast_15 = (0.5).xxxx;
				float2 uv_MatcapMask = IN.ase_texcoord3.xy * _MatcapMask_ST.xy + _MatcapMask_ST.zw;
				float4 lerpResult947 = lerp( float4( gammaToLinear1027 , 0.0 ) , ( ( ( float4( gammaToLinear1027 , 0.0 ) * temp_output_489_0 * 2.0 ) * temp_output_941_0 ) + ( ( 1.0 - ( float4( ( 1.0 - gammaToLinear1027 ) , 0.0 ) * ( 1.0 - temp_output_489_0 ) * 2.0 ) ) * ( 1.0 - temp_output_941_0 ) ) ) , ( ( _MatcapBlend * 0.1 ) * tex2D( _MatcapMask, uv_MatcapMask ).r ));
				#ifdef _USEMATCAP_ON
				float4 staticSwitch416 = lerpResult947;
				#else
				float4 staticSwitch416 = float4( gammaToLinear1027 , 0.0 );
				#endif
				float4 temp_output_317_0 = ( lerpResult565 * staticSwitch416 );
				float temp_output_419_0 = ( dotResult299 + _SpecularRange );
				float2 uv_SpecularMask = IN.ase_texcoord3.xy * _SpecularMask_ST.xy + _SpecularMask_ST.zw;
				float4 tex2DNode493 = tex2D( _SpecularMask, uv_SpecularMask );
				float temp_output_499_0 = ( temp_output_419_0 + _SpecularMaskRange01 );
				float4 lerpResult538 = lerp( ( saturate( ( temp_output_419_0 * _SpecularSoft ) ) * _SpecularColor * _SpecularPower * tex2DNode493.g ) , _SpecularColor01 , ( tex2DNode493.g * saturate( ( temp_output_499_0 * _SpecularSoft01 ) ) ));
				float4 lerpResult510 = lerp( lerpResult538 , _SpecularColor02 , ( tex2DNode493.g * saturate( ( ( temp_output_499_0 + _SpecularMaskRange02 ) * _SpecularSoft02 ) ) ));
				#ifdef _USESPECULAR_ON
				float4 staticSwitch475 = ( temp_output_317_0 + lerpResult510 );
				#else
				float4 staticSwitch475 = temp_output_317_0;
				#endif
				float4 temp_output_318_0 = ( lerpResult565 * _DarkColor * staticSwitch416 );
				float3 hsvTorgb991 = RGBToHSV( temp_output_318_0.rgb );
				float3 hsvTorgb994 = HSVToRGB( float3(saturate( ( _ColorGamut + hsvTorgb991.x ) ),saturate( ( hsvTorgb991.y + _Saturation ) ),saturate( ( _Brightness + hsvTorgb991.z ) )) );
				float clampResult990 = clamp( (( ( dotResult299 + 1.0 ) * 0.5 )*_RampMaskRange + 0.0) , 0.01 , 0.99 );
				float2 temp_cast_18 = (clampResult990).xx;
				float4 lerpResult995 = lerp( float4( hsvTorgb994 , 0.0 ) , temp_output_318_0 , saturate( ( tex2D( _RampMask, temp_cast_18 ).r * _RampMaskIntensity ) ));
				float lerpResult885 = lerp( _DarkRange , ( _DarkRange * IN.ase_color.a ) , _VertexColorAlphaFixDarkRange);
				float temp_output_314_0 = ( 1.0 - saturate( ( ( dotResult299 + lerpResult885 ) / _DarkSoft ) ) );
				float2 uv_ShadowMask = IN.ase_texcoord3.xy * _ShadowMask_ST.xy + _ShadowMask_ST.zw;
				float4 tex2DNode556 = tex2D( _ShadowMask, uv_ShadowMask );
				#ifdef _FILPSHADOWMASK_ON
				float staticSwitch563 = ( 1.0 - tex2DNode556.r );
				#else
				float staticSwitch563 = tex2DNode556.r;
				#endif
				float temp_output_820_0 = ( staticSwitch563 * _ShadowMaskPower );
				#ifdef _USESHADOWMASK_ON
				float staticSwitch558 = saturate( ( temp_output_314_0 + temp_output_820_0 ) );
				#else
				float staticSwitch558 = temp_output_314_0;
				#endif
				float4 lerpResult316 = lerp( staticSwitch475 , lerpResult995 , staticSwitch558);
				float3 ase_worldViewDir = ( _WorldSpaceCameraPos.xyz - WorldPosition );
				ase_worldViewDir = normalize(ase_worldViewDir);
				float dotResult440 = dot( tangentToWorldDir384 , (ase_worldViewDir*1.0 + _RimOffset) );
				float2 uv_RimMask = IN.ase_texcoord3.xy * _RimMask_ST.xy + _RimMask_ST.zw;
				float4 mainlightColor895 = GetMainLightColor(  );
				float3 shColorResult567 = SampleSH( float3( 0,0,0 ) );
				float splitFlag923 = GetEnvSplitFlag(  );
				float3 lerpResult641 = lerp( float3(1,1,1) , (saturate( shColorResult567 )*0.6 + 0.2) , splitFlag923);
				
				float4 screenPos = IN.ase_texcoord7;
				float2 appendResult5_g229 = (float2(_ScreenParams.x , _ScreenParams.y));
				float smoothstepResult21_g229 = smoothstep( ( _ActorRadius - 0.2 ) , _ActorRadius , length( ( frac( ( ( (screenPos).xy / screenPos.w ) * appendResult5_g229 * float2( 0.25,0.25 ) ) ) - float2( 0.5,0.5 ) ) ));
				#ifdef _ALPHAACTOR_ON
				float staticSwitch13_g229 = ( 1.0 - smoothstepResult21_g229 );
				#else
				float staticSwitch13_g229 = 1.0;
				#endif
				float temp_output_854_0 = staticSwitch13_g229;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( temp_output_856_0 + ( ( lerpResult316 + ( saturate( ( ( 1.0 - ( dotResult440 + _RimLightRange ) ) / _RimLightSoft ) ) * _RimLightColor * tex2D( _RimMask, uv_RimMask ).b * _RimPower ) ) * mainlightColor895 * float4( lerpResult641 , 0.0 ) ) ).rgb;
				float Alpha = temp_output_854_0;
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
			#pragma multi_compile_local _ HAMLET_GPU_SKINNING
			
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 999999

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#pragma multi_compile __ _ALPHAACTOR_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 hamlet_gpu_boneWeights : BLENDWEIGHTS;
				uint4 hamlet_gpu_boneIndices : BLENDINDICES;
				
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
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _GpuSkinningBoneTextureSize;
			float _GpuSkinningBoneOffset;
			float _GpuSkinningWeightCount;
			float4 _BaseTex_ST;
			float4 _RimLightColor;
			float4 _SpecularColor02;
			float4 _SpecularColor01;
			float4 _SpecularMask_ST;
			float4 _SpecularColor;
			float4 _MatcapMask_ST;
			float4 _MatcapColor;
			float4 _RampColor;
			float4 _RimMask_ST;
			float4 _OutlineColor;
			float4 _Normalmap_ST;
			float4 _BaseColor;
			float4 _DarkColor;
			float4 _ShadowMask_ST;
			float4 _EmissiveTex_ST;
			float4 _EmissiveColor;
			float2 _EmiBlendSpeed;
			float2 _EmiBlendTiling;
			float _StartFrame;
			float _SpecularRange;
			float _SpecularSoft;
			float _SpecularPower;
			float _SpecularMaskRange01;
			float _SpecularSoft01;
			float _SpecularMaskRange02;
			float _ColorGamut;
			float _Saturation;
			float _Brightness;
			float _RampMaskRange;
			float _RampMaskIntensity;
			float _RimOffset;
			float _RimLightRange;
			float _RimLightSoft;
			float _SpecularSoft02;
			float _MatcapBlend;
			float _MatcapPower;
			float _RampBlend;
			float _SetKey;
			float _UseSetKey;
			float _DarkRange;
			float _UseExpression;
			float _UseLUT;
			float _LutBrightnessFix;
			float _VertexColorAlphaFixDarkRange;
			float _DarkSoft;
			float _ShadowMaskPower;
			float _FrameSpeed;
			float _EmissivePower;
			float _ActorRadius;
			float _OutlineWidth;
			float _OutlineZoffset;
			float _Rows;
			float _OutlineColorBlendIntensity;
			float _Colums;
			float _NormalIntensity;
			float _RampRange;
			float _ColorPower;
			float _UseSequential;
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
			#include "HamletGpuSkinning.hlsl"

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

				#if defined(HAMLET_GPU_SKINNING)
				HamletApplyGpuSkinning(v.vertex, v.ase_normal, v.hamlet_gpu_boneWeights, v.hamlet_gpu_boneIndices);
				#endif

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
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

				float4 screenPos = IN.ase_texcoord2;
				float2 appendResult5_g229 = (float2(_ScreenParams.x , _ScreenParams.y));
				float smoothstepResult21_g229 = smoothstep( ( _ActorRadius - 0.2 ) , _ActorRadius , length( ( frac( ( ( (screenPos).xy / screenPos.w ) * appendResult5_g229 * float2( 0.25,0.25 ) ) ) - float2( 0.5,0.5 ) ) ));
				#ifdef _ALPHAACTOR_ON
				float staticSwitch13_g229 = ( 1.0 - smoothstepResult21_g229 );
				#else
				float staticSwitch13_g229 = 1.0;
				#endif
				float temp_output_854_0 = staticSwitch13_g229;
				
				float Alpha = temp_output_854_0;
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

	
	}
	SubShader
	{
		LOD 400

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		
		Cull Back
		AlphaToMask Off
		HLSLINCLUDE
		#pragma target 3.0

		#pragma prefer_hlslcc gles
		#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal vulkan 
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
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			Cull [_CullMode]
			

			HLSLPROGRAM
			#pragma multi_compile_local _ HAMLET_GPU_SKINNING

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

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#define ASE_NEEDS_VERT_NORMAL
			#pragma shader_feature_local _USESHADOWMASK_ON
			#pragma shader_feature_local _FILPSHADOWMASK_ON
			#pragma multi_compile __ _ALPHAACTOR_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 hamlet_gpu_boneWeights : BLENDWEIGHTS;
				uint4 hamlet_gpu_boneIndices : BLENDINDICES;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
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
				float4 ase_color : COLOR;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _GpuSkinningBoneTextureSize;
			float _GpuSkinningBoneOffset;
			float _GpuSkinningWeightCount;
			float4 _BaseTex_ST;
			float4 _RimLightColor;
			float4 _SpecularColor02;
			float4 _SpecularColor01;
			float4 _SpecularMask_ST;
			float4 _SpecularColor;
			float4 _MatcapMask_ST;
			float4 _MatcapColor;
			float4 _RampColor;
			float4 _RimMask_ST;
			float4 _OutlineColor;
			float4 _Normalmap_ST;
			float4 _BaseColor;
			float4 _DarkColor;
			float4 _ShadowMask_ST;
			float4 _EmissiveTex_ST;
			float4 _EmissiveColor;
			float2 _EmiBlendSpeed;
			float2 _EmiBlendTiling;
			float _StartFrame;
			float _SpecularRange;
			float _SpecularSoft;
			float _SpecularPower;
			float _SpecularMaskRange01;
			float _SpecularSoft01;
			float _SpecularMaskRange02;
			float _ColorGamut;
			float _Saturation;
			float _Brightness;
			float _RampMaskRange;
			float _RampMaskIntensity;
			float _RimOffset;
			float _RimLightRange;
			float _RimLightSoft;
			float _SpecularSoft02;
			float _MatcapBlend;
			float _MatcapPower;
			float _RampBlend;
			float _SetKey;
			float _UseSetKey;
			float _DarkRange;
			float _UseExpression;
			float _UseLUT;
			float _LutBrightnessFix;
			float _VertexColorAlphaFixDarkRange;
			float _DarkSoft;
			float _ShadowMaskPower;
			float _FrameSpeed;
			float _EmissivePower;
			float _ActorRadius;
			float _OutlineWidth;
			float _OutlineZoffset;
			float _Rows;
			float _OutlineColorBlendIntensity;
			float _Colums;
			float _NormalIntensity;
			float _RampRange;
			float _ColorPower;
			float _UseSequential;
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
			#include "HamletGpuSkinning.hlsl"

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
			sampler2D _SequentialTex;
			sampler2D _LutTexture;
			sampler2D _ShadowMask;
			sampler2D _EmissiveTex;
			sampler2D _EmissiveBlendTex;


			float4 MyCustomExpression1035( float4 Texcolor, sampler2D LutTex, float _BrightnessCompensation, float _LutEnable )
			{
				// 采样原图
				float4 col = Texcolor;
				// 初始化最终颜色（默认返回原图，开关为1时再替换为校色后颜色）
				float3 finalColor = col.rgb;
				// 仅当开关为1时，执行LUT校色逻辑（开关为0时跳过，直接输出原图）
				if (_LutEnable > 0.5) 
				{
				    // 通道映射（R→U, G→V, B→W）
				    float u = col.r;
				    float v = col.g;
				    float w = col.b;
				    // LUT采样计算
				    const int LUT_SIZE = 16;
				    float scaleZ = LUT_SIZE - 1.0;
				    // 安全边界处理
				    float halfPixel = 0.5 / (LUT_SIZE * LUT_SIZE);
				    float maxSafeU = 1.0 - (1.0 / LUT_SIZE) - halfPixel;
				    u = saturate(u);
				    u = min(u, maxSafeU);
				    v = saturate(v);
				    v = clamp(v, halfPixel, 1.0 - halfPixel);
				    w = saturate(w);
				    // 计算LUT坐标
				    w *= scaleZ;
				    float stripIndex = floor(w);
				    stripIndex = clamp(stripIndex, 0.0, LUT_SIZE - 1.0);
				    float stripOffset = stripIndex * LUT_SIZE;
				    // 当前条带采样坐标
				    float x = (stripOffset + u * LUT_SIZE) / (LUT_SIZE * LUT_SIZE);
				    x = clamp(x, stripOffset / (LUT_SIZE * LUT_SIZE) + halfPixel, 
				              (stripOffset + LUT_SIZE) / (LUT_SIZE * LUT_SIZE) - halfPixel);
				    float y = v;
				    // 下一条带采样坐标（用于插值）
				    float nextStripIndex = min(stripIndex + 1.0, LUT_SIZE - 1.0);
				    float nextStripOffset = nextStripIndex * LUT_SIZE;
				    float x2 = (nextStripOffset + u * LUT_SIZE) / (LUT_SIZE * LUT_SIZE);
				    x2 = clamp(x2, nextStripOffset / (LUT_SIZE * LUT_SIZE) + halfPixel, 
				               (nextStripOffset + LUT_SIZE) / (LUT_SIZE * LUT_SIZE) - halfPixel);
				    // LUT双线性插值采样
				    float4 color1 = tex2D(LutTex, float2(x, y));
				    float4 color2 = tex2D(LutTex, float2(x2, y));
				    float t = saturate(w - stripIndex);
				    float4 correctedColor = lerp(color1, color2, t);
				    // 亮度补偿（仅校色时生效）
				    finalColor = correctedColor.rgb * _BrightnessCompensation;
				    // 颜色范围钳位（仅校色时生效）
				    finalColor.r = clamp(finalColor.r, 0.0, 1.0);
				    finalColor.g = clamp(finalColor.g, 0.0, 1.0);
				    finalColor.b = clamp(finalColor.b, 0.0, 1.0);
				}
				// 输出最终颜色（开关0=原图，1=校色后；始终保留原图Alpha）
				return float4(finalColor, col.a);
			}
			
			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				#if defined(HAMLET_GPU_SKINNING)
				HamletApplyGpuSkinning(v.vertex, v.ase_normal, v.hamlet_gpu_boneWeights, v.hamlet_gpu_boneIndices);
				#endif

				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord4.xyz = ase_worldNormal;
				
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord5 = screenPos;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				o.ase_texcoord4.w = 0;
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
				float4 ase_color : COLOR;

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
				o.ase_color = v.ase_color;
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
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
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
				float4 mainlightColor895 = GetMainLightColor(  );
				float2 uv_BaseTex = IN.ase_texcoord3.xy * _BaseTex_ST.xy + _BaseTex_ST.zw;
				float4 temp_output_1030_0 = saturate( ( tex2D( _BaseTex, uv_BaseTex ) * _BaseColor * _ColorPower ) );
				float2 appendResult1083 = (float2(_Colums , _Rows));
				float totalFrames1084 = ( _Colums * _Rows );
				float2 appendResult1075 = (float2(totalFrames1084 , _Rows));
				float mulTime1081 = _TimeParameters.x * _FrameSpeed;
				float clampResult1072 = clamp( _StartFrame , 0.0001 , ( totalFrames1084 - 1.0 ) );
				float lerpResult1094 = lerp( ( mulTime1081 + clampResult1072 ) , ( ( _SetKey - 1.0 ) + 0.1 ) , _UseSetKey);
				float temp_output_1077_0 = frac( ( lerpResult1094 / totalFrames1084 ) );
				float2 appendResult1068 = (float2(temp_output_1077_0 , ( 1.0 - temp_output_1077_0 )));
				float4 lerpResult1128 = lerp( temp_output_1030_0 , tex2D( _SequentialTex, ( ( IN.ase_texcoord3.xy / appendResult1083 ) + ( floor( ( appendResult1075 * appendResult1068 ) ) / appendResult1083 ) ) ) , _UseSequential);
				float4 lerpResult1132 = lerp( temp_output_1030_0 , lerpResult1128 , _UseExpression);
				float3 linearToGamma1028 = FastLinearToSRGB( lerpResult1132.rgb );
				float4 Texcolor1035 = float4( linearToGamma1028 , 0.0 );
				sampler2D LutTex1035 = _LutTexture;
				float _BrightnessCompensation1035 = _LutBrightnessFix;
				float _LutEnable1035 = _UseLUT;
				float4 localMyCustomExpression1035 = MyCustomExpression1035( Texcolor1035 , LutTex1035 , _BrightnessCompensation1035 , _LutEnable1035 );
				float3 gammaToLinear1027 = FastSRGBToLinear( localMyCustomExpression1035.xyz );
				float lerpResult885 = lerp( _DarkRange , ( _DarkRange * IN.ase_color.a ) , _VertexColorAlphaFixDarkRange);
				float3 ase_worldNormal = IN.ase_texcoord4.xyz;
				float4 mainlight901 = GetMainLightDir(  );
				float3 break6_g227 = (mainlight901).xyz;
				float3 appendResult8_g227 = (float3(break6_g227.x , 0.0 , break6_g227.z));
				float3 normalizeResult9_g227 = normalize( appendResult8_g227 );
				float temp_output_2_0_g227 = 0.6;
				float3 break12_g227 = ( normalizeResult9_g227 * sqrt( ( 1.0 - pow( temp_output_2_0_g227 , 2.0 ) ) ) );
				float3 appendResult11_g227 = (float3(break12_g227.x , temp_output_2_0_g227 , break12_g227.z));
				float dotResult904 = dot( ase_worldNormal , appendResult11_g227 );
				float temp_output_907_0 = ( 1.0 - saturate( ( ( lerpResult885 + dotResult904 ) / _DarkSoft ) ) );
				float2 uv_ShadowMask = IN.ase_texcoord3.xy * _ShadowMask_ST.xy + _ShadowMask_ST.zw;
				float4 tex2DNode556 = tex2D( _ShadowMask, uv_ShadowMask );
				#ifdef _FILPSHADOWMASK_ON
				float staticSwitch563 = ( 1.0 - tex2DNode556.r );
				#else
				float staticSwitch563 = tex2DNode556.r;
				#endif
				float temp_output_820_0 = ( staticSwitch563 * _ShadowMaskPower );
				#ifdef _USESHADOWMASK_ON
				float staticSwitch918 = saturate( ( temp_output_907_0 + temp_output_820_0 ) );
				#else
				float staticSwitch918 = temp_output_907_0;
				#endif
				float4 lerpResult919 = lerp( float4( gammaToLinear1027 , 0.0 ) , ( float4( gammaToLinear1027 , 0.0 ) * _DarkColor ) , staticSwitch918);
				float3 shColorResult567 = SampleSH( float3( 0,0,0 ) );
				float splitFlag923 = GetEnvSplitFlag(  );
				float3 lerpResult641 = lerp( float3(1,1,1) , (saturate( shColorResult567 )*0.6 + 0.2) , splitFlag923);
				float4 temp_output_906_0 = ( mainlightColor895 * lerpResult919 * float4( lerpResult641 , 0.0 ) );
				float2 uv_EmissiveTex = IN.ase_texcoord3.xy * _EmissiveTex_ST.xy + _EmissiveTex_ST.zw;
				float2 texCoord535 = IN.ase_texcoord3.xy * _EmiBlendTiling + float2( 0,0 );
				float2 panner524 = ( 1.0 * _Time.y * _EmiBlendSpeed + texCoord535);
				float4 temp_output_856_0 = ( ( tex2D( _EmissiveTex, uv_EmissiveTex ) * _EmissiveColor * _EmissivePower ) * tex2D( _EmissiveBlendTex, panner524 ) );
				
				float4 screenPos = IN.ase_texcoord5;
				float2 appendResult5_g229 = (float2(_ScreenParams.x , _ScreenParams.y));
				float smoothstepResult21_g229 = smoothstep( ( _ActorRadius - 0.2 ) , _ActorRadius , length( ( frac( ( ( (screenPos).xy / screenPos.w ) * appendResult5_g229 * float2( 0.25,0.25 ) ) ) - float2( 0.5,0.5 ) ) ));
				#ifdef _ALPHAACTOR_ON
				float staticSwitch13_g229 = ( 1.0 - smoothstepResult21_g229 );
				#else
				float staticSwitch13_g229 = 1.0;
				#endif
				float temp_output_854_0 = staticSwitch13_g229;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = ( temp_output_906_0 + temp_output_856_0 ).xyz;
				float Alpha = temp_output_854_0;
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
			#pragma multi_compile_local _ HAMLET_GPU_SKINNING
			
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 999999

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#pragma multi_compile __ _ALPHAACTOR_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 hamlet_gpu_boneWeights : BLENDWEIGHTS;
				uint4 hamlet_gpu_boneIndices : BLENDINDICES;
				
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
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _GpuSkinningBoneTextureSize;
			float _GpuSkinningBoneOffset;
			float _GpuSkinningWeightCount;
			float4 _BaseTex_ST;
			float4 _RimLightColor;
			float4 _SpecularColor02;
			float4 _SpecularColor01;
			float4 _SpecularMask_ST;
			float4 _SpecularColor;
			float4 _MatcapMask_ST;
			float4 _MatcapColor;
			float4 _RampColor;
			float4 _RimMask_ST;
			float4 _OutlineColor;
			float4 _Normalmap_ST;
			float4 _BaseColor;
			float4 _DarkColor;
			float4 _ShadowMask_ST;
			float4 _EmissiveTex_ST;
			float4 _EmissiveColor;
			float2 _EmiBlendSpeed;
			float2 _EmiBlendTiling;
			float _StartFrame;
			float _SpecularRange;
			float _SpecularSoft;
			float _SpecularPower;
			float _SpecularMaskRange01;
			float _SpecularSoft01;
			float _SpecularMaskRange02;
			float _ColorGamut;
			float _Saturation;
			float _Brightness;
			float _RampMaskRange;
			float _RampMaskIntensity;
			float _RimOffset;
			float _RimLightRange;
			float _RimLightSoft;
			float _SpecularSoft02;
			float _MatcapBlend;
			float _MatcapPower;
			float _RampBlend;
			float _SetKey;
			float _UseSetKey;
			float _DarkRange;
			float _UseExpression;
			float _UseLUT;
			float _LutBrightnessFix;
			float _VertexColorAlphaFixDarkRange;
			float _DarkSoft;
			float _ShadowMaskPower;
			float _FrameSpeed;
			float _EmissivePower;
			float _ActorRadius;
			float _OutlineWidth;
			float _OutlineZoffset;
			float _Rows;
			float _OutlineColorBlendIntensity;
			float _Colums;
			float _NormalIntensity;
			float _RampRange;
			float _ColorPower;
			float _UseSequential;
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
			#include "HamletGpuSkinning.hlsl"

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

				#if defined(HAMLET_GPU_SKINNING)
				HamletApplyGpuSkinning(v.vertex, v.ase_normal, v.hamlet_gpu_boneWeights, v.hamlet_gpu_boneIndices);
				#endif

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
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

				float4 screenPos = IN.ase_texcoord2;
				float2 appendResult5_g229 = (float2(_ScreenParams.x , _ScreenParams.y));
				float smoothstepResult21_g229 = smoothstep( ( _ActorRadius - 0.2 ) , _ActorRadius , length( ( frac( ( ( (screenPos).xy / screenPos.w ) * appendResult5_g229 * float2( 0.25,0.25 ) ) ) - float2( 0.5,0.5 ) ) ));
				#ifdef _ALPHAACTOR_ON
				float staticSwitch13_g229 = ( 1.0 - smoothstepResult21_g229 );
				#else
				float staticSwitch13_g229 = 1.0;
				#endif
				float temp_output_854_0 = staticSwitch13_g229;
				
				float Alpha = temp_output_854_0;
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

	
	}
	
SubShader
	{
		LOD 300

		
		Tags { "RenderPipeline"="UniversalPipeline" "RenderType"="Opaque" "Queue"="Geometry" }
		
		Cull Back
		AlphaToMask On
		HLSLINCLUDE
		#pragma target 3.0

		#pragma prefer_hlslcc gles
		#pragma only_renderers d3d9 d3d11 glcore gles gles3 metal vulkan 
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
			
			Name "Forward"
			Tags { "LightMode"="UniversalForward" }
			
			Blend One Zero, One Zero
			ZWrite On
			ZTest LEqual
			Offset 0 , 0
			ColorMask RGBA
			Cull [_CullMode]
			

			HLSLPROGRAM
			#pragma multi_compile_local _ HAMLET_GPU_SKINNING

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

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"
			#define ASE_NEEDS_VERT_NORMAL
			#pragma shader_feature_local _USESHADOWMASK_ON
			#pragma shader_feature_local _FILPSHADOWMASK_ON
			#pragma multi_compile __ _ALPHAACTOR_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 hamlet_gpu_boneWeights : BLENDWEIGHTS;
				uint4 hamlet_gpu_boneIndices : BLENDINDICES;
				float4 ase_texcoord : TEXCOORD0;
				float4 ase_color : COLOR;
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
				float4 ase_color : COLOR;
				float4 ase_texcoord4 : TEXCOORD4;
				float4 ase_texcoord5 : TEXCOORD5;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _GpuSkinningBoneTextureSize;
			float _GpuSkinningBoneOffset;
			float _GpuSkinningWeightCount;
			float4 _BaseTex_ST;
			float4 _RimLightColor;
			float4 _SpecularColor02;
			float4 _SpecularColor01;
			float4 _SpecularMask_ST;
			float4 _SpecularColor;
			float4 _MatcapMask_ST;
			float4 _MatcapColor;
			float4 _RampColor;
			float4 _RimMask_ST;
			float4 _OutlineColor;
			float4 _Normalmap_ST;
			float4 _BaseColor;
			float4 _DarkColor;
			float4 _ShadowMask_ST;
			float4 _EmissiveTex_ST;
			float4 _EmissiveColor;
			float2 _EmiBlendSpeed;
			float2 _EmiBlendTiling;
			float _StartFrame;
			float _SpecularRange;
			float _SpecularSoft;
			float _SpecularPower;
			float _SpecularMaskRange01;
			float _SpecularSoft01;
			float _SpecularMaskRange02;
			float _ColorGamut;
			float _Saturation;
			float _Brightness;
			float _RampMaskRange;
			float _RampMaskIntensity;
			float _RimOffset;
			float _RimLightRange;
			float _RimLightSoft;
			float _SpecularSoft02;
			float _MatcapBlend;
			float _MatcapPower;
			float _RampBlend;
			float _SetKey;
			float _UseSetKey;
			float _DarkRange;
			float _UseExpression;
			float _UseLUT;
			float _LutBrightnessFix;
			float _VertexColorAlphaFixDarkRange;
			float _DarkSoft;
			float _ShadowMaskPower;
			float _FrameSpeed;
			float _EmissivePower;
			float _ActorRadius;
			float _OutlineWidth;
			float _OutlineZoffset;
			float _Rows;
			float _OutlineColorBlendIntensity;
			float _Colums;
			float _NormalIntensity;
			float _RampRange;
			float _ColorPower;
			float _UseSequential;
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
			#include "HamletGpuSkinning.hlsl"

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
			sampler2D _SequentialTex;
			sampler2D _LutTexture;
			sampler2D _ShadowMask;


			float4 MyCustomExpression1035( float4 Texcolor, sampler2D LutTex, float _BrightnessCompensation, float _LutEnable )
			{
				// 采样原图
				float4 col = Texcolor;
				// 初始化最终颜色（默认返回原图，开关为1时再替换为校色后颜色）
				float3 finalColor = col.rgb;
				// 仅当开关为1时，执行LUT校色逻辑（开关为0时跳过，直接输出原图）
				if (_LutEnable > 0.5) 
				{
				    // 通道映射（R→U, G→V, B→W）
				    float u = col.r;
				    float v = col.g;
				    float w = col.b;
				    // LUT采样计算
				    const int LUT_SIZE = 16;
				    float scaleZ = LUT_SIZE - 1.0;
				    // 安全边界处理
				    float halfPixel = 0.5 / (LUT_SIZE * LUT_SIZE);
				    float maxSafeU = 1.0 - (1.0 / LUT_SIZE) - halfPixel;
				    u = saturate(u);
				    u = min(u, maxSafeU);
				    v = saturate(v);
				    v = clamp(v, halfPixel, 1.0 - halfPixel);
				    w = saturate(w);
				    // 计算LUT坐标
				    w *= scaleZ;
				    float stripIndex = floor(w);
				    stripIndex = clamp(stripIndex, 0.0, LUT_SIZE - 1.0);
				    float stripOffset = stripIndex * LUT_SIZE;
				    // 当前条带采样坐标
				    float x = (stripOffset + u * LUT_SIZE) / (LUT_SIZE * LUT_SIZE);
				    x = clamp(x, stripOffset / (LUT_SIZE * LUT_SIZE) + halfPixel, 
				              (stripOffset + LUT_SIZE) / (LUT_SIZE * LUT_SIZE) - halfPixel);
				    float y = v;
				    // 下一条带采样坐标（用于插值）
				    float nextStripIndex = min(stripIndex + 1.0, LUT_SIZE - 1.0);
				    float nextStripOffset = nextStripIndex * LUT_SIZE;
				    float x2 = (nextStripOffset + u * LUT_SIZE) / (LUT_SIZE * LUT_SIZE);
				    x2 = clamp(x2, nextStripOffset / (LUT_SIZE * LUT_SIZE) + halfPixel, 
				               (nextStripOffset + LUT_SIZE) / (LUT_SIZE * LUT_SIZE) - halfPixel);
				    // LUT双线性插值采样
				    float4 color1 = tex2D(LutTex, float2(x, y));
				    float4 color2 = tex2D(LutTex, float2(x2, y));
				    float t = saturate(w - stripIndex);
				    float4 correctedColor = lerp(color1, color2, t);
				    // 亮度补偿（仅校色时生效）
				    finalColor = correctedColor.rgb * _BrightnessCompensation;
				    // 颜色范围钳位（仅校色时生效）
				    finalColor.r = clamp(finalColor.r, 0.0, 1.0);
				    finalColor.g = clamp(finalColor.g, 0.0, 1.0);
				    finalColor.b = clamp(finalColor.b, 0.0, 1.0);
				}
				// 输出最终颜色（开关0=原图，1=校色后；始终保留原图Alpha）
				return float4(finalColor, col.a);
			}
			
			
			VertexOutput VertexFunction ( VertexInput v  )
			{
				VertexOutput o = (VertexOutput)0;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_TRANSFER_INSTANCE_ID(v, o);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				#if defined(HAMLET_GPU_SKINNING)
				HamletApplyGpuSkinning(v.vertex, v.ase_normal, v.hamlet_gpu_boneWeights, v.hamlet_gpu_boneIndices);
				#endif

				float3 ase_worldNormal = TransformObjectToWorldNormal(v.ase_normal);
				o.ase_texcoord4.xyz = ase_worldNormal;
				
				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord5 = screenPos;
				
				o.ase_texcoord3.xy = v.ase_texcoord.xy;
				o.ase_color = v.ase_color;
				
				//setting value to unused interpolator channels and avoid initialization warnings
				o.ase_texcoord3.zw = 0;
				o.ase_texcoord4.w = 0;
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
				float4 ase_color : COLOR;

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
				o.ase_color = v.ase_color;
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
				o.ase_color = patch[0].ase_color * bary.x + patch[1].ase_color * bary.y + patch[2].ase_color * bary.z;
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
				float4 mainlightColor895 = GetMainLightColor(  );
				float2 uv_BaseTex = IN.ase_texcoord3.xy * _BaseTex_ST.xy + _BaseTex_ST.zw;
				float4 temp_output_1030_0 = saturate( ( tex2D( _BaseTex, uv_BaseTex ) * _BaseColor * _ColorPower ) );
				float2 appendResult1083 = (float2(_Colums , _Rows));
				float totalFrames1084 = ( _Colums * _Rows );
				float2 appendResult1075 = (float2(totalFrames1084 , _Rows));
				float mulTime1081 = _TimeParameters.x * _FrameSpeed;
				float clampResult1072 = clamp( _StartFrame , 0.0001 , ( totalFrames1084 - 1.0 ) );
				float lerpResult1094 = lerp( ( mulTime1081 + clampResult1072 ) , ( ( _SetKey - 1.0 ) + 0.1 ) , _UseSetKey);
				float temp_output_1077_0 = frac( ( lerpResult1094 / totalFrames1084 ) );
				float2 appendResult1068 = (float2(temp_output_1077_0 , ( 1.0 - temp_output_1077_0 )));
				float4 lerpResult1128 = lerp( temp_output_1030_0 , tex2D( _SequentialTex, ( ( IN.ase_texcoord3.xy / appendResult1083 ) + ( floor( ( appendResult1075 * appendResult1068 ) ) / appendResult1083 ) ) ) , _UseSequential);
				float4 lerpResult1132 = lerp( temp_output_1030_0 , lerpResult1128 , _UseExpression);
				float3 linearToGamma1028 = FastLinearToSRGB( lerpResult1132.rgb );
				float4 Texcolor1035 = float4( linearToGamma1028 , 0.0 );
				sampler2D LutTex1035 = _LutTexture;
				float _BrightnessCompensation1035 = _LutBrightnessFix;
				float _LutEnable1035 = _UseLUT;
				float4 localMyCustomExpression1035 = MyCustomExpression1035( Texcolor1035 , LutTex1035 , _BrightnessCompensation1035 , _LutEnable1035 );
				float3 gammaToLinear1027 = FastSRGBToLinear( localMyCustomExpression1035.xyz );
				float lerpResult885 = lerp( _DarkRange , ( _DarkRange * IN.ase_color.a ) , _VertexColorAlphaFixDarkRange);
				float3 ase_worldNormal = IN.ase_texcoord4.xyz;
				float4 mainlight901 = GetMainLightDir(  );
				float3 break6_g227 = (mainlight901).xyz;
				float3 appendResult8_g227 = (float3(break6_g227.x , 0.0 , break6_g227.z));
				float3 normalizeResult9_g227 = normalize( appendResult8_g227 );
				float temp_output_2_0_g227 = 0.6;
				float3 break12_g227 = ( normalizeResult9_g227 * sqrt( ( 1.0 - pow( temp_output_2_0_g227 , 2.0 ) ) ) );
				float3 appendResult11_g227 = (float3(break12_g227.x , temp_output_2_0_g227 , break12_g227.z));
				float dotResult904 = dot( ase_worldNormal , appendResult11_g227 );
				float temp_output_907_0 = ( 1.0 - saturate( ( ( lerpResult885 + dotResult904 ) / _DarkSoft ) ) );
				float2 uv_ShadowMask = IN.ase_texcoord3.xy * _ShadowMask_ST.xy + _ShadowMask_ST.zw;
				float4 tex2DNode556 = tex2D( _ShadowMask, uv_ShadowMask );
				#ifdef _FILPSHADOWMASK_ON
				float staticSwitch563 = ( 1.0 - tex2DNode556.r );
				#else
				float staticSwitch563 = tex2DNode556.r;
				#endif
				float temp_output_820_0 = ( staticSwitch563 * _ShadowMaskPower );
				#ifdef _USESHADOWMASK_ON
				float staticSwitch918 = saturate( ( temp_output_907_0 + temp_output_820_0 ) );
				#else
				float staticSwitch918 = temp_output_907_0;
				#endif
				float4 lerpResult919 = lerp( float4( gammaToLinear1027 , 0.0 ) , ( float4( gammaToLinear1027 , 0.0 ) * _DarkColor ) , staticSwitch918);
				float3 shColorResult567 = SampleSH( float3( 0,0,0 ) );
				float splitFlag923 = GetEnvSplitFlag(  );
				float3 lerpResult641 = lerp( float3(1,1,1) , (saturate( shColorResult567 )*0.6 + 0.2) , splitFlag923);
				float4 temp_output_906_0 = ( mainlightColor895 * lerpResult919 * float4( lerpResult641 , 0.0 ) );
				
				float4 screenPos = IN.ase_texcoord5;
				float2 appendResult5_g229 = (float2(_ScreenParams.x , _ScreenParams.y));
				float smoothstepResult21_g229 = smoothstep( ( _ActorRadius - 0.2 ) , _ActorRadius , length( ( frac( ( ( (screenPos).xy / screenPos.w ) * appendResult5_g229 * float2( 0.25,0.25 ) ) ) - float2( 0.5,0.5 ) ) ));
				#ifdef _ALPHAACTOR_ON
				float staticSwitch13_g229 = ( 1.0 - smoothstepResult21_g229 );
				#else
				float staticSwitch13_g229 = 1.0;
				#endif
				float temp_output_854_0 = staticSwitch13_g229;
				
				float3 BakedAlbedo = 0;
				float3 BakedEmission = 0;
				float3 Color = temp_output_906_0.xyz;
				float Alpha = temp_output_854_0;
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
			#pragma multi_compile_local _ HAMLET_GPU_SKINNING
			
			#pragma multi_compile_fog
			#define ASE_FOG 1
			#define ASE_SRP_VERSION 999999

			
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
			#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/ShaderGraphFunctions.hlsl"
			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Color.hlsl"

			#pragma multi_compile __ _ALPHAACTOR_ON


			struct VertexInput
			{
				float4 vertex : POSITION;
				float3 ase_normal : NORMAL;
				float4 hamlet_gpu_boneWeights : BLENDWEIGHTS;
				uint4 hamlet_gpu_boneIndices : BLENDINDICES;
				
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
				float4 ase_texcoord2 : TEXCOORD2;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			CBUFFER_START(UnityPerMaterial)
			float4 _GpuSkinningBoneTextureSize;
			float _GpuSkinningBoneOffset;
			float _GpuSkinningWeightCount;
			float4 _BaseTex_ST;
			float4 _RimLightColor;
			float4 _SpecularColor02;
			float4 _SpecularColor01;
			float4 _SpecularMask_ST;
			float4 _SpecularColor;
			float4 _MatcapMask_ST;
			float4 _MatcapColor;
			float4 _RampColor;
			float4 _RimMask_ST;
			float4 _OutlineColor;
			float4 _Normalmap_ST;
			float4 _BaseColor;
			float4 _DarkColor;
			float4 _ShadowMask_ST;
			float4 _EmissiveTex_ST;
			float4 _EmissiveColor;
			float2 _EmiBlendSpeed;
			float2 _EmiBlendTiling;
			float _StartFrame;
			float _SpecularRange;
			float _SpecularSoft;
			float _SpecularPower;
			float _SpecularMaskRange01;
			float _SpecularSoft01;
			float _SpecularMaskRange02;
			float _ColorGamut;
			float _Saturation;
			float _Brightness;
			float _RampMaskRange;
			float _RampMaskIntensity;
			float _RimOffset;
			float _RimLightRange;
			float _RimLightSoft;
			float _SpecularSoft02;
			float _MatcapBlend;
			float _MatcapPower;
			float _RampBlend;
			float _SetKey;
			float _UseSetKey;
			float _DarkRange;
			float _UseExpression;
			float _UseLUT;
			float _LutBrightnessFix;
			float _VertexColorAlphaFixDarkRange;
			float _DarkSoft;
			float _ShadowMaskPower;
			float _FrameSpeed;
			float _EmissivePower;
			float _ActorRadius;
			float _OutlineWidth;
			float _OutlineZoffset;
			float _Rows;
			float _OutlineColorBlendIntensity;
			float _Colums;
			float _NormalIntensity;
			float _RampRange;
			float _ColorPower;
			float _UseSequential;
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
			#include "HamletGpuSkinning.hlsl"

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

				#if defined(HAMLET_GPU_SKINNING)
				HamletApplyGpuSkinning(v.vertex, v.ase_normal, v.hamlet_gpu_boneWeights, v.hamlet_gpu_boneIndices);
				#endif

				float4 ase_clipPos = TransformObjectToHClip((v.vertex).xyz);
				float4 screenPos = ComputeScreenPos(ase_clipPos);
				o.ase_texcoord2 = screenPos;
				
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

				float4 screenPos = IN.ase_texcoord2;
				float2 appendResult5_g229 = (float2(_ScreenParams.x , _ScreenParams.y));
				float smoothstepResult21_g229 = smoothstep( ( _ActorRadius - 0.2 ) , _ActorRadius , length( ( frac( ( ( (screenPos).xy / screenPos.w ) * appendResult5_g229 * float2( 0.25,0.25 ) ) ) - float2( 0.5,0.5 ) ) ));
				#ifdef _ALPHAACTOR_ON
				float staticSwitch13_g229 = ( 1.0 - smoothstepResult21_g229 );
				#else
				float staticSwitch13_g229 = 1.0;
				#endif
				float temp_output_854_0 = staticSwitch13_g229;
				
				float Alpha = temp_output_854_0;
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

	
	}
	

	CustomEditor "ParaMaterialEditor"
	Fallback "Hidden/InternalErrorShader"
	
}
/*ASEBEGIN
Version=18912
2571;211;2560;1232;135.431;2585.951;1;True;True
Node;AmplifyShaderEditor.CommentaryNode;1063;3410.031,-2363.772;Inherit;False;1946.718;376.2009;OutlineCullFix;12;1060;1054;1048;1053;1055;1052;1050;1056;1057;1049;1051;1061;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;1046;2458.83,-2609.259;Inherit;False;943.5439;389.4224;LUT;5;1045;1027;1035;1028;1040;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;957;3840.163,-3388.389;Inherit;False;1153.711;976.1045;Outline;14;958;963;977;976;978;974;971;961;969;965;959;973;972;979;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;403;1558.124,-706.7764;Inherit;False;2833.037;670.8929;CartoonLight;27;558;556;318;314;562;560;304;308;305;307;313;316;317;475;563;306;299;745;730;820;822;823;883;884;885;886;894;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;401;1451.674,-1166.722;Inherit;False;1586.331;443.3327;Ramp;13;555;955;554;954;553;218;565;407;254;253;824;825;956;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;399;-286.6118,-11.53522;Inherit;False;2714.043;803.4395;matcap;31;951;948;946;949;953;488;937;934;942;416;941;944;938;945;487;815;936;939;947;384;816;952;381;833;935;950;492;943;489;776;834;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;398;3316.807,-5.925011;Inherit;False;1431.718;885.8992;Emissve;10;534;524;523;535;395;390;537;393;391;856;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;400;1712.255,-1738.095;Inherit;False;558.6589;518.444;Basecolor;4;260;217;251;252;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;429;3109.814,928.0593;Inherit;False;1222.921;982.5642;Specular;26;538;510;422;421;419;424;499;509;506;505;423;496;427;493;428;497;495;420;504;593;594;596;595;597;598;599;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;469;2700.755,1954.153;Inherit;False;1766.055;541.3859;RimLight;13;814;443;437;441;444;439;436;462;445;433;440;461;431;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;644;4392.764,1130.416;Inherit;False;633.4209;403.8587;SH Sampler;6;567;608;788;790;641;923;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;922;2872.979,-1972.96;Inherit;False;2938.089;792.8103;LODshader;22;897;918;917;920;907;904;906;903;908;909;902;901;919;910;911;905;924;926;928;927;999;997;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;1012;34.99418,-2524.486;Inherit;False;2403.607;753.4337;SequentialTex;33;1013;1065;1071;1069;1079;1082;1074;1080;1084;1085;1067;1007;1008;1081;1072;1066;1005;1006;1073;1076;1070;1077;1068;1075;1083;1090;1093;1092;1094;1095;1129;1128;1131;;1,1,1,1;0;0
Node;AmplifyShaderEditor.CommentaryNode;980;3089.526,-1138.273;Inherit;False;1793.67;410.6412;RampMask;22;996;995;994;993;992;991;990;989;988;987;986;985;984;983;982;981;344;343;345;1001;1000;1047;;1,1,1,1;0;0
Node;AmplifyShaderEditor.ClampOpNode;990;3770.311,-1018.197;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.01;False;2;FLOAT;0.99;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;554;1762.404,-1076.197;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;951;891.6233,662.1819;Inherit;False;Constant;_Float2;Float 2;57;0;Create;True;0;0;0;False;0;False;0.1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;992;4380.081,-1001.38;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;982;4334.805,-874.3868;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;936;1496.415,289.5038;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;981;3880.632,-1022.191;Inherit;True;Property;_RampMask;RampMask;34;1;[Header];Create;True;1;__________________RampHSV____________________________________________________________________________________________;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;1002;4228.896,-1172.328;Inherit;False;Property;_ColorGamut;ColorGamut;37;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1082;1386.705,-2261.621;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.DotProductOpNode;299;2273.575,-565.6318;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;534;3514.105,606.7371;Inherit;False;Property;_EmiBlendSpeed;EmiBlendSpeed;55;0;Create;True;0;0;0;False;0;False;0,0;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.TransformDirectionNode;384;393.3452,207.6537;Inherit;False;Tangent;World;True;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;814;3952.219,2268.459;Inherit;True;Property;_RimMask;RimMask(B);68;1;[Header];Create;False;1;__________________RimLight____________________________________________________________________________________________;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;937;1487.077,370.6698;Inherit;False;Constant;_Float0;Float 0;46;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;745;1959.522,-292.2901;Inherit;False;FixLightHeight;-1;;228;38674e54ca9510a46bffe97b4729b4a5;0;2;1;FLOAT3;0,0,0;False;2;FLOAT;0.6;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;939;1637.808,72.83121;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;995;4745.235,-887.294;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;560;3256.781,-120.909;Inherit;False;Property;_ShadowMaskPower;ShadowMaskPower;43;0;Create;True;0;0;0;False;0;False;1;1;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;907;4295.921,-1697.642;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1051;3908.031,-2201.772;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;934;1538.403,193.9921;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SampleSHNode;567;4386.431,1315.308;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;506;3122.313,1748.548;Inherit;False;Property;_SpecularMaskRange02;SpecularMaskRange02;66;0;Create;True;0;0;0;False;0;False;-0.1;-1;-1;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;823;3787.555,-339.9495;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DecodeLightColorNode;895;4557.382,1034.395;Inherit;False;0;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;1108;4935.071,-3636.235;Inherit;False;FLOAT4;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;1101;4296.222,-3531.109;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1000;False;1;FLOAT;0
Node;AmplifyShaderEditor.DecodeLightDirectionNode;894;1567.571,-280.6754;Inherit;False;0;1;FLOAT4;0
Node;AmplifyShaderEditor.RangedFloatNode;1050;3713.031,-2104.771;Inherit;False;Property;_OutlineCullWith;OutlineCullWith;74;1;[Header];Create;True;1;___________________OutlineCullFix____________________________________________________________________________________________;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;433;3556.433,2321.281;Inherit;False;Property;_RimLightSoft;RimLightSoft;71;0;Create;True;0;0;0;False;0;False;0.2;0.101;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;395;3656.387,389.993;Inherit;False;Property;_EmissivePower;EmissivePower;52;0;Create;True;0;0;0;False;0;False;1;0;0;20;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;421;3895.494,1118.164;Inherit;False;4;4;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.Vector3Node;608;4511.866,1163.353;Inherit;False;Constant;_Vector0;Vector 0;48;0;Create;True;0;0;0;False;0;False;1,1,1;0,0,0;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;820;3527.114,-277.0332;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;963;4514.931,-2944.584;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;998;4402.229,-1234.328;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RGBToHSVNode;991;4180.032,-1095.624;Inherit;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.TexturePropertyNode;1045;2488.767,-2476.282;Inherit;True;Property;_LutTexture;LutTexture;11;0;Create;True;0;0;0;False;0;False;None;None;False;white;Auto;Texture2D;-1;0;2;SAMPLER2D;0;SAMPLERSTATE;1
Node;AmplifyShaderEditor.LerpOp;979;4640.404,-2558.725;Inherit;False;3;0;FLOAT;1;False;1;FLOAT;0;False;2;FLOAT;0.5;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;434;4874.377,978.5336;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;1019;2548.841,-2271.337;Inherit;False;Property;_LutBrightnessFix;LutBrightnessFix;12;0;Create;True;0;0;0;False;0;False;0.98;0.98;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.StepOpNode;941;1650.222,428.5652;Inherit;False;2;0;COLOR;0,0,0,0;False;1;FLOAT;0.5;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;1054;4158.631,-2103.571;Inherit;False;Property;_OutlineCullFix;OutlineCullFix;75;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;953;-252.4602,269.9587;Inherit;False;Property;_NormalIntensity;NormalIntensity;29;0;Create;True;0;0;0;False;0;False;1;0;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.Vector2Node;537;3335.212,489.8618;Inherit;False;Property;_EmiBlendTiling;EmiBlendTiling;54;0;Create;True;0;0;0;False;0;False;1,1;0,0;0;3;FLOAT2;0;FLOAT;1;FLOAT;2
Node;AmplifyShaderEditor.SwizzleNode;902;3156.947,-1512.752;Inherit;False;FLOAT3;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SamplerNode;493;3533.145,1357.302;Inherit;True;Property;_SpecularMask;SpecularMask(G);57;0;Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.PosVertexDataNode;1119;5006.411,-2736.776;Inherit;False;0;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;305;2211.488,-326.3843;Inherit;False;Property;_DarkRange;DarkRange;7;0;Create;True;0;0;0;False;0;False;0.2;0.432;-1;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;929;5417.187,-979.4321;Inherit;False;2;2;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SimpleAddOpNode;424;4189.536,1002.175;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;987;3277.752,-1081.656;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;444;3875.43,2010.28;Inherit;True;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;944;1794.265,426.6145;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;443;3459.299,2095.346;Inherit;True;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GammaToLinearNode;1027;3181.374,-2559.259;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;989;3592.817,-1019.874;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1066;686.9554,-2139.222;Inherit;False;1084;totalFrames;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;984;3232.468,-992.0004;Inherit;False;Constant;_Float7;Float 7;10;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;825;2533.347,-819.3382;Inherit;False;Property;_RampBlend;RampBlend;33;0;Create;True;0;0;0;False;0;False;1;1;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;988;3138.752,-1062.656;Inherit;False;Constant;_Float6;Float 6;48;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.CameraDepthFade;974;4399.374,-2537.937;Inherit;False;3;2;FLOAT3;0,0,0;False;0;FLOAT;1;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;510;4171.366,1459.647;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;1;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;437;4062.431,2099.281;Inherit;False;Property;_RimLightColor;RimLightColor;69;0;Create;True;1;__________________RimLight____________________________________________________________________________________________;0;0;False;0;False;0,0,0,0;0.4708971,0.6365787,0.6981132,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;1052;4032.031,-2207.772;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;487;772.3089,578.9018;Inherit;False;Property;_MatcapBlend;MatcapBlend;48;0;Create;False;0;0;0;False;0;False;1;0.434;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;1067;408.9119,-2100.179;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;461;2951.843,2084.075;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;961;3960.278,-3322.792;Inherit;False;World;True;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;946;1794.787,82.49197;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;856;4291.474,479.4138;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;886;2237.857,-96.31665;Inherit;False;Property;_VertexColorAlphaFixDarkRange;VertexColorAlphaFixDarkRange;9;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;958;4742.09,-2770.892;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1099;4477.086,-3653.216;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;943;2110.403,308.3839;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;962;5219.387,-3040.553;Inherit;False;Property;_OutlineWidth;OutlineWidth;25;0;Create;True;1;;0;0;False;0;False;0.1;0.549;0;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;397;5436.805,17.53474;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;492;1024.11,242.9297;Inherit;False;Property;_MatcapPower;MatcapPower;47;0;Create;False;0;0;0;False;0;False;1;0.98;0;35;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;1100;4275.086,-3677.216;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;977;4679.547,-2922.624;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;947;2034.952,71.32706;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.TransformPositionNode;1104;4604.071,-3661.235;Inherit;False;World;View;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.WorldSpaceCameraPos;1117;5117.045,-2897.554;Inherit;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.LerpOp;919;5079.774,-1711.558;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;1107;4520.071,-3465.235;Inherit;False;Property;_ViewZoffset;ViewZoffset;76;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;970;5494.656,-3040.286;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1000;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;595;3197.7,1841.072;Inherit;False;Property;_SpecularSoft02;SpecularSoft02;67;0;Create;True;0;0;0;False;0;False;50;50;0;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1131;2206.452,-2075.705;Inherit;False;Property;_UseExpression;UseExpression;13;2;[Header];[Toggle];Create;True;1;___________________SequentialTex____________________________________________________________________________________________;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;1120;5172.317,-2741.897;Inherit;False;Object;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;965;3843.309,-3187.06;Inherit;False;Property;_OutlineZ1;OutlineOffsetY;27;0;Create;False;0;0;0;False;0;False;0;0;-2;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;1118;5393.226,-2833.502;Inherit;False;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;1000;4494.896,-1090.328;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;562;3102.243,-172.2254;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalVertexDataNode;960;5431.498,-3194.2;Inherit;False;0;5;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;964;5671.497,-3178.2;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;428;3744.842,995.5255;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;1053;4166.031,-2208.772;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;969;4103.672,-3179.737;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;100;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;462;2786.035,2218.01;Inherit;False;Property;_RimOffset;RimOffset;72;0;Create;True;0;0;0;False;0;False;0.16;0.19;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;252;2108.96,-1469.968;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;313;2979.597,-412.0117;Inherit;False;Property;_DarkColor;DarkColor;6;0;Create;True;0;0;0;False;0;False;0.9056604,0.8330367,0.8330367,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;956;2082.625,-1078.644;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.01;False;2;FLOAT;0.99;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;1113;4941.117,-3468.536;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DynamicAppendNode;1075;1241.125,-2312.42;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.HSVToRGBNode;994;4634.132,-1091.029;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;997;4234.229,-1244.328;Inherit;False;Property;_Brightness;Brightness;39;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;972;4412.187,-2762.992;Inherit;True;Property;_OutlineMask;OutlineMask;22;1;[Header];Create;True;1;__________________Outline____________________________________________________________________________________________;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;973;4238.372,-2516.937;Inherit;False;Constant;_Float5;Float 5;66;0;Create;True;0;0;0;False;0;False;2;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;1071;1632.182,-2338.626;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1001;4386.896,-1094.328;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DecodeEnvSplitFlagNode;923;4589.945,1401.979;Inherit;False;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;307;2487.982,-336.5942;Inherit;False;Property;_DarkSoft;DarkSoft;8;0;Create;True;0;0;0;False;0;False;0.1;0.035;0;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;304;2597,-481;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;959;4228.927,-3249.789;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1006;660.9554,-2328.222;Inherit;False;Property;_Rows;Rows;17;0;Create;True;0;0;0;False;0;False;4;4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;854;5154.612,284.8298;Inherit;False;AlphaActor;0;;229;92bf20db17d0d2b46abe078b3b0cece6;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;496;3856.403,1405.305;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;440;3235.433,2010.28;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;253;2325.652,-910.3548;Inherit;False;Property;_RampColor;RampColor;31;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.LerpOp;1060;5174.749,-2192.45;Inherit;False;3;0;FLOAT;1;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;917;4652.926,-1569.193;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1106;4702.071,-3483.235;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.TransformPositionNode;1105;5082.77,-3632.934;Inherit;False;View;World;False;Fast;True;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1055;4328.03,-2159.772;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;422;3597.515,1114.495;Inherit;False;Property;_SpecularColor;SpecularColor;58;0;Create;True;0;0;0;False;0;False;1,1,1,0;0.6581524,0.9622641,0.8877704,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DotProductOpNode;1049;3668.031,-2313.772;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;558;3930.787,-395.6712;Inherit;False;Property;_UseShadowMask;UseShadowMask;40;0;Create;True;0;0;0;False;1;Header(__________________ShadowMask____________________________________________________________________________________________);False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;911;4518.876,-1560.163;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;488;836.836,166.1059;Inherit;False;Property;_MatcapColor;MatcapColor;46;0;Create;False;0;0;0;False;0;False;1,1,1,0;1,1,1,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ColorNode;824;2624.969,-1109.391;Inherit;False;Constant;_Color1;Color 1;47;0;Create;True;0;0;0;False;0;False;1,1,1,1;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;1095;675.814,-1868.152;Inherit;False;Property;_UseSetKey;UseSetKey;20;1;[Toggle];Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;251;1846.758,-1501.23;Inherit;False;Property;_BaseColor;BaseColor;4;0;Create;True;0;0;0;False;0;False;1,1,1,0;1,1,1,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TextureCoordinatesNode;535;3513.833,471.5457;Inherit;False;0;-1;2;3;2;SAMPLER2D;;False;0;FLOAT2;1,1;False;1;FLOAT2;0,0;False;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;445;4091.532,2011.412;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RegisterLocalVarNode;1084;972.1526,-2377.031;Float;False;totalFrames;-1;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.CustomExpressionNode;1035;2857.086,-2558.793;Inherit;False;$// 采样原图$float4 col = Texcolor@$$// 初始化最终颜色（默认返回原图，开关为1时再替换为校色后颜色）$float3 finalColor = col.rgb@$$$// 仅当开关为1时，执行LUT校色逻辑（开关为0时跳过，直接输出原图）$if (_LutEnable > 0.5) ${$    // 通道映射（R→U, G→V, B→W）$    float u = col.r@$    float v = col.g@$    float w = col.b@$$$    // LUT采样计算$    const int LUT_SIZE = 16@$    float scaleZ = LUT_SIZE - 1.0@$$    // 安全边界处理$    float halfPixel = 0.5 / (LUT_SIZE * LUT_SIZE)@$    float maxSafeU = 1.0 - (1.0 / LUT_SIZE) - halfPixel@$    u = saturate(u)@$    u = min(u, maxSafeU)@$    v = saturate(v)@$    v = clamp(v, halfPixel, 1.0 - halfPixel)@$    w = saturate(w)@$$    // 计算LUT坐标$    w *= scaleZ@$    float stripIndex = floor(w)@$    stripIndex = clamp(stripIndex, 0.0, LUT_SIZE - 1.0)@$    float stripOffset = stripIndex * LUT_SIZE@$$    // 当前条带采样坐标$    float x = (stripOffset + u * LUT_SIZE) / (LUT_SIZE * LUT_SIZE)@$    x = clamp(x, stripOffset / (LUT_SIZE * LUT_SIZE) + halfPixel, $              (stripOffset + LUT_SIZE) / (LUT_SIZE * LUT_SIZE) - halfPixel)@$    float y = v@$$    // 下一条带采样坐标（用于插值）$    float nextStripIndex = min(stripIndex + 1.0, LUT_SIZE - 1.0)@$    float nextStripOffset = nextStripIndex * LUT_SIZE@$    float x2 = (nextStripOffset + u * LUT_SIZE) / (LUT_SIZE * LUT_SIZE)@$    x2 = clamp(x2, nextStripOffset / (LUT_SIZE * LUT_SIZE) + halfPixel, $               (nextStripOffset + LUT_SIZE) / (LUT_SIZE * LUT_SIZE) - halfPixel)@$$    // LUT双线性插值采样$    float4 color1 = tex2D(LutTex, float2(x, y))@$    float4 color2 = tex2D(LutTex, float2(x2, y))@$    float t = saturate(w - stripIndex)@$    float4 correctedColor = lerp(color1, color2, t)@$$    // 亮度补偿（仅校色时生效）$    finalColor = correctedColor.rgb * _BrightnessCompensation@$$    // 颜色范围钳位（仅校色时生效）$    finalColor.r = clamp(finalColor.r, 0.0, 1.0)@$    finalColor.g = clamp(finalColor.g, 0.0, 1.0)@$    finalColor.b = clamp(finalColor.b, 0.0, 1.0)@$}$$$// 输出最终颜色（开关0=原图，1=校色后；始终保留原图Alpha）$return float4(finalColor, col.a)@;4;Create;4;True;Texcolor;FLOAT4;0,0,0,0;In;;Inherit;False;True;LutTex;SAMPLER2D;0,0,0;In;;Inherit;False;True;_BrightnessCompensation;FLOAT;0;In;;Inherit;False;True;_LutEnable;FLOAT;0;In;;Inherit;False;My Custom Expression;True;False;0;;False;4;0;FLOAT4;0,0,0,0;False;1;SAMPLER2D;0,0,0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.DynamicAppendNode;1083;1242.825,-2404.32;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;983;3409.468,-1040;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;935;1686.802,249.9418;Inherit;False;3;3;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;314;3039.743,-502.3484;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;950;1110.868,606.8367;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.UnpackScaleNormalNode;952;52.60295,223.4173;Inherit;False;2;0;FLOAT4;0,0,0,0;False;1;FLOAT;1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SamplerNode;377;-309.6647,67.33983;Inherit;True;Property;_Normalmap;Normalmap;28;2;[Header];[Normal];Create;True;1;__________________Normalmap____________________________________________________________________________________________;0;0;False;0;False;-1;None;None;True;0;True;bump;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;308;2861.015,-481.1523;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.WorldNormalVector;905;3325.641,-1693.869;Inherit;False;False;1;0;FLOAT3;0,0,1;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SaturateNode;597;3681.836,1515.996;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FractNode;1077;982.9559,-2212.222;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;316;4214.403,-482.3137;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;260;1790.502,-1324.73;Inherit;False;Property;_ColorPower;ColorPower;5;0;Create;True;0;0;0;False;0;False;1;1;0;20;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;599;3591.493,985.6595;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;565;2861.762,-937.4848;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.ColorNode;505;3642.22,1748.458;Inherit;False;Property;_SpecularColor02;SpecularColor02;65;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;948;1314.869,245.8367;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ColorNode;393;3694.223,218.0085;Inherit;False;Property;_EmissiveColor;EmissiveColor;51;0;Create;True;0;0;0;False;0;False;1,1,1,1;0.1415094,0.1415094,0.1415094,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;1040;2731.932,-2391.985;Inherit;False;Property;_UseLUT;UseLUT;10;1;[Toggle];Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;489;1376.148,94.96535;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;217;1762.255,-1688.095;Inherit;True;Property;_BaseTex;BaseTex;3;1;[Header];Create;False;1;___________________BaseTex____________________________________________________________________________________________;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.DecodeLightDirectionNode;901;2922.979,-1495.508;Inherit;False;0;1;FLOAT4;0
Node;AmplifyShaderEditor.SamplerNode;218;2258.046,-1103.322;Inherit;True;Property;_RampTex;RampTex;30;2;[Header];[NoScaleOffset];Create;True;1;__________________Ramp____________________________________________________________________________________________;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ClampOpNode;1072;543.9553,-2180.222;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0.0001;False;2;FLOAT;8;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;407;1897.331,-1076.421;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;523;3968.866,498.647;Inherit;True;Property;_EmissiveBlendTex;EmissiveBlendTex;53;1;[NoScaleOffset];Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SwizzleNode;730;1801.539,-297.9193;Inherit;False;FLOAT3;0;1;2;3;1;0;FLOAT4;0,0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;516;5102.985,1007.812;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;FLOAT4;0,0,0,0;False;2;FLOAT3;0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;954;1635.687,-1131.853;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;306;2736,-480;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1092;721.6927,-1978.137;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0.1;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;942;1486.686,457.356;Inherit;False;Constant;_Float1;Float 1;46;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1061;4879.751,-2106.85;Inherit;False;Property;_OutlineCullAlphaClip;OutlineCullAlphaClip;77;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;993;4489.081,-998.3801;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;945;1975.091,336.3821;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;955;1470.687,-1117.854;Inherit;False;Constant;_Float4;Float 4;48;0;Create;True;0;0;0;False;0;False;1;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;436;4279.527,2062.68;Inherit;False;4;4;0;FLOAT;0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1065;1776.181,-2402.626;Inherit;False;2;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.PannerNode;524;3731.75,495.0615;Inherit;True;3;0;FLOAT2;0,0;False;2;FLOAT2;0,0;False;1;FLOAT;1;False;1;FLOAT2;0
Node;AmplifyShaderEditor.FunctionNode;833;674.412,71.50495;Inherit;False;BentMatcapNormal;-1;;226;111106acccbe7a249888e78d98d12562;0;1;1;FLOAT3;0,0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;885;2547.857,-204.3167;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;499;3384.757,1538.92;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;504;3891.405,1561.343;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;254;2622.419,-929.6356;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.OneMinusNode;441;3673.433,2007.28;Inherit;True;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;816;1222.24,398.6721;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;475;3612.758,-624.2743;Inherit;False;Property;_UseSpecular;UseSpecular;56;0;Create;True;0;0;0;False;1;Header(__________________Specular____________________________________________________________________________________________);False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;949;1103.869,314.8367;Inherit;False;Constant;_Float3;Float 3;57;0;Create;True;0;0;0;False;0;False;0.4;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;593;3136.881,1629.777;Inherit;False;Property;_SpecularSoft01;SpecularSoft01;64;0;Create;True;0;0;0;False;0;False;50;50;0;100;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;495;3097.617,1536.736;Inherit;False;Property;_SpecularMaskRange01;SpecularMaskRange01;63;0;Create;True;0;0;0;False;0;False;-0.2;0.5;-1;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;985;3976.722,-854.381;Inherit;False;Property;_RampMaskIntensity;RampMaskIntensity;36;0;Create;True;0;0;0;False;0;False;1;1;0;10;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;1076;871.9554,-2214.222;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;9;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;1080;1096.093,-2161.34;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;538;4003.443,1403.643;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;822;3656.226,-339.0834;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;834;904.005,71.50497;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.RangedFloatNode;1005;644.9553,-2408.222;Inherit;False;Property;_Colums;Colums;16;0;Create;True;0;0;0;False;0;False;4;4;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;598;3822.091,1788.42;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;884;2378.857,-211.3167;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FunctionNode;903;3314.93,-1507.123;Inherit;False;FixLightHeight;-1;;227;38674e54ca9510a46bffe97b4729b4a5;0;2;1;FLOAT3;0,0,0;False;2;FLOAT;0.6;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;1069;1632.182,-2434.626;Inherit;False;2;0;FLOAT2;0,0;False;1;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.SamplerNode;815;807.993,372.7883;Inherit;True;Property;_MatcapMask;MatcapMask(R);49;0;Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;986;3297.885,-918.4598;Inherit;False;Property;_RampMaskRange;RampMaskRange;35;0;Create;True;0;0;0;False;0;False;0.8;0.8;0.1;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;1013;1895.471,-2429.424;Inherit;True;Property;_SequentialTex;SequentialTex;15;0;Create;True;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;976;4879.246,-2947.025;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SaturateNode;790;4526.289,1311.951;Inherit;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;1129;1991.853,-2166.955;Inherit;False;Property;_UseSequential;UseSequential;14;1;[Toggle];Create;True;1;___________________SequentialTex____________________________________________________________________________________________;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;906;5295.768,-1530.801;Inherit;False;3;3;0;FLOAT4;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT3;0,0,0;False;1;FLOAT4;0
Node;AmplifyShaderEditor.SamplerNode;556;2771.954,-223.7468;Inherit;True;Property;_ShadowMask;ShadowMask(R);41;0;Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;1123;5713.581,-2702.373;Inherit;False;Property;_OutlineZoffset;OutlineZoffset;26;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;596;3533.7,1830.072;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;317;3154.935,-633.7056;Inherit;False;2;2;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SamplerNode;391;3627.809,30.15003;Inherit;True;Property;_EmissiveTex;EmissiveTex;50;1;[Header];Create;True;1;__________________Emissive____________________________________________________________________________________________;0;0;False;0;False;-1;None;None;True;0;False;black;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;1048;3464.901,-2227.512;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.ColorNode;497;3669.588,1577.216;Inherit;False;Property;_SpecularColor01;SpecularColor01;62;0;Create;True;0;0;0;False;0;False;0,0,0,0;0,0,0,0;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.RangedFloatNode;978;4408.547,-2835.624;Inherit;False;Property;_OutlineColorBlendIntensity;OutlineColorBlendIntensity;24;0;Create;True;0;0;0;False;0;False;0;0;0;1;0;1;FLOAT;0
Node;AmplifyShaderEditor.ViewDirInputsCoordNode;439;2752.522,2068.813;Inherit;False;World;False;0;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.RangedFloatNode;431;3201.433,2264.281;Inherit;False;Property;_RimLightRange;RimLightRange;70;0;Create;True;0;0;0;False;0;False;0.9;0.984;0;2;0;1;FLOAT;0
Node;AmplifyShaderEditor.OneMinusNode;938;1817.778,250.9418;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleDivideOpNode;909;4027.08,-1687.986;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.FloorOpNode;1079;1513.798,-2260.32;Inherit;False;1;0;FLOAT2;0,0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.StaticSwitch;416;2191.196,41.18754;Inherit;False;Property;_UseMatcap;UseMatcap;44;0;Create;True;0;0;0;False;1;Header(___________________Matcap_________________________________________________________________________________________________);False;0;0;0;True;;Toggle;2;Key0;Key1;Create;False;True;9;1;COLOR;0,0,0,0;False;0;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;3;COLOR;0,0,0,0;False;4;COLOR;0,0,0,0;False;5;COLOR;0,0,0,0;False;6;COLOR;0,0,0,0;False;7;COLOR;0,0,0,0;False;8;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;423;3532.651,1285.58;Inherit;False;Property;_SpecularPower;SpecularPower;61;0;Create;True;0;0;0;False;0;False;1;0.042;0;3;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;930;3989.827,2459.224;Inherit;False;Property;_RimPower;RimPower;73;0;Create;True;0;0;0;False;0;False;1;1;0;20;0;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;563;3263.131,-277.38;Inherit;False;Property;_FilpShadowMask;FlipShadowMask;42;0;Create;False;0;0;0;False;0;False;0;0;0;True;;Toggle;2;Key0;Key1;Create;True;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;555;1660.821,-959.6561;Inherit;False;Property;_RampRange;RampRange;32;0;Create;True;0;0;0;False;0;False;0.8;0.8;0.1;5;0;1;FLOAT;0
Node;AmplifyShaderEditor.DotProductOpNode;904;3578.522,-1679.439;Inherit;True;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1070;822.9553,-2372.222;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;318;3477.605,-506.8843;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;1094;873.9162,-2000.648;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;1047;4549.797,-873.2335;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.ScaleAndOffsetNode;788;4679.896,1236.519;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT;0.6;False;2;FLOAT;0.2;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;419;3384.311,964.8466;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;908;4152.094,-1689.138;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;420;3101.252,984.6335;Inherit;False;Property;_SpecularRange;SpecularRange;59;0;Create;True;0;0;0;False;0;False;-0.75;-0.763;-1;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;1057;4733.649,-2204.592;Inherit;False;3;0;FLOAT;0;False;1;FLOAT;1;False;2;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.StaticSwitch;918;4796.157,-1624.915;Inherit;False;Property;_UseShadowMask;UseShadowMask;40;0;Create;True;0;0;0;False;1;Header(__________________ShadowMask____________________________________________________________________________________________);False;0;0;0;True;;Toggle;2;Key0;Key1;Reference;558;True;True;9;1;FLOAT;0;False;0;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;4;FLOAT;0;False;5;FLOAT;0;False;6;FLOAT;0;False;7;FLOAT;0;False;8;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleSubtractOpNode;1093;590.9111,-1974.92;Inherit;False;2;0;FLOAT;0;False;1;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.LerpOp;641;4888.59,1194.216;Inherit;False;3;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;2;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SaturateNode;999;4517.229,-1234.328;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;594;3521.881,1560.777;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.GetLocalVarNode;1085;235.912,-2105.179;Inherit;False;1084;totalFrames;1;0;OBJECT;;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1116;5993.267,-2951.53;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleAddOpNode;1073;711.9553,-2246.222;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SaturateNode;1056;4460.457,-2154.512;Inherit;False;1;0;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;1007;379.9121,-2186.179;Inherit;False;Property;_StartFrame;StartFrame;18;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;996;4239.08,-956.3794;Inherit;False;Property;_Saturation;Saturation;38;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.SamplerNode;381;1060.926,36.67619;Inherit;True;Property;_MatcapTex;MatcapTex;45;1;[NoScaleOffset];Create;False;0;0;0;False;0;False;-1;None;None;True;0;False;white;Auto;False;Object;-1;Auto;Texture2D;8;0;SAMPLER2D;;False;1;FLOAT2;0,0;False;2;FLOAT;0;False;3;FLOAT2;0,0;False;4;FLOAT2;0,0;False;5;FLOAT;1;False;6;FLOAT;0;False;7;SAMPLERSTATE;;False;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.VertexColorNode;883;2199.095,-250.7495;Inherit;False;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SaturateNode;1030;2308.493,-1393.094;Inherit;False;1;0;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.LinearToGammaNode;1028;2663.173,-2558.759;Inherit;False;0;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;920;4303.355,-1907.892;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;COLOR;0,0,0,0;False;1;COLOR;0
Node;AmplifyShaderEditor.RangedFloatNode;1008;371.9121,-2261.179;Inherit;False;Property;_FrameSpeed;FrameSpeed;19;0;Create;True;0;0;0;False;0;False;1;1;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;553;1585.404,-1028.195;Inherit;False;Constant;_dotfix;dotfix;10;0;Create;True;0;0;0;False;0;False;0.5;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;1121;5523.557,-2832.599;Inherit;False;True;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;390;4073.724,194.6328;Inherit;False;3;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.DynamicAppendNode;1068;1244.825,-2213.321;Inherit;False;FLOAT2;4;0;FLOAT;0;False;1;FLOAT;0;False;2;FLOAT;0;False;3;FLOAT;0;False;1;FLOAT2;0
Node;AmplifyShaderEditor.LerpOp;1132;2418.885,-2121.468;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.LerpOp;1128;2201.062,-2210.44;Inherit;False;3;0;COLOR;0,0,0,0;False;1;COLOR;0,0,0,0;False;2;FLOAT;0;False;1;COLOR;0
Node;AmplifyShaderEditor.SimpleAddOpNode;910;3845.079,-1722.986;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.NormalizeNode;776;253.3382,211.7846;Inherit;False;False;1;0;FLOAT3;0,0,0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.RangedFloatNode;1090;404.263,-1981.205;Inherit;False;Property;_SetKey;SetKey;21;0;Create;True;0;0;0;False;0;False;0;0;0;0;0;1;FLOAT;0
Node;AmplifyShaderEditor.RangedFloatNode;427;3268.215,1074.547;Inherit;False;Property;_SpecularSoft;SpecularSoft;60;0;Create;True;0;0;0;False;0;False;5;0.15;0;50;0;1;FLOAT;0
Node;AmplifyShaderEditor.TransformDirectionNode;1127;5686.349,-2871.687;Inherit;False;World;Object;True;Fast;False;1;0;FLOAT3;0,0,0;False;4;FLOAT3;0;FLOAT;1;FLOAT;2;FLOAT;3
Node;AmplifyShaderEditor.SimpleAddOpNode;509;3427.568,1731.759;Inherit;False;2;2;0;FLOAT;0;False;1;FLOAT;0;False;1;FLOAT;0
Node;AmplifyShaderEditor.SimpleMultiplyOpNode;1122;5952.286,-2810.255;Inherit;False;2;2;0;FLOAT3;0,0,0;False;1;FLOAT;0;False;1;FLOAT3;0
Node;AmplifyShaderEditor.ColorNode;971;4196.883,-2898.776;Inherit;False;Property;_OutlineColor;OutlineColor;23;1;[Header];Create;True;1;__________________Outline____________________________________________________________________________________________;0;0;False;0;False;0.2075472,0.2075472,0.2075472,0;0.7075471,0.3708804,0.3448735,1;True;0;5;COLOR;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.TexCoordVertexDataNode;1074;1370.705,-2482.626;Inherit;False;0;2;0;5;FLOAT2;0;FLOAT;1;FLOAT;2;FLOAT;3;FLOAT;4
Node;AmplifyShaderEditor.SimpleTimeNode;1081;532.9112,-2255.179;Inherit;False;1;0;FLOAT;1;False;1;FLOAT;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;898;5342.896,670.3017;Float;False;False;1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;896;5342.896,670.3017;Float;False;False;1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=SRPDefaultUnlit;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;342;5616.286,9.153087;Half;False;True;-1;2;ParaMaterialEditor;500;3;Douyin/AI/Cartoon/AvatarNPR_AIHaiHai;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;7;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;0;False;True;0;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;True;True;0;False;-8;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;True;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;3;LightMode=UniversalForward;RenderPipeline=UniversalRenderPipeline;RenderType=Opaque=RenderType;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;0;LOD CrossFade;0;Built-in Fog;1;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;1;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;True;True;True;False;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;345;4008.388,-780.3983;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;341;6150.981,-3033.332;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;3;LightMode=SRPDefaultUnlit;RenderType=Opaque=RenderType;Queue=AlphaTest=Queue=0;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;924;5471.958,-1320.756;Float;False;False;0;2;UnityEditor.ShaderGraph.PBRMasterGUI;100;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ExtraPrePass;0;0;ExtraPrePass;5;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;True;1;1;False;-1;0;False;-1;0;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=SRPDefaultUnlit;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;899;5342.896,670.3017;Float;False;False;1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;344;4008.388,-780.3983;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;343;4008.388,-780.3983;Float;False;False;-1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;925;5580.667,-986.2673;Half;False;True;0;2;ParaMaterialEditor;400;3;Douyin/AI/Cartoon/AvatarNPR_AIHaiHai;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;7;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;True;-8;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;0;LOD CrossFade;0;Built-in Fog;1;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;True;False;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;927;5471.958,-1320.756;Float;False;False;0;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;DepthOnly;0;3;DepthOnly;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;True;False;False;False;False;0;False;-1;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;False;True;1;LightMode=DepthOnly;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;897;5556.783,-1492.205;Half;False;True;1;2;ParaMaterialEditor;300;3;Douyin/AI/Cartoon/AvatarNPR_AIHaiHai;2992e84f91cbeb14eab234972e07ea9d;True;Forward;0;1;Forward;8;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;7;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;0;False;True;1;1;False;-1;0;False;-1;1;1;False;-1;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;True;0;True;-8;False;True;True;True;True;True;0;False;-1;False;False;False;False;False;False;False;True;False;255;False;-1;255;False;-1;255;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;7;False;-1;1;False;-1;1;False;-1;1;False;-1;False;True;1;False;-1;True;3;False;-1;True;True;0;False;-1;0;False;-1;True;1;LightMode=UniversalForward;False;False;0;Hidden/InternalErrorShader;0;0;Standard;22;Surface;0;  Blend;0;Two Sided;1;Cast Shadows;1;  Use Shadow Threshold;0;Receive Shadows;1;GPU Instancing;0;LOD CrossFade;0;Built-in Fog;1;DOTS Instancing;0;Meta Pass;0;Extra Pre Pass;0;Tessellation;0;  Phong;0;  Strength;0.5,False,-1;  Type;0;  Tess;16,False,-1;  Min;10,False,-1;  Max;25,False,-1;  Edge Length;16,False,-1;  Max Displacement;25,False,-1;Vertex Position,InvertActionOnDeselection;1;0;5;False;True;True;False;False;False;;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;928;5471.958,-1320.756;Float;False;False;0;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;926;5471.958,-1320.756;Float;False;False;0;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;ShadowCaster;0;2;ShadowCaster;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;False;-1;True;3;False;-1;False;True;1;LightMode=ShadowCaster;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
Node;AmplifyShaderEditor.TemplateMultiPassMasterNode;900;5342.896,670.3017;Float;False;False;1;2;UnityEditor.ShaderGraph.PBRMasterGUI;0;3;New Amplify Shader;2992e84f91cbeb14eab234972e07ea9d;True;Meta;0;4;Meta;0;False;False;False;False;False;False;False;False;False;False;False;False;True;0;False;-1;False;True;0;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;3;RenderPipeline=UniversalPipeline;RenderType=Opaque=RenderType;Queue=Geometry=Queue=0;True;0;True;17;d3d9;d3d11;glcore;gles;gles3;metal;vulkan;xbox360;xboxone;xboxseries;ps4;playstation;psp2;n3ds;wiiu;switch;nomrt;0;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;2;False;-1;False;False;False;False;False;False;False;False;False;False;False;False;False;False;True;1;LightMode=Meta;False;False;0;Hidden/InternalErrorShader;0;0;Standard;0;False;0
WireConnection;990;0;989;0
WireConnection;554;0;954;0
WireConnection;554;1;553;0
WireConnection;992;0;991;2
WireConnection;992;1;996;0
WireConnection;982;0;981;1
WireConnection;982;1;985;0
WireConnection;936;0;489;0
WireConnection;981;1;990;0
WireConnection;1082;0;1075;0
WireConnection;1082;1;1068;0
WireConnection;299;0;384;0
WireConnection;299;1;745;0
WireConnection;384;0;776;0
WireConnection;745;1;730;0
WireConnection;939;0;1027;0
WireConnection;939;1;489;0
WireConnection;939;2;937;0
WireConnection;995;0;994;0
WireConnection;995;1;318;0
WireConnection;995;2;1047;0
WireConnection;907;0;908;0
WireConnection;1051;0;1049;0
WireConnection;1051;1;1050;0
WireConnection;934;0;1027;0
WireConnection;823;0;822;0
WireConnection;1108;0;1104;1
WireConnection;1108;1;1104;2
WireConnection;1108;2;1113;0
WireConnection;421;0;428;0
WireConnection;421;1;422;0
WireConnection;421;2;423;0
WireConnection;421;3;493;2
WireConnection;820;0;563;0
WireConnection;820;1;560;0
WireConnection;963;0;1027;0
WireConnection;963;1;971;0
WireConnection;998;0;997;0
WireConnection;998;1;991;3
WireConnection;991;0;318;0
WireConnection;979;1;974;0
WireConnection;434;0;316;0
WireConnection;434;1;436;0
WireConnection;941;0;489;0
WireConnection;941;1;942;0
WireConnection;902;0;901;0
WireConnection;929;0;906;0
WireConnection;929;1;856;0
WireConnection;424;0;317;0
WireConnection;424;1;510;0
WireConnection;987;0;299;0
WireConnection;987;1;988;0
WireConnection;444;0;441;0
WireConnection;444;1;433;0
WireConnection;944;0;941;0
WireConnection;443;0;440;0
WireConnection;443;1;431;0
WireConnection;1027;0;1035;0
WireConnection;989;0;983;0
WireConnection;989;1;986;0
WireConnection;974;0;973;0
WireConnection;510;0;538;0
WireConnection;510;1;505;0
WireConnection;510;2;504;0
WireConnection;1052;0;1051;0
WireConnection;1067;0;1085;0
WireConnection;461;0;439;0
WireConnection;461;2;462;0
WireConnection;946;0;939;0
WireConnection;946;1;941;0
WireConnection;856;0;390;0
WireConnection;856;1;523;0
WireConnection;1099;0;1100;0
WireConnection;1099;1;1101;0
WireConnection;943;0;946;0
WireConnection;943;1;945;0
WireConnection;397;0;856;0
WireConnection;397;1;516;0
WireConnection;977;0;963;0
WireConnection;977;1;971;0
WireConnection;977;2;978;0
WireConnection;947;0;1027;0
WireConnection;947;1;943;0
WireConnection;947;2;816;0
WireConnection;1104;0;1099;0
WireConnection;919;0;1027;0
WireConnection;919;1;920;0
WireConnection;919;2;918;0
WireConnection;970;0;962;0
WireConnection;1120;0;1119;0
WireConnection;1118;0;1117;0
WireConnection;1118;1;1120;0
WireConnection;1000;0;1001;0
WireConnection;562;0;556;1
WireConnection;964;0;960;0
WireConnection;964;1;970;0
WireConnection;428;0;599;0
WireConnection;1053;0;1052;0
WireConnection;969;0;965;0
WireConnection;252;0;217;0
WireConnection;252;1;251;0
WireConnection;252;2;260;0
WireConnection;956;0;407;0
WireConnection;1113;0;1104;3
WireConnection;1113;1;1106;0
WireConnection;1113;2;1057;0
WireConnection;1075;0;1084;0
WireConnection;1075;1;1006;0
WireConnection;994;0;1000;0
WireConnection;994;1;993;0
WireConnection;994;2;999;0
WireConnection;1071;0;1079;0
WireConnection;1071;1;1083;0
WireConnection;1001;0;1002;0
WireConnection;1001;1;991;1
WireConnection;304;0;299;0
WireConnection;304;1;885;0
WireConnection;959;0;961;3
WireConnection;959;1;969;0
WireConnection;496;0;493;2
WireConnection;496;1;597;0
WireConnection;440;0;384;0
WireConnection;440;1;461;0
WireConnection;1060;0;854;0
WireConnection;1060;1;1057;0
WireConnection;1060;2;1061;0
WireConnection;917;0;911;0
WireConnection;1106;0;1104;3
WireConnection;1106;1;1107;0
WireConnection;1105;0;1108;0
WireConnection;1055;0;1052;0
WireConnection;1055;1;1054;0
WireConnection;1049;0;384;0
WireConnection;1049;1;1048;0
WireConnection;558;1;314;0
WireConnection;558;0;823;0
WireConnection;911;0;907;0
WireConnection;911;1;820;0
WireConnection;535;0;537;0
WireConnection;445;0;444;0
WireConnection;1084;0;1070;0
WireConnection;1035;0;1028;0
WireConnection;1035;1;1045;0
WireConnection;1035;2;1019;0
WireConnection;1035;3;1040;0
WireConnection;1083;0;1005;0
WireConnection;1083;1;1006;0
WireConnection;983;0;987;0
WireConnection;983;1;984;0
WireConnection;935;0;934;0
WireConnection;935;1;936;0
WireConnection;935;2;937;0
WireConnection;314;0;308;0
WireConnection;950;0;487;0
WireConnection;950;1;951;0
WireConnection;952;0;377;0
WireConnection;952;1;953;0
WireConnection;308;0;306;0
WireConnection;597;0;594;0
WireConnection;1077;0;1076;0
WireConnection;316;0;475;0
WireConnection;316;1;995;0
WireConnection;316;2;558;0
WireConnection;599;0;419;0
WireConnection;599;1;427;0
WireConnection;565;0;824;0
WireConnection;565;1;254;0
WireConnection;565;2;825;0
WireConnection;948;0;492;0
WireConnection;948;1;949;0
WireConnection;489;0;381;0
WireConnection;489;1;488;0
WireConnection;489;2;948;0
WireConnection;218;1;956;0
WireConnection;1072;0;1007;0
WireConnection;1072;2;1067;0
WireConnection;407;0;554;0
WireConnection;407;1;555;0
WireConnection;523;1;524;0
WireConnection;730;0;894;0
WireConnection;516;0;434;0
WireConnection;516;1;895;0
WireConnection;516;2;641;0
WireConnection;954;0;299;0
WireConnection;954;1;955;0
WireConnection;306;0;304;0
WireConnection;306;1;307;0
WireConnection;1092;0;1093;0
WireConnection;993;0;992;0
WireConnection;945;0;938;0
WireConnection;945;1;944;0
WireConnection;436;0;445;0
WireConnection;436;1;437;0
WireConnection;436;2;814;3
WireConnection;436;3;930;0
WireConnection;1065;0;1069;0
WireConnection;1065;1;1071;0
WireConnection;524;0;535;0
WireConnection;524;2;534;0
WireConnection;833;1;384;0
WireConnection;885;0;305;0
WireConnection;885;1;884;0
WireConnection;885;2;886;0
WireConnection;499;0;419;0
WireConnection;499;1;495;0
WireConnection;504;0;493;2
WireConnection;504;1;598;0
WireConnection;254;0;218;0
WireConnection;254;1;253;0
WireConnection;441;0;443;0
WireConnection;816;0;950;0
WireConnection;816;1;815;1
WireConnection;475;1;317;0
WireConnection;475;0;424;0
WireConnection;1076;0;1094;0
WireConnection;1076;1;1066;0
WireConnection;1080;0;1077;0
WireConnection;538;0;421;0
WireConnection;538;1;497;0
WireConnection;538;2;496;0
WireConnection;822;0;314;0
WireConnection;822;1;820;0
WireConnection;834;0;833;0
WireConnection;598;0;596;0
WireConnection;884;0;305;0
WireConnection;884;1;883;4
WireConnection;903;1;902;0
WireConnection;1069;0;1074;0
WireConnection;1069;1;1083;0
WireConnection;1013;1;1065;0
WireConnection;976;0;977;0
WireConnection;790;0;567;0
WireConnection;906;0;895;0
WireConnection;906;1;919;0
WireConnection;906;2;641;0
WireConnection;596;0;509;0
WireConnection;596;1;595;0
WireConnection;317;0;565;0
WireConnection;317;1;416;0
WireConnection;938;0;935;0
WireConnection;909;0;910;0
WireConnection;909;1;307;0
WireConnection;1079;0;1082;0
WireConnection;416;1;1027;0
WireConnection;416;0;947;0
WireConnection;563;1;556;1
WireConnection;563;0;562;0
WireConnection;904;0;905;0
WireConnection;904;1;903;0
WireConnection;1070;0;1005;0
WireConnection;1070;1;1006;0
WireConnection;318;0;565;0
WireConnection;318;1;313;0
WireConnection;318;2;416;0
WireConnection;1094;0;1073;0
WireConnection;1094;1;1092;0
WireConnection;1094;2;1095;0
WireConnection;1047;0;982;0
WireConnection;788;0;790;0
WireConnection;419;0;299;0
WireConnection;419;1;420;0
WireConnection;908;0;909;0
WireConnection;1057;2;1056;0
WireConnection;918;1;907;0
WireConnection;918;0;917;0
WireConnection;1093;0;1090;0
WireConnection;641;0;608;0
WireConnection;641;1;788;0
WireConnection;641;2;923;0
WireConnection;999;0;998;0
WireConnection;594;0;499;0
WireConnection;594;1;593;0
WireConnection;1116;0;964;0
WireConnection;1116;1;1122;0
WireConnection;1073;0;1081;0
WireConnection;1073;1;1072;0
WireConnection;1056;0;1055;0
WireConnection;381;1;834;0
WireConnection;1030;0;252;0
WireConnection;1028;0;1132;0
WireConnection;920;0;1027;0
WireConnection;920;1;313;0
WireConnection;1121;0;1118;0
WireConnection;390;0;391;0
WireConnection;390;1;393;0
WireConnection;390;2;395;0
WireConnection;1068;0;1077;0
WireConnection;1068;1;1080;0
WireConnection;1132;0;1030;0
WireConnection;1132;1;1128;0
WireConnection;1132;2;1131;0
WireConnection;1128;0;1030;0
WireConnection;1128;1;1013;0
WireConnection;1128;2;1129;0
WireConnection;910;0;885;0
WireConnection;910;1;904;0
WireConnection;776;0;952;0
WireConnection;1127;0;1121;0
WireConnection;509;0;499;0
WireConnection;509;1;506;0
WireConnection;1122;0;1127;0
WireConnection;1122;1;1123;0
WireConnection;1081;0;1008;0
WireConnection;342;2;397;0
WireConnection;342;3;854;0
WireConnection;341;0;976;0
WireConnection;341;1;854;0
WireConnection;341;3;1116;0
WireConnection;925;2;929;0
WireConnection;925;3;854;0
WireConnection;897;2;906;0
WireConnection;897;3;854;0
ASEEND*/
//CHKSM=D1EC6DE1A1C7709E8AE1FC7FE0AC9992AB49A348
