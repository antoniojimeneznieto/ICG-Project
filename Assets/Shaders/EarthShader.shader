Shader "Custom/EarthShader" {
    Properties {
        _DayTex ("Daytime Texture", 2D) = "white" {}
        _NightTex ("Nighttime Texture", 2D) = "white" {}
        _LightBrightness ("Light Brightness", Range(0, 3)) = 1.0
        _EmissionThreshold ("Emission Threshold", Range(0, 1)) = 0.5
    }
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"

            struct appdata {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
                float3 normal : NORMAL;
            };

            struct v2f {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldNormal : TEXCOORD1;
                float3 lightDir : TEXCOORD2;
                float3 worldViewDir : TEXCOORD3;
            };

            sampler2D _DayTex;
            sampler2D _NightTex;
            float _LightBrightness;
            float _EmissionThreshold;

            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.lightDir = normalize(_WorldSpaceLightPos0.xyz - worldPos);
                o.worldViewDir = UnityWorldSpaceViewDir(v.vertex);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target {
                fixed4 dayColor = tex2D(_DayTex, i.uv);
                fixed4 nightColor = tex2D(_NightTex, i.uv);
                float NdotL = max(0, dot(i.worldNormal, i.lightDir));
                float factor = smoothstep(0, 0.3, NdotL);
                fixed4 finalColor = lerp(nightColor, dayColor, factor);

                if (factor < 0.1) {
                    // Add emission (yellow light)
                    float emission = (nightColor.g > _EmissionThreshold) ? _LightBrightness * nightColor.g * (1 - factor) : 0.0;
                    float3 yellowLight = float3(1, 0.9, 0);  // Yellowish light
                    float3 whiteLight = float3(1, 1, 1);  // Whitish light
                    float3 emissionColor = lerp(yellowLight, whiteLight, emission);
                    finalColor.rgb += emission * emissionColor;
                }

                return finalColor;
            }
            ENDCG
        }
    }
}

