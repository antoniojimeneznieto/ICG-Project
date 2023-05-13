
Shader "Scattering/RayleighScattering"
{
	Properties
	{
        _PlanetTextureIsVisible ("Planet Texture is Visible", Range(0, 1)) = 1

		_MainTex ("Planet Texture (day)", 2D) = "white" {}

		_NightTex ("Planet Texture (Night)", 2D) = "black" {}
		_NightColor ("Night Color", Color) = (1,1,1,0.5)

		_bodyRadius ("Planet Radius", Float) = 6371000 

        _AtmosphColor ("Atmosphere Color", Color) = (1,1,1,1)
		_AtmosphRadius("Atmosphere Radius", Range(0.1,25)) = 6.371
		_AtmosphHeight ("Atmosphere Height", Float) = 60000 

        _ScatteringIsVisible ("Scattering is Visible", Range(0, 1)) = 1
		_ScatteringCoeff("Scattering Coefficient", Vector) = (0.0000060, 0.000014, 0.000031, 0)
		_ScatteringHeight("Scattering Height", Float) = 10000 

		_LightIntensity("Light intensity", Range(0,1)) = 0.15
		_InScattering("In Scattering:", Range(0,64)) = 16
		_OutScattering("Out Scattering", Range(0,64)) = 16
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 100
		
		CGPROGRAM

		#pragma surface surf Standard Shaders

		#pragma target 3.0

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
			float3 worldNormal;

			INTERNAL_DATA
		};
		
		sampler2D _NightTex;
		fixed4 _NightColor;
        float _PlanetTextureIsVisible;


		void surf (Input input, inout SurfaceOutputStandard output) {
			fixed4 c = tex2D (_MainTex, input.uv_MainTex);
			float3 normal = WorldNormalVector (input,  output.Normal);
			float3 light = _WorldSpaceLightPos0.xyz;
			float lightNormalDot = dot(normal,light) - 0.5;
			float emissionStrength = saturate(-lightNormalDot);

            output.Albedo = c.rgb * _PlanetTextureIsVisible;
			output.Metallic = 0 * _PlanetTextureIsVisible;
			output.Alpha = c.a * _PlanetTextureIsVisible;
			output.Emission = tex2D (_NightTex, input.uv_MainTex).rgb * _NightColor * emissionStrength * _PlanetTextureIsVisible;
		}
		ENDCG

		Tags { "RenderType"="Opaque" "Queue"="Transparent"}
		LOD 100

		Blend One One
		
		CGPROGRAM
		#pragma surface calculateSurfaceProperties RayleighScattering vertex:transformVertex
		#define PI 3.14

		sampler2D _MainTex;

		struct Input {
			float2 uv_MainTex;
			float3 worldPos;
			float3 centre;
		};

		float _bodyRadius; 
        
        float _AtmosphRadius; 
		fixed4 _AtmosphColor;
		float _AtmosphHeight; 

        float _ScatteringIsVisible;
		float3 _ScatteringCoeff;
		float _ScatteringHeight;

		float _LightIntensity;
        int _InScattering;
		int _OutScattering;

        float atmosphereRadius; 

		float UnitToMeterConversionFactor; 

		float3 worldCentre;
		float3 worldPos;

		float3 spaceCentre;
		float3 spacePosition;

        bool raySphereIntersection(float3 origin, float3 direction, 
                                   float3 center, float radius,   
                                   out float tMin, out float tMax) {
            float3 diffVector = center - origin;
            float dotProduct = dot(diffVector, direction);

            float radiusSquared = radius * radius;

            float distanceSquared = dot(diffVector, diffVector) - dotProduct * dotProduct;

            if (distanceSquared > radiusSquared) {
                return false;
            }

            float distance = sqrt(radiusSquared - distanceSquared);
            float sameDistance = distance;

            tMin = dotProduct - distance;
            tMax = dotProduct + sameDistance;
            return true;
        }

        void transformVertex(inout appdata_full vertexData, out Input outputData) {
            UNITY_INITIALIZE_OUTPUT(Input, outputData);
            vertexData.vertex.xyz += vertexData.normal * (_AtmosphHeight * ( _AtmosphRadius / _bodyRadius));
            outputData.centre = mul(unity_ObjectToWorld, half4(0,0,0,1));
        }

        bool sampleLight(float3 position, float3 direction,
                         out float rayOpticalDepth) {
            float ignoreDepth;
            float intersectionDepth;
            raySphereIntersection(position, direction, spaceCentre, atmosphereRadius, ignoreDepth, intersectionDepth);

            rayOpticalDepth = 0;

            float time = 0;
            float3 intersectionPoint = position + direction * intersectionDepth;
            float lightSampleSize = distance(position, intersectionPoint) / _InScattering;

            for (int i = 0; i < _InScattering; i++) {
                float3 samplePoint = position + direction * (time + lightSampleSize * 0.5);
                float height = distance(spaceCentre, samplePoint) - _bodyRadius;

                if (height < 0)
                    return false;

                rayOpticalDepth += exp(-height / _ScatteringHeight) * lightSampleSize;

                time += lightSampleSize;
            }

            return true;
        }

		#include "UnityPBSLighting.cginc"
        inline fixed4 LightingRayleighScattering(SurfaceOutputStandard surface, fixed3 viewDirection, UnityGI globalIllumination)
        {
            float3 lightDirection = globalIllumination.light.dir;
            float3 viewDir = viewDirection;
            float3 normal = surface.Normal;

            float3 sunLightDirection = lightDirection;
            float3 viewRayDirection = -viewDir;

            float atmosphereEntryPoint;
            float atmosphereExitPoint;

            if (!raySphereIntersection(spacePosition, viewRayDirection, spaceCentre, atmosphereRadius, atmosphereEntryPoint, atmosphereExitPoint))
                return fixed4(0, 0, 0, 0);

            float planetEntryPoint, planetExitPoint;
            if (raySphereIntersection(spacePosition, viewRayDirection, spaceCentre, _bodyRadius, planetEntryPoint, planetExitPoint))
            {
                atmosphereExitPoint = planetEntryPoint;
            }

            float totalOpticalDepth = 0;
            float3 totalScattering = float3(0, 0, 0);

            float time = atmosphereEntryPoint;
            float viewSampleSize = (atmosphereExitPoint - atmosphereEntryPoint) / (float)(_OutScattering);
            for (int i = 0; i < _OutScattering; i++)
            {
                float3 samplePoint = spacePosition + viewRayDirection * (time + viewSampleSize * 0.5);
                float height = distance(spaceCentre, samplePoint) - _bodyRadius;

                float viewRayOpticalDepth = exp(-height / _ScatteringHeight) * viewSampleSize;
                totalOpticalDepth += viewRayOpticalDepth;

                float lightRayOpticalDepth = 0;
                bool isAboveGround = sampleLight(samplePoint, sunLightDirection, lightRayOpticalDepth);
                if (isAboveGround)
                {
                    float3 attenuation = exp(-_ScatteringCoeff * (totalOpticalDepth + lightRayOpticalDepth));
                    totalScattering += viewRayOpticalDepth * attenuation;
                }
                time += viewSampleSize;
            }

            float cosTheta = dot(viewDir, lightDirection);
            float cos2Theta = cosTheta * cosTheta;
            float rayPhase = 3.0 / (16.0 * PI) * (1.0 + cos2Theta);

            float3 scattering = (_LightIntensity * 100) * (rayPhase * _ScatteringCoeff) * totalScattering;

            fixed4 atmosphereColor = _AtmosphColor;
            atmosphereColor.rgb *= scattering * atmosphereColor.a;

            atmosphereColor.rgb = min(atmosphereColor.rgb, 1);
            return atmosphereColor;
        }

		void LightingRayleighScattering_GI(SurfaceOutputStandard surface, UnityGIInput data, inout UnityGI gi) {
		    //TODO: Implement
		}

        void calculateSurfaceProperties (Input input, inout SurfaceOutputStandard output) {
            fixed4 textureColor = tex2D (_MainTex, input.uv_MainTex);
            output.Albedo = textureColor.rgb;
            
            output.Alpha = textureColor.a;

            worldCentre = input.centre;
            worldPos = input.worldPos;
            
            UnitToMeterConversionFactor = _bodyRadius / _AtmosphRadius;

            spaceCentre = float3(0,0,0);
            spacePosition = (worldPos - worldCentre) * UnitToMeterConversionFactor;

            atmosphereRadius = _bodyRadius + _AtmosphHeight;
            _ScatteringHeight *= _ScatteringIsVisible;

            _ScatteringCoeff *= 2;
            _ScatteringCoeff *= _ScatteringIsVisible;
        }
		ENDCG
	}
	FallBack "Diffuse"
}