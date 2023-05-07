Shader "Custom/Scattering"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
		// _CloudsTex ("Clouds", 2D) = "black" {}
		// _CloudsAlpha ("Clouds Alpha", Range(0,1)) = 0.25
		// _CloudsSpeed ("Clouds Speed", Range(-10,10)) = 1
		[Toggle] _CloudsAdditive ("Additive clouds?", Int) = 1
		_NightTex ("Night Map", 2D) = "black" {}
		[HDR] _NightColor ("Night Color (RGBA)", Color) = (1,1,1,0.5)
		_NightWrap ("Night Wrap", Range(0,1)) = 0.5
		_AtmosphereModifier ("Atmosphere Modifier", Float) = 1
		_ScatteringModifier ("Scattering Modifier", Float) = 1
		_AtmosphereColor ("Atmosphere Color", Color) = (1,1,1,1)
		_SphereRadius("Sphere Radius (units)", Range(0.1,25)) = 6.371
		_PlanetRadius ("Planet Radius (metres)", Float) = 6371000 
		_AtmosphereHeight ("Atmosphere Height (metres)", Float) = 60000 
        _RayScatteringCoefficient("βᵣ, Rayleight Scattering Coefficient (RGB, metres^-1)", Vector) = (0.000005804542996261093, 0.000013562911419845635, 0.00003026590629238531, 0)
		_RayScaleHeight("H₀, Rayleigh Scale Height (metres)", Float) = 8000 


    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
