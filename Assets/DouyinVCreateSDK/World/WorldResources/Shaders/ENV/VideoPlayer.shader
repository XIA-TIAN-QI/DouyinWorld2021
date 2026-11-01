Shader "Douyin/World/ENV/VideoPlayer"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DisplayParams ("Display Params", Vector) = (1,1,0,0) // 添加可调整的显示scale属性，ZW默认设为偏移初始值0
        _OutOfBoundsColor ("Out of Bounds Color", Color) = (0,0,0,1) // 显示区域外的颜色，默认黑色
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            float4 _DisplayParams;
            fixed4 _OutOfBoundsColor;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex) * _DisplayParams.xy + _DisplayParams.zw; 
                UNITY_TRANSFER_FOG(o,o.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                if (i.uv.x < 0 || i.uv.x > 1 || i.uv.y < 0 || i.uv.y > 1)
                {
                    return _OutOfBoundsColor;
                }
                // sample the texture
                fixed4 col = tex2D(_MainTex, i.uv);
                // apply fog
                UNITY_APPLY_FOG(i.fogCoord, col);
                return col;
            }
            ENDCG
        }
    }
}    