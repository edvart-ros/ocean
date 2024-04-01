Shader "Custom/Tessellate"
{
    Properties
    {
        _MaxTessDist ("Max tessellation distance", Float) = 100.0
        _MinTessDist ("Minimum tessellation distance", Float) = 1.0
        _MaxTess ("Max tessellation factor", Float) = 20.0
        _MinTess ("Minimum tessellation factor", Float) = 1.0
        _DistFactor ("Distance-based factor for tessellation", Float) = 1.0
        _TessOffset ("Tessellation distance offset", Float) = 5.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100
        
        Pass
        {
            CGPROGRAM
            #pragma target 5.0
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma fragment frag
            #pragma multi_compile_fog
            
            #include "UnityCG.cginc"
            struct TessellationFactors {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };
            
            struct Interpolators {
                float4 pos : SV_POSITION;
                float3 normalWS : TEXCOORD3;
                float3 posWS : TEXCOORD4;
            };

            struct TessellationControlPoint {
                float3 posWS : INTERNALTESSPOS; // only really need the vertex positions
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            #include <TesselateInc.hlsl> // all the interpolation code is in here
            


            [domain("tri")]
            Interpolators domain(TessellationFactors factors, OutputPatch<TessellationControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) {
                Interpolators o;
                 // boilerplate
                UNITY_SETUP_INSTANCE_ID(patch[0]);
                UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                // YOUR "VERTEX SHADER" TYPE CODE HERE
                float3 positionWS = BARYCENTRIC_INTERPOLATE(posWS);
                o.posWS = positionWS;
                o.pos = UnityWorldToClipPos(positionWS);
                o.normalWS = float3(0, 1, 0);
                return o;
            }

            fixed4 frag(Interpolators i) : SV_Target {
                return 1;
            }
            ENDCG
        }
    }
}
