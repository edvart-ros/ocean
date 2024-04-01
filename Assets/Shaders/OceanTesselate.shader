Shader "Custom/OceanTesselate"
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
            
            float clampDot(const float3 u, const float3 v){
                return clamp(dot(u, v), 0.0, 1.0);
            }

            float3 wave(const float a,const  float2 D, const float k, const float c, const float2 p, const float t){
                const float h = a*exp(sin(k*dot(D, p) - c*t)-1);
                const float tmp = h*k*cos(c*t-k*dot(D, p));
                const float dh_dx = D[0]*tmp;
                const float dh_dz = D[1]*tmp;
                return float3(h, dh_dx, dh_dz);
            }

            float4 _DiffuseColor;
            float4 _AmbientColor;
            float _AmbientGain;
            float4 _SpecularColor;
            float _SpecularExponent;
            float _SpecularGain;
            float3 _L;
            float _A[128];
            float _D[128];
            float _K[129];
            float _C[128];
            int _NumWaves;
            
            [domain("tri")]
            Interpolators domain(TessellationFactors factors, OutputPatch<TessellationControlPoint, 3> patch, float3 barycentricCoordinates : SV_DomainLocation) {
                Interpolators o;
                 // boilerplate
                UNITY_SETUP_INSTANCE_ID(patch[0]);
                UNITY_TRANSFER_INSTANCE_ID(patch[0], o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                const float t = _Time.y;
                float3 wave_vec, wave_vec_sum; // (h, dh_dx, dh_dz)
                float2 D;
                float3 p = BARYCENTRIC_INTERPOLATE(posWS);

                for (int i = 0; i < _NumWaves; i++){
                    D = normalize(float2(cos(_D[i]), sin(_D[i])));
                    wave_vec = wave(_A[i], D, _K[i], _C[i], p.xz + wave_vec.yz, t);
                    wave_vec_sum += wave_vec;
                }
                const float3 T = float3(1.0, wave_vec_sum[1], 0.0);
                const float3 B = float3(0.0, wave_vec_sum[2], 1.0);
                const float3 n = normalize(cross(B, T));
                p.y += wave_vec_sum[0];

                o.posWS = p;
                o.pos = UnityWorldToClipPos(p);
                o.normalWS = n;
                return o;
            }

            fixed4 frag(Interpolators i) : SV_Target {
                const float3 lightDirWS = normalize(-_L);
                
                //diffuse
                const float diffuse = clampDot(lightDirWS, i.normalWS);
                
                // specular
                const float3 V = normalize(_WorldSpaceCameraPos-i.posWS);
                const float3 H = normalize(V + lightDirWS);
                float specular = clampDot(H, i.normalWS);
                specular = _SpecularGain*pow(specular, _SpecularExponent);
                
                // reflect
                const float3 R = 2*i.normalWS*(dot(i.normalWS, V))-V;
                const float4 skyData = UNITY_SAMPLE_TEXCUBE(unity_SpecCube0, normalize(R));
                const float3 reflectCol = DecodeHDR(skyData, unity_SpecCube0_HDR);
                const float fresnel = clamp(pow(1-dot(V, i.normalWS), 5), 0, 1);
                
                float4 col = float4(fresnel*reflectCol, 1) + _DiffuseColor*diffuse + fresnel*specular*_SpecularColor + _AmbientColor*_AmbientGain;
                UNITY_APPLY_FOG(i.fogCoord, col);
                return float4(i.normalWS, 1.0);
                return col;
            }
            ENDCG
        }
    }
}
