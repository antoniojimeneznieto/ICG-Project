Shader "Custom/RayleighScattering" {
    Properties {
        _MainTex ("Main Texture (Day)", 2D) = "white" {}
        _NightTex ("Main Texture (Night)", 2D) = "black" {}
        _ScatteringCoeff ("Scattering Coefficient", Range(0, 1)) = 0.1
        _AtmosphereHeight ("Atmosphere Height", Range(0, 1)) = 0.1
        _RayleighScaleHeight ("Rayleigh Scale Height", Range(0, 1)) = 0.1
        _PlanetRadius ("Planet Radius", Range(0, 10000)) = 6371
        _PlanetCenter ("Planet Center", Vector) = (0, 0, 0)
        _EmissionIntensity ("Emission Intensity", Range(0, 5)) = 1
        _EmissionRange ("Emission Range", Range(0, 1)) = 0.2
    }

    SubShader {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100

        CGPROGRAM
        #pragma surface surf Lambert

        sampler2D _MainTex;
        sampler2D _NightTex;
        float _ScatteringCoeff;
        float _AtmosphereHeight;
        float _RayleighScaleHeight;
        float _PlanetRadius;
        float3 _PlanetCenter;
        float _EmissionIntensity;
        float _EmissionRange;

        struct Input {
            float2 uv_MainTex;
            float3 worldPos;
            float3 worldNormal;
        };

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
        ENDCG
    }
    FallBack "Diffuse"
}




