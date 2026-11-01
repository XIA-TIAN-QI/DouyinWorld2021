Shader "Douyin_PostProcessing/PostProcessing/Outline"
{
    SubShader
    {
        Cull [_Cull]
        ZWrite Off
        ZTest [_ZTest]

        Pass
        {
			ColorMask [_ColorMask]

            Stencil
            {
                Ref [_OutlineRef]
                Comp Always
                Pass Replace
            }
            

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing
     
			#pragma fragmentoption ARB_precision_hint_fastest
			//#pragma multi_compile __ BACK_OBSTACLE_RENDERING BACK_MASKING_RENDERING

            #include "UnityCG.cginc"
            #include "MiskCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
//#if USE_CUTOUT
//                float2 uv : TEXCOORD0;
//#endif
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
//#if USE_CUTOUT
 //               float2 uv : TEXCOORD0;
//#endif


				float4 screenUV : TEXCOORD1;
                UNITY_VERTEX_OUTPUT_STEREO
            };


			/*UNITY_DECLARE_SCREENSPACE_TEXTURE(_InfoBuffer);
			half4 _InfoBuffer_ST;
			half4 _InfoBuffer_TexelSize;*/

			DEFINE_CUTOUT
			DefineCoords

            v2f vert (appdata v)
            {
                v2f o;
                
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.vertex = UnityObjectToClipPos(v.vertex);

				o.screenUV = ComputeScreenPos(o.vertex);
                FixDepth
	
                return o;
            }

            half4 _EPOColor;

			half4 frag(v2f i) : SV_Target
			{
                return half4(1, 0, 0, 0);
            }
            ENDCG
        }
    }
}
