Shader "SupGames/Mobile/PostProcessURP"
{
	Properties
	{
		_MainTex("Base (RGB)", 2D) = "" {}
	}

	HLSLINCLUDE

	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
	#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
	#define lum half3(0.212673h, 0.715152h, 0.072175h)
	#define hal half3(0.5h, 0.5h, 0.5h)

	uniform TEXTURE2D_X(_MainTex);
	SAMPLER(sampler_MainTex);
	uniform TEXTURE3D(_LutTex);
	SAMPLER(sampler_LutTex);
	uniform TEXTURE2D_X(_MaskTex);
	SAMPLER(sampler_MaskTex);
	uniform TEXTURE2D_X(_BlurTex);
	SAMPLER(sampler_BlurTex);

	uniform half			_LutAmount;
	uniform half4			_BloomColor;
	uniform half			_BlurAmount;
	uniform half			_BloomDiffuse;
	uniform half4			_Color;
	uniform half4			_BloomData;		// Vector4(bloomThreshold, bloomThreshold - knee, 2f * knee, 1f / (4f * knee + 0.00001f)))
	uniform half			_Contrast;
	uniform half			_Brightness;
	uniform half			_Saturation;
	uniform half			_CentralFactor;
	uniform half			_SideFactor;
	uniform half			_Offset;
	uniform half			_FishEye;
	uniform half			_LensDistortion;
	uniform half4			_VignetteColor;
	uniform half			_VignetteAmount;
	uniform half			_VignetteSoftness;
	uniform half4			_MainTex_TexelSize;
	float					_ContrastThreshold, _RelativeThreshold;

	struct appdata
	{
		half4 pos			: POSITION;
		half2 uv			: TEXCOORD0;
		UNITY_VERTEX_INPUT_INSTANCE_ID
	};

	struct Interpolators 
	{
		float4 pos			: SV_POSITION;
		float2 uv			: TEXCOORD0;
	};

	struct v2fb
	{
		half4 pos			: SV_POSITION;
		half4 uv			: TEXCOORD0;
		UNITY_VERTEX_INPUT_INSTANCE_ID
		UNITY_VERTEX_OUTPUT_STEREO
	};

	struct v2f 
	{
		half4 pos			: SV_POSITION;
		half4 uv			: TEXCOORD0;
		half4 uv1			: TEXCOORD1;
		half4 uv2			: TEXCOORD2;
		half2 uv3			: TEXCOORD3;
		UNITY_VERTEX_INPUT_INSTANCE_ID
		UNITY_VERTEX_OUTPUT_STEREO
	};

	Interpolators VertexProgram (appdata v) 
	{
		Interpolators i;
		UNITY_SETUP_INSTANCE_ID(v);
		UNITY_TRANSFER_INSTANCE_ID(v, i);
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(i);
		i.pos				= mul(unity_MatrixVP, mul(unity_ObjectToWorld, half4(v.pos.xyz, 1.0h)));
		i.uv				= UnityStereoTransformScreenSpaceTex(v.uv);
		return i;
	}

	float4 FXAAQualityFragement(Interpolators interpolators) : SV_Target
	{
		UNITY_SETUP_INSTANCE_ID(interpolators);
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(interpolators);
		float2 UV			= interpolators.uv;
		float2 TexelSize	= _MainTex_TexelSize.xy;
		float4 Origin		= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, UV);
		float M				= Luminance(Origin);
		float NW			= Luminance(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, UV + float2(-TexelSize.x,  TexelSize.y) * 0.5));
		float NE			= Luminance(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, UV + float2( TexelSize.x,  TexelSize.y) * 0.5));
		float SW			= Luminance(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, UV + float2(-TexelSize.x, -TexelSize.y) * 0.5));
		float SE			= Luminance(SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, UV + float2( TexelSize.x, -TexelSize.y) * 0.5));

		float MaxLuma		= max(max(NW, NE), max(SW, SE));
		float MinLuma		= min(min(NW, NE), min(NW, NE));
		float Contrast		= max(MaxLuma, M) -  min(MinLuma, M);
			
		if(Contrast < max(_ContrastThreshold, MaxLuma * _RelativeThreshold))
		{
			return Origin;
		}

		NE					+= 1.0f / 384.0f;
		float2 Dir;
		Dir.x				= -((NW + NE) - (SW + SE));
		Dir.y				= ((NE + SE) - (NW + SW));
		Dir					= normalize(Dir);
			
		#define _Scale 0.5
		float2 Dir1			= Dir * _MainTex_TexelSize.xy * _Scale;

		float4 N1			= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, UV - Dir1);
		float4 P1			= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, UV + Dir1);
		float4 Result		= (N1 + P1) * 0.5;

		#define _Sharpness 8
		float DirAbsMinTimesC = min(abs(Dir1.x), abs(Dir1.y)) * _Sharpness;
		float2 Dir2			= clamp(Dir1.xy / DirAbsMinTimesC, -2.0, 2.0) * 2;
		float4 N2			= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, UV - Dir2 * _MainTex_TexelSize.xy);
		float4 P2			= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, UV + Dir2 * _MainTex_TexelSize.xy);
		float4 Result2		= Result * 0.5f + (N2 + P2) * 0.25f;

		float NewLum		= Luminance(Result2);
		if((NewLum >= MinLuma) && (NewLum <= MaxLuma)) {
			Result			= Result2;
		}
		return Result;
	}


	v2fb vertBlur(appdata i)
	{
		v2fb o;
		UNITY_SETUP_INSTANCE_ID(i);
		UNITY_TRANSFER_INSTANCE_ID(i, o);
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
		o.pos				= mul(unity_MatrixVP, mul(unity_ObjectToWorld, half4(i.pos.xyz, 1.0h)));
		i.uv				= UnityStereoTransformScreenSpaceTex(i.uv);

		half2 offset		= _MainTex_TexelSize.xy * 0.5;
		o.uv				= half4(i.uv - offset, i.uv + offset);
		return o;
	}

	v2f vert(appdata i)
	{
		v2f o;
		UNITY_SETUP_INSTANCE_ID(i);
		UNITY_TRANSFER_INSTANCE_ID(i, o);
		UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

		o.pos				= mul(unity_MatrixVP, mul(unity_ObjectToWorld, half4(i.pos.xyz, 1.0h)));
		o.uv.xy				= UnityStereoTransformScreenSpaceTex(i.uv);
		o.uv.zw				= i.uv;

		o.uv1				= half4(o.uv.xy - _MainTex_TexelSize.xy, o.uv.xy + _MainTex_TexelSize.xy);
		o.uv2.x				= o.uv.x - _Offset * _MainTex_TexelSize.x - 0.5h;
		o.uv2.y				= o.uv.x + _Offset * _MainTex_TexelSize.x - 0.5h;
		o.uv2.zw			= i.uv - 0.5h;
		o.uv3				= o.uv.xy - 0.5h;
		return o;
	}

	half4 fragBlur(v2fb i) : SV_Target
	{
		UNITY_SETUP_INSTANCE_ID(i);
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

		/*
		float2 uv			= i.uv.xy;
		float4 d			= _MainTex_TexelSize.xyxy * float4( -1.0, -1.0, 1.0, 1.0 );
		half4 s;
		s					= (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(uv + d.xy)));
		s				   += (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(uv + d.zy)));
		s				   += (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(uv + d.xw)));
		s				   += (SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, UnityStereoTransformScreenSpaceTex(uv + d.zw)));

		return s * 0.25f;
		*/

		
		half4 b				= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, i.uv.xy);
		b					+= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, i.uv.xw);
		b					+= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, i.uv.zy);
		b					+= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, i.uv.zw);
		return b * 0.25h;
		
	}

	half4 frag(v2f i) : SV_Target
	{
		UNITY_SETUP_INSTANCE_ID(i);
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

		half q				= dot(i.uv2.zw, i.uv2.zw);
		half q2				= sqrt(q);

		#if defined(DISTORTION)
		half q3				= q * _LensDistortion * q2;
		i.uv.xy				= (1.0h + q3) * i.uv3 + hal;
		#endif

		half4 c				= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, i.uv.xy);

		#if defined(BLUR) || defined(BLOOM)
		half4 b				= SAMPLE_TEXTURE2D_X(_BlurTex, sampler_BlurTex, i.uv.xy);
		#endif

		#ifdef BLUR
		half4 m				= SAMPLE_TEXTURE2D_X(_MaskTex, sampler_MaskTex, i.uv.zw);
		#endif

		#ifdef CHROMA
			half r = dot(i.uv2.xw, i.uv2.xw);
			#ifdef DISTORTION
					half2 r2 = (1.0h + r * _FishEye * sqrt(r) + q3) * i.uv2.xw + hal;
			#else
					half2 r2 = (1.0h + r * _FishEye * sqrt(r)) * i.uv2.xw + hal;
			#endif
			c.r = SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, r2).r;
			#ifdef BLUR 
					b.r = SAMPLE_TEXTURE2D_X(_BlurTex, sampler_BlurTex, r2).r;
			#endif
			r = dot(i.uv2.yw, i.uv2.yw);
			#ifdef DISTORTION
					r2 = (1.0h - r * _FishEye * sqrt(r) + q3) * i.uv2.yw + hal;
			#else
					r2 = (1.0h - r * _FishEye * sqrt(r)) * i.uv2.yw + hal;
			#endif
			c.b = SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, r2).b;
			#ifdef BLUR
					b.b = SAMPLE_TEXTURE2D_X(_BlurTex, sampler_BlurTex, r2).b;
			#endif
		#endif

		#if !defined(UNITY_NO_LINEAR_COLORSPACE)
			c.rgb = sqrt(c.rgb);
			#if defined(BLOOM)|| defined(BLUR)
					b.rgb = sqrt(b.rgb);
			#endif
		#endif

		//#if defined(BLUR) || defined(BLOOM)
		//	c += b;
			//c  = b;
		//#endif

		/*#ifdef SHARPEN
			c *= _CentralFactor;
			c -= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, i.uv1.xy) * _SideFactor;
			c -= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, i.uv1.xw) * _SideFactor;
			c -= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, i.uv1.zy) * _SideFactor;
			c -= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, i.uv1.zw) * _SideFactor;
		#endif*/



		#ifdef LUT

			// 3维uvw坐标转2维uv坐标
			//float BLOCKSIZE = 16.0;
			//float u		= floor(c.b * BLOCKSIZE) / BLOCKSIZE * 256.0;
			//u			= floor(c.r * BLOCKSIZE) / BLOCKSIZE * BLOCKSIZE + u;
			//u			/= 255.0;

			//float v		= 1.0 - (floor(c.g * BLOCKSIZE) / BLOCKSIZE );

			//float2 lut		= clamp(float2(u, v), 0, 1.0 );
			float4 mixcolor		= SAMPLE_TEXTURE3D(_LutTex, sampler_LutTex, c.rgb * 0.9375h + 0.03125h);
			c					= lerp(c, mixcolor, _LutAmount);
			#if defined(BLOOM)|| defined(BLUR)
				b			= lerp(b, mixcolor, _LutAmount);
			#endif
		#endif

		//#ifdef BLUR
		//c				= lerp(c, b, m.r);
		//#endif

		// Vector4(bloomThreshold, bloomThreshold - knee, 2f * knee, 1f / (4f * knee + 0.00001f)))
		#ifdef BLOOM
			half br				= max(b.r, max(b.g, b.b));
			half soft			= clamp(br - _BloomData.y, 0.0h, _BloomData.z);

			half rq				= soft * soft * _BloomData.w;
			b					*= max(rq, br - _BloomData.x) / max(br, 0.00001h);

			#if !defined(UNITY_NO_LINEAR_COLORSPACE)
			b.rgb				*= b.rgb;
			#endif
			b					*= (_BloomColor);
			b.rgb				= saturate(b.rgb);

			//c					= c + b;
			c					= 1.0 - (1.0 - c) * (1.0 - b);
			//c.rgb					= saturate(c.rgb);
		#endif

		#ifdef FILTER
			c.rgb				= _Contrast * c.rgb + _Brightness;
			c.rgb				= lerp(dot(c.rgb, lum), c.rgb, _Saturation) * _Color.rgb;
			c.rgb				= saturate(c.rgb);
		#endif
		c.rgb					= lerp(_VignetteColor.rgb * c.rgb, c.rgb, smoothstep(_VignetteAmount, _VignetteSoftness, q2));

		#if !defined(UNITY_NO_LINEAR_COLORSPACE)
			c.rgb		*= c.rgb;
		#endif
		return c;
	}


	half4 fragexposure(v2f i) : SV_Target
	{
		UNITY_SETUP_INSTANCE_ID(i);
		UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

		half4 b				= SAMPLE_TEXTURE2D_X(_MainTex, sampler_MainTex, i.uv.xy);
		half br				= max(b.r, max(b.g, b.b));
		half soft			= clamp(br - _BloomData.y, 0.0h, _BloomData.z);

		half rq				= soft * soft * _BloomData.w;
		b					*= max(rq, br - _BloomData.x) / max(br, 0.00001h);

		#if !defined(UNITY_NO_LINEAR_COLORSPACE)
		b.rgb				*= b.rgb;
		#endif

		b					*= (_BloomColor);
		return b;
	}
	ENDHLSL


	Subshader
	{

		Pass //0
		{
			ZTest Always Cull Off ZWrite Off
			Fog { Mode off }
			HLSLPROGRAM
			#pragma vertex VertexProgram
			#pragma fragment FXAAQualityFragement
			ENDHLSL
		}

		Pass //1
		{
			ZTest Always Cull Off ZWrite Off
			Fog { Mode off }
			HLSLPROGRAM
			#pragma vertex vertBlur
			#pragma fragment fragBlur
			#pragma multi_compile __ BLOOM
			#pragma multi_compile __ BLUR
			ENDHLSL
		}

		Pass //2
		{
			ZTest Always Cull Off ZWrite Off
			Fog { Mode off }
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile __ BLOOM
			#pragma multi_compile __ DISTORTION
			#pragma multi_compile __ BLUR
			#pragma multi_compile __ CHROMA
			#pragma multi_compile __ LUT
			#pragma multi_compile __ FILTER
			//#pragma multi_compile __ SHARPEN
			ENDHLSL
		}

		Pass //3
		{
			ZTest Always Cull Off ZWrite Off
			Fog { Mode off }
			HLSLPROGRAM
			#pragma vertex vert
			#pragma fragment fragexposure
			ENDHLSL
		}
	}
	Fallback off
}