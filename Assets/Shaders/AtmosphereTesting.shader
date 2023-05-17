// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'


Shader "Scattering/RayleighScattering"
{
    Properties
    {
        _MainTexture("Texture", 2D) = "white" {}
        _AtmosphereSize("AtmosphereSize", Range(1.0,1.5))=1.1
    }
    SubShader
    {
        // This is the pass that renders the planet.
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            sampler2D _MainTexture;
            float4 _MainTexture_ST;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float4 clipPos : SV_POSITION;
                float2 uv : TEXCOORD0;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.clipPos=UnityObjectToClipPos(v.vertex);
                o.uv=(v.uv*_MainTexture_ST.xy)+_MainTexture_ST.zw;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                col=tex2D(_MainTexture, i.uv);
                return col;
            }
            ENDCG
        }

        // This is the pass that renders the atmosphere.
        Pass
        {
            ZTest Always 
            Cull Off 
            ZWrite Off
			Blend One Zero
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            fixed4 _OutlineColor;
            float _AtmosphereSize;

            float3 planetCenter;
            float planetRadius;
            float planetAtmosphereRadius;

            float3 lightPosition;

            struct appdata
            {
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float4 pos : SV_POSITION;
                float3 viewVector : TEXCOORD1;
            };

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

            // Negative intersection points (i.e. behind the ray origin) are clamped to ray ray origin.
            bool findIntersectionPoints(float3 rayOrigin, float3 rayDirection, 
                                        out float3 intersectionPoint1, out float3 intersectionPoint2) {
                
                float tMin;
                float tMax;

                if(!raySphereIntersection(rayOrigin, rayDirection, planetCenter, planetAtmosphereRadius, tMin, tMax)) {
                    return false;
                }

                if(!raySphereIntersection(rayOrigin, rayDirection, planetCenter, planetRadius, tMin, tMax)) {
                    return raySphereIntersection(rayOrigin, rayDirection, planetCenter, planetAtmosphereRadius, tMin, tMax);
                }
                raySphereIntersection(rayOrigin, rayDirection, planetCenter, planetAtmosphereRadius, tMin, tMax);
                if(tMin < 0) { tMin = 0; }
                intersectionPoint1 = rayOrigin + rayDirection * tMin;

                raySphereIntersection(rayOrigin, rayDirection, planetCenter, planetRadius, tMin, tMax);
                if(tMin < 0) { tMin = 0; }
                intersectionPoint2 = rayOrigin + rayDirection * tMin;
                
                return true;
            }

            // Eq. 5
            // F(theta, g) = (3 / 4) * (1 + cos(theta)^2) / (2 + g^2) * (1 + g^2 - 2 * g * cos(theta))^(3/2)
            // For Rayleigh scattering, we use g = 0;
            // Theta is the angle between the view ray and the light ray coming from the sun.
            // @param theta(float): The angle between the incident ray and the reflected ray.
            // @param g(float): The asymmetry factor.
            float phaseFunction(float theta, float g) {

                float a = 3 * (1 - g * g);
                float b = 2 * (2 + g * g);
                float c = 1 + cos(theta) * cos(theta);
                float d = 1 + g * g - 2 * g * cos(theta);

                return (a / b) * (c / sqrt(d * d * d));
            }

            // Eq. 2
            // Slightly adapted to be between 0 and 1
            // rho = exp(-height) * (1 - height)
            // @param p(float3): The point in the atmosphere where we want to compute the local density.
            // @return(float): The local density at point p.

            float computeDensityAtPoint(float3 p) {
                float height = (length(p - planetCenter) - planetRadius) / planetAtmosphereRadius;
                return exp(-height) * (1.0 - height);
            }

            // Eq. 4
            // Compute the inner integral (optical depth) of the scattering equation.
            // This is the attenuation caused by light traveling between the point P1 and P2. (dist(P1, P2) = S)
            // t(S, lambda) = Beta * integral from 0 to S of rho(s) * ds
            // @param P1(float): The first point in the atmosphere.
            // @param P2(float): The second point in the atmosphere.
            // @param numberOfSamples(int): The number of samples to take along the ray to integrate.
            // @return(float): The attenuation caused by particles between the point P1 and P2.

            float opticalDepth(float3 P1, float3 P2, int numberOfSamples) {

                float attenuation = 0;
                float S = length(P2 - P1);
                float step = S / float(numberOfSamples - 1);

                float3 rayDirection = normalize(P2 - P1);

                float3 pt = P1;

                for(int i = 0; i < numberOfSamples; i ++) {
                    float rho = computeDensityAtPoint(pt);
                    attenuation += rho * step;
                    pt += rayDirection * step;
                }

                return attenuation;
            }

            // Eq. 1
            // Compute the proportion of light reflected from the incident light ray towards the reflected ray at point P.
            // @param incidentRay(float3): The incident light ray.
            // @param reflectedRay(float3): The reflected light ray.
            // @param P(float3): The point in the atmosphere where we want to compute the proportion of reflected light.
            // @return(float): The proportion of reflected light
            float computeRayleighScattering(float3 incidentRay, float3 reflectedRay, float3 P) {

                //Only rho * Fr(theta)
                float theta = acos(dot(incidentRay, reflectedRay));
                
                return computeDensityAtPoint(P) * phaseFunction(theta, 0);
            }

            // Eq. 8
            // Compute the Rayleigh scattering effect for a given view ray.
            // @param viewRayOrigin(float3): The origin of the view ray.
            // @param viewRayDirection(float3): The direction of the view ray.
            // @param numberOfSamples(int): The number of samples to take along the ray to integrate.
            // @return(float): The Rayleigh scattering effect for the given view ray.
            float calculateAtmosphericEffect(float3 viewRayOrigin, float3 viewRayDirection, int numberOfSamples) {

                float3 Pa;
                float3 Pb;
                float3 Pc;
                float3 P;

                float3 temp;

                float intensity = 0;           

                if(!findIntersectionPoints(viewRayOrigin, viewRayDirection, Pa, Pb)) {
                    return 0;
                }

                float viewAtmoRayLength = length(Pb - Pa);
                float step = viewAtmoRayLength / float(numberOfSamples - 1);  

                P = Pa;

                for(int i = 0; i < numberOfSamples; i++) {

                    float3 lightRayOrigin = lightPosition;
                    float3 lightRayDirection = normalize(P - lightPosition);

                    findIntersectionPoints(lightRayOrigin, lightRayDirection, Pc, temp);

                    intensity += computeRayleighScattering(lightRayDirection, normalize(P - Pc), P) * exp(-opticalDepth(Pc, P, numberOfSamples) - opticalDepth(P, Pa, numberOfSamples));
                    intensity *= step;

                    P += viewRayDirection * step;
                }

                return intensity;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.pos=UnityObjectToClipPos(v.vertex*_AtmosphereSize);

				o.viewVector = normalize(UnityWorldSpaceViewDir(v.vertex));

                planetCenter = mul(unity_ObjectToWorld, float4(0.0,0.0,0.0,1.0)).xyz;
                planetRadius = distance(planetCenter, mul(unity_ObjectToWorld, v.vertex)); 
                planetAtmosphereRadius = planetRadius + _AtmosphereSize;
                lightPosition = _WorldSpaceLightPos0.xyz;
 
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col;           
                float3 viewRayOrigin = _WorldSpaceCameraPos;
                float intensity = calculateAtmosphericEffect(viewRayOrigin, i.viewVector, 100);
                return float4(1.0, 1.0, 1.0, 1.0) * intensity;
            }
            ENDCG
        }
    }
}