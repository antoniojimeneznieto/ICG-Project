Shader "Custom/EarthShader" {
    Properties {
        _DayTex ("Daytime Texture", 2D) = "white" {}
        _NightTex ("Nighttime Texture", 2D) = "white" {}
        // Parameter for the brightness of the emitted light
        _LightBrightness ("Light Brightness", Range(0, 3)) = 1.0
        // Threshold below which no light emission will occur
        _EmissionThreshold ("Emission Threshold", Range(0, 1)) = 0.5
    }
    SubShader {
        Pass {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            // Include Unity's common shader library
            #include "UnityCG.cginc"

            // The input data structure for the vertex shader
            struct appdata {
                float4 vertex : POSITION;  // Vertex position
                float2 uv : TEXCOORD0;  // Texture coordinates
                float3 normal : NORMAL;  // Normal vector
            };

            // The output data structure from the vertex shader
            struct v2f {
                float4 vertex : SV_POSITION;  // Transformed vertex position
                float2 uv : TEXCOORD0;  // Pass through texture coordinates
                float3 worldNormal : TEXCOORD1;  // Normal vector in world space
                float3 lightDir : TEXCOORD2;  // Direction towards the light source
                float3 worldViewDir : TEXCOORD3;  // Direction towards the viewer
            };

            // Declare the textures and parameters to be used in the shader
            sampler2D _DayTex;
            sampler2D _NightTex;
            float _LightBrightness;
            float _EmissionThreshold;

            // The vertex shader
            v2f vert (appdata v) {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);  // Transform vertex to clip space
                o.uv = v.uv;  // Pass through texture coordinates
                o.worldNormal = UnityObjectToWorldNormal(v.normal);  // Transform normal vector to world space
                float3 worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;  // Calculate world space position
                o.lightDir = normalize(_WorldSpaceLightPos0.xyz - worldPos);  // Calculate direction towards light source
                o.worldViewDir = UnityWorldSpaceViewDir(v.vertex);  // Calculate direction towards viewer
                return o;
            }

            // The fragment (pixel) shader
            fixed4 frag (v2f i) : SV_Target {
                fixed4 dayColor = tex2D(_DayTex, i.uv);  // Sample daytime texture
                fixed4 nightColor = tex2D(_NightTex, i.uv);  // Sample nighttime texture
                float NdotL = max(0, dot(i.worldNormal, i.lightDir));  // Calculate diffuse lighting factor
                float factor = smoothstep(0, 0.3, NdotL);  // Softly transition between day and night
                fixed4 finalColor = lerp(nightColor, dayColor, factor);  // Linearly interpolate between night and day color

                if (factor < 0.1) {
                    // If we are on the dark side of the object
                    // Calculate emission based on nighttime texture's green channel and light brightness
                    float emission = (nightColor.g > _EmissionThreshold) ? _LightBrightness * nightColor.g * (1 - factor) : 0.0;
                    float3 yellowLight = float3(1, 0.9, 0); 
                    float3 whiteLight = float3(1, 1, 1);  
                    float3 emissionColor = lerp(yellowLight, whiteLight, emission);  // Linearly interpolate between yellow and white light based on emission
                    finalColor.rgb += emission * emissionColor;  // Add the emission color to the final color
                }

                return finalColor;  
            }
            ENDCG
        }
    }
}

