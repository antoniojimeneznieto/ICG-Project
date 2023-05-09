Shader "Custom/RayleighScattering" {
    Properties {
        _MainTex ("Main Texture (Day)", 2D) = "white" {}

        _NightTex ("Main Texture (Night)", 2D) = "black" {}
        [HDR] _NightColor ("Night Color", Color) = (1,1,1,0.5)

		_AtmosphereFactor ("Atmosphere Factor", Float) = 1
        _AtmosphereHeight ("Atmosphere Height (km)", Range(0, 10)) = 8
        _AtmosphereColor ("Atmosphere Color", Color) = (1,1,1,1)

        _PlanetRadius ("Planet Radius (km)", Range(0, 10000)) = 6371
        _PlanetCenter ("Planet Center", Vector) = (0, 0, 0)
        _EmissionIntensity ("Emission Intensity", Range(0, 5)) = 1
        _EmissionRange ("Emission Range", Range(0, 1)) = 0.2

        _ScatteringCoeff ("Scattering Coefficient", Range(0, 1)) = 0.1
        _RayleighScaleHeight ("Rayleigh Scale Height", Range(0, 1)) = 0.1

    }

    SubShader {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100

        CGPROGRAM
        #pragma surface surf Lambert

        sampler2D _MainTex;

        struct Input {
            float2 uv_MainTex;
            float3 worldPos;
            float3 worldNormal;
        };

        sampler2D _NightTex;
        fixed4 _NightColor;

        float _AtmosphereFactor;
        float _AtmosphereHeight;
        float _AtmosphereColor;

        float _PlanetRadius;
        float3 _PlanetCenter;
        float _EmissionIntensity;
        float _EmissionRange;


        float _ScatteringCoeff;
        float _RayleighScaleHeight;


        void surf (Input IN, inout SurfaceOutput o) {
            float3 worldPos = IN.worldPos;
            float3 worldNormal = normalize(IN.worldNormal);

            // Compute the view direction
            float3 viewDirection = normalize(_WorldSpaceCameraPos - worldPos);

            // Calculate Rayleigh scattering
            float cosTheta = dot(viewDirection, worldNormal);
            float rayleighFactor = 1.0 + pow(cosTheta, 2.0);
            float rayleighPhase = (3.0 / (16.0 * 3.14159)) * rayleighFactor;

            // Calculate the height from the center of the planet
            float heightFromCenter = length(worldPos - _PlanetCenter);

            // Calculate the atmospheric height
            float height = exp(-(heightFromCenter - _PlanetRadius) / _AtmosphereHeight);

            // Calculate the scattering term
            float scatteringTerm = _ScatteringCoeff * exp(-(heightFromCenter - _PlanetRadius) / _RayleighScaleHeight);

            // Day and night texture blending
            float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);
            float dayNightBlend = saturate(dot(worldNormal, lightDirection) * 0.5 + 0.5);
            float3 dayColor = tex2D(_MainTex, IN.uv_MainTex).rgb;
            float3 nightColor = tex2D(_NightTex, IN.uv_MainTex).rgb;
            float3 finalColor = lerp(dayColor, nightColor, dayNightBlend);

            // Compute the final color
            o.Albedo = finalColor * (1.0 - rayleighPhase * scatteringTerm * height);
            o.Alpha = 1;

            // Emission for yellowish pixels on the night texture
            float3 emissionColor = nightColor * _EmissionIntensity;
            float emissionMask = smoothstep(0.5 - _EmissionRange, 0.5 + _EmissionRange, dot(emissionColor, float3(1, 1, 0)));
            o.Emission = emissionColor * emissionMask * (1.0 - dayNightBlend);
        }


        bool rayIntersect(float3 origin, float3 direction, 
                          float3 center, float radius, 
                          out float firstIntersectionTime,
                          out float secondIntersectionTime) {
            float3 diff = center - origin;
            float dotProduct = dot(diff, direction);

            float radiusSquared = radius * radius;
            float orthogonalDistanceSquared = dot(diff, diff) - dotProduct * dotProduct;

            if (orthogonalDistanceSquared > radiusSquared)
            {
                return false;
            }

            float intersectionDistance = sqrt(radiusSquared - orthogonalDistanceSquared);
            firstIntersectionTime = dotProduct - intersectionDistance;
            secondIntersectionTime = dotProduct + intersectionDistance;
            return true;
        }


        ENDCG

        // Tags { "RenderType"="Transparent" "Queue"="Transparent"}
		// LOD 100
		
		// CGPROGRAM
		// #pragma surface surf Scattering

		// #pragma target 3.0

        // struct Input {
        //     float2 uv_MainTex;
        //     float3 worldPos;
        //     float3 worldNormal;
        // };

        // // Compute intersection between ray of origin O and direction D with 
        // // sphere of center C, radius R
        // // Output the two solution of the equation in A and B
        // // (First weeks of classes)

        


        // ENDCG
    }
    FallBack "Diffuse"
}




