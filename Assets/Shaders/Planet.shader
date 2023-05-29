Shader "CelestialBody/Planet"
{
	Properties
	{
		/*
			Surface Properties
		*/

		_DayTex ("Daytime Texture", 2D) = "white" {}
        _NightTex ("Nighttime Texture", 2D) = "white" {}
        // Parameter for the brightness of the emitted light
        _LightBrightness ("Light Brightness", Range(0, 3)) = 1.0
        // Threshold below which no light emission will occur
        _EmissionThreshold ("Emission Threshold", Range(0, 1)) = 0.5

		/*
			Atmosphere Properties
			Default values take earth's values
		*/

		// space_ -> variable is in meters
		_space_planetRadius ("Planet radius in meters", Float) = 6371000
		_space_atmosphereHeight ("Atmosphere radius in meters", Float) = 60000
		_space_rayleighScatteringCoefficient("Rayleigh scattering coefficient", Vector) = (0.0000058, 0.0000135, 0.0000331, 0)
		_space_rayleighScaleHeight("Rayleigh scale height in meters", Float) = 8000	

		// world_ -> variable is in unity units 
		_world_planetRadius("Planet radius in units", Float) = 6.371		

		// Modifiers to play with
		_AtmosphereModifier ("Atmosphere modifier", Range(1, 25)) = 1
		_ScatteringModifier ("Scattering modifier", Range(0, 25)) = 1
		_LightColor ("Light color", Color) = (1,1,1,1)
		_SunIntensity("Sun intensity", Range(0,100)) = 25
		_ViewSamples("View ray samples", Range(0,100)) = 10
		_LightSamples("Light ray samples", Range(0,100)) = 10

	}

	SubShader {

		Tags { "RenderType"="Opaque" }
		LOD 100

		/*
			1st Pass : Render the surface of the planet
		*/
		
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

		/*
			2nd Pass : Render the atmosphere of the planet from space
		*/

		Tags { "RenderType"="Transparent" "Queue"="Transparent"}
		LOD 100
		Cull Back
		Blend One One // Use additive blending
	
		CGPROGRAM
		#pragma surface surf Scattering vertex:vert
		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
			float3 worldPos;
			float3 world_planetCenter;
		};
		fixed4 _Color;

		#define PI 3.1415926535897932384626433832795
		float unitsToMeters;

		// space_ -> in metres
		float3 _space_rayleighScatteringCoefficient;
		float _space_rayleighScaleHeight;
		float3 space_planetCenter;
		float _space_planetRadius;
		float _space_atmosphereHeight;
		float space_atmosphereRadius;
		float3 space_position;		

		// world_ -> in unity units
		float3 world_planetCenter;
		float3 worldPos;
		float _world_planetRadius;

		// Modifiers to play around with
		float _AtmosphereModifier;
		float _ScatteringModifier;
		fixed4 _LightColor;
		float _SunIntensity;
		int _ViewSamples;
		int _LightSamples;

		/*
		 * Ray-sphere intersection
		 * @param origin:    ray origin
		 * @param direction: ray direction
		 * @param center:    sphere center
		 * @param radius:    sphere radius
		 * @out   t:         intersection time (t.x < t.y)
		 * @return true if the ray intersects the sphere, otherwise false
		*/
		bool raySphereIntersection(float3 origin, float3 direction, float3 center, float radius, out float2 t) {
            float3 L = center - origin;
            float tca = dot(L, direction);
            float d2 = dot(L, L) - tca * tca;
            if (d2 > radius * radius) {
                t = float2(0.0, 0.0);
                return false;
            }
            float thc = sqrt(radius * radius - d2);
            t = float2(tca - thc, tca + thc);
            return true;
        }

		/*
		 * Local Rayleigh air density at a given height
		 * @param height: height in meters
		 * @return The local density
		*/
		float localDensity(float height) {
            return exp(-height / _space_rayleighScaleHeight);
        }
		
		/*
		 * Rayleigh phase function
		 * @param cosTheta: angle between the incident light and the view direction
		 * @return The phase function
		*/
		float rayleighPhaseFunction(float cosTheta) {
            return 3.0 / (16.0 * PI) * (1.0 + cosTheta * cosTheta);
        }

		/*
		 * Compute the in-scattering for a given point P inside the atmosphere
		 * @param P:            point in the atmosphere
		 * @param sunDirection: direction of the sun ray
		 * @out   opticalDepth: optical depth of the light ray traveling from planet's atmosphere edge to P
		 * @return true if the light ray does not intersect the planet
		*/
		bool computeInScattering(float3 P, float3 sunDirection, out float opticalDepth) {

			float2 t;
			raySphereIntersection(P, sunDirection, space_planetCenter, space_atmosphereRadius, t);

			opticalDepth = 0;

			float stepSize = distance(P, t.y) / (float) (_LightSamples);
			float3 X = P + sunDirection * stepSize * 0.5; // We sample in the middle of the segment
			for (int i = 0; i < _LightSamples; i ++) {

				float height = distance(space_planetCenter, X) - _space_planetRadius;
				if (height < 0) { return false; } // check if X is inside the planet

				opticalDepth += localDensity(height) * stepSize;

				X += sunDirection * i * stepSize;
				}
			return true;
		}

		/*
		 * Custom lighting function to compute the scattering effect if the atmosphere.
		 * This is where the bulk of the scattering code is.
		 * @param s:       surface properties
		 * @param viewDir: view direction
		 * @param gi:      global illumination information
		*/
		#include "UnityPBSLighting.cginc"
		inline fixed4 LightingScattering(SurfaceOutputStandard s, fixed3 viewDir, UnityGI gi) {

			float3 viewRayOrigin = space_position;
			float3 viewRayDirection = -viewDir;
			float3 sunDirection = normalize((float3(0, 0, 0) - mul(unity_ObjectToWorld, float4(0, 0, 0, 1))).xyz);

			float2 tA; // Atmosphere intersection time
			float2 tP; // Planet intersection time

			float2 t; // Intersection time

			// Ignore if the view ray does not intersect the atmosphere
			if (!raySphereIntersection(viewRayOrigin, viewRayDirection, space_planetCenter, space_atmosphereRadius, tA)) {
				return fixed4(0,0,0,0);
			}

			t = tA;
			
			// Adapt intersection time if we hit the planet
			if (raySphereIntersection(viewRayOrigin, viewRayDirection, space_planetCenter, _space_planetRadius, tP)) {
				t.y = tP.x;
			}

			float3 rayleighScattering = float3(0,0,0);
			float opticalDepth = 0;
			float stepSize = (t.y-t.x) / (float) (_ViewSamples);

			float3 Pa = viewRayOrigin + viewRayDirection * t.x;
			float3 P = Pa + viewRayDirection * stepSize * 0.5; // we sample in the middle of the segment

			for (int i = 0; i < _ViewSamples; i ++) {

				float height = distance(P, space_planetCenter) - _space_planetRadius;

				float lightRayOpticalDepth = 0;
				float viewRayOpticalDepth = 0;
			
				viewRayOpticalDepth = localDensity(height) * stepSize;
				opticalDepth += viewRayOpticalDepth;

				if (computeInScattering(P, sunDirection, lightRayOpticalDepth)) {
					float3 attenuation = exp(-(opticalDepth + lightRayOpticalDepth) * _space_rayleighScatteringCoefficient);

					rayleighScattering += viewRayOpticalDepth * attenuation;
				}
				P += viewRayDirection * stepSize;
			}

			float rayleighPhase = rayleighPhaseFunction(dot(-viewRayDirection, sunDirection));

			float3 scattering = rayleighPhase * _space_rayleighScatteringCoefficient * rayleighScattering;
			scattering *= _SunIntensity;

			fixed4 color = _LightColor;
			color.rgb *= scattering;

			color.rgb = min(color.rgb, 1);
			return color;

		}

		void LightingScattering_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi) {
			LightingStandard_GI(s, data, gi);		
		}

		// Normal extrusion for the atmosphere
		void vert (inout appdata_full v, out Input o) {

			UNITY_INITIALIZE_OUTPUT(Input, o);

			// Planet center in unity units
			o.world_planetCenter = mul(unity_ObjectToWorld, half4(0,0,0,1));

			// Normal extrusion
			float factor = _space_atmosphereHeight * _AtmosphereModifier;
			factor *= _world_planetRadius / _space_planetRadius; // convert to unity units
			v.vertex.xyz += v.normal * factor;
		}

		// Surface shader for the amtmosphere
		void surf (Input IN, inout SurfaceOutputStandard o) {
			fixed4 c = tex2D (_MainTex, IN.uv_MainTex);
			o.Albedo = c.rgb;
			o.Alpha = c.a;

			unitsToMeters = _space_planetRadius / _world_planetRadius;

			// Unity units
			worldPos = IN.worldPos;
			world_planetCenter = IN.world_planetCenter;

			// Metres
			space_planetCenter = float3(0,0,0);
			space_position = (worldPos - world_planetCenter) * unitsToMeters;
			space_atmosphereRadius = _space_planetRadius + (_space_atmosphereHeight * _AtmosphereModifier);

			_space_rayleighScatteringCoefficient *= _ScatteringModifier;
		}
		ENDCG
	}
	FallBack "Diffuse"
}