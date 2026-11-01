Shader "Douyin_PostProcessing/PostProcessing/Dilate"
{
    SubShader
    {
        Cull Front ZWrite Off ZTest Always

        Pass
        {   
            Stencil 
            {
                Ref [_Ref]
                Comp [_Comparison]
				Pass IncrWrap
            }
            

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
			#pragma fragmentoption ARB_precision_hint_fastest

            #include "UnityCG.cginc"
            #include "MiskCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                half3 normal : NORMAL;
				DefineTransform
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 uv : TEXCOORD0;

                float4		vertex : SV_POSITION;
				float2x2	rotation : TEXCOORD1;

                UNITY_VERTEX_OUTPUT_STEREO
            };
            
            half _EffectSize;

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_MainTex);
            half4 _MainTex_ST;
            half4 _MainTex_TexelSize;
            half2 _Shift;
            

            UNITY_DECLARE_SCREENSPACE_TEXTURE(_InfoBuffer);
            half4 _InfoBuffer_ST;
            half4 _InfoBuffer_TexelSize;

			DefineCoords

            v2f vert (appdata v)
            {
                v2f o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				
                o.vertex = UnityObjectToClipPos(v.vertex);


                ComputeScreenShift
					
                o.uv = ComputeScreenPos(o.vertex);
				o.uv.xy *= _Scale;
				CheckY

#if UNITY_UV_STARTS_AT_TOP
				ModifyUV
#endif
                
                return o;
            }
            
            inline half4 average(half4 first, half4 second)
            {
                return max(first, second);
            }

            half4 frag (v2f i) : SV_Target
			{
                UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);

				half2 uv = i.uv.xy / i.uv.w;
                half2 baseShift = _Shift;
				half2 texelShift = baseShift;
                texelShift          *= _MainTex_TexelSize;
				half4 shiftedMax    = average(FetchTexelAtWithShift(uv, +texelShift), FetchTexelAtWithShift(uv, -texelShift));
				return average(FetchTexelAt(uv), shiftedMax);
            }
            ENDCG
        }
    }
}
