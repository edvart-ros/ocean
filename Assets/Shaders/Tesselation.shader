Shader "Unlit/Tesselation"
{
    Properties
    {
        _MaxTessDist ("Max tesselation distance", Float) = 100.0
        _MinTessDist ("Minimum tesselation distance", Float) = 1.0
        _MaxTess ("Max tesselation factor", Float) = 20.0
        _MinTess ("Minimum tesselation factor", Float) = 1.0
        _DistFactor ("Distance-based factor for tesselation", Float) = 1.0
        _TessOffset ("Tesselation distance offset", Float) = 5.0
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

            float _MinTessDist, _MaxTessDist, _MinTess, _MaxTess, _TessOffset, _DistFactor;

            // mesh data inputs to vertex shader
            struct appdata
            {
                float4 vertex : POSITION;
            };

            // the thing the vertex shader outputs to the hull shader
            struct TesselationControlPoint {
                float3 posWS : INTERNALTESSPOS; // only really need the vertex positions
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct TesselationFactors {
                float edge[3] : SV_TessFactor;
                float inside : SV_InsideTessFactor;
            };

            struct Interpolators {
                float4 pos : SV_POSITION;
                float3 normalWS : TEXCOORD3;
                float3 posWS : TEXCOORD4;
            };

            float sigmoid(float x){
                return 1/(1+exp(-x));
            }
            float getTesselationFactor(const float d){
                return (_MaxTess-_MinTess)*sigmoid(-_DistFactor*(d-_TessOffset)) + _MinTess;
            }

            // helper macro for domain shader
            #define BARYCENTRIC_INTERPOLATE(fieldName) \
                    patch[0].fieldName * barycentricCoordinates.x + \
                    patch[1].fieldName * barycentricCoordinates.y + \
                    patch[2].fieldName * barycentricCoordinates.z


            // runs on each vertex, outputs data to the hull shader
            TesselationControlPoint vert (appdata v)
            {
                TesselationControlPoint o;

                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);

                o.posWS = mul(unity_ObjectToWorld, float4(v.vertex));
                return o;
            }

            [domain("tri")] // Signal we're inputting triangles
            [outputcontrolpoints(3)] // Triangles have three points
            [outputtopology("triangle_cw")] // Signal we're outputting triangles
            [patchconstantfunc("PatchConstantFunction")] // Register the patch constant function
            [partitioning("integer")]
            TesselationControlPoint hull(
                InputPatch<TesselationControlPoint, 3> patch, // Input triangle
                uint id : SV_OutputControlPointID) { // Vertex index on the triangle

                return patch[id];
            }
            
            TesselationFactors PatchConstantFunction(InputPatch<TesselationControlPoint, 3> patch) {
                UNITY_SETUP_INSTANCE_ID(patch[0]);
                // calculate tesselation factors
                TesselationFactors f;
                float d = length(_WorldSpaceCameraPos-patch[0].posWS);
                int tessFactor = 1;
                if (d < _MinTessDist){
                    tessFactor = _MaxTess;
                }
                else if (d > _MaxTessDist){
                    tessFactor = _MinTess;
                }
                else {
                    tessFactor = getTesselationFactor(d);
                }
                f.edge[0] = tessFactor;
                f.edge[1] = tessFactor;
                f.edge[2] = tessFactor;
                f.inside = (f.edge[0] + f.edge[1] + f.edge[2]) * (1 / 3.0);
                return f;
            }




            // WATER SPECIFIC STUFF HERE 

            [domain("tri")]
            Interpolators domain(TesselationFactors factors, OutputPatch<TesselationControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) {
                Interpolators o;
                UNITY_SETUP_INSTANCE_ID(patch[0]); // boilerplate
                UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                float3 positionWS = BARYCENTRIC_INTERPOLATE(posWS);

                o.posWS = positionWS;
                o.pos = UnityWorldToClipPos(positionWS);
                // also *actually* compute normals!
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
