Shader "Ocean"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            #define PI 3.14159265

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };
            
            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 pos : SV_POSITION;
                float3 normal : TEXCOORD2;
                float3 normalWS : TEXCOORD3;
                float3 posWS : TEXCOORD4;
            };

            
            sampler2D _MainTex;
            float4 _MainTex_ST;
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
            int _Debug;
            
            float4 f4(const float3 f){
                return float4(f, 1.0);
            }

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


            v2f vert (appdata v)
            {
                v2f o;
                float2 D;
                
                float4 vert = v.vertex;
                const float t = _Time.y;
                float3 wave_vec; // (h, dh_dx, dh_dz)
                float3 wave_vec_sum = float3(0, 0, 0);

                for (int i = 0; i < _NumWaves; i++){
                    D = normalize(float2(cos(_D[i]), sin(_D[i])));
                    wave_vec = wave(_A[i], D, _K[i], _C[i], vert.xz + wave_vec.yz, t);
                    wave_vec_sum += wave_vec;
                }

                const float3 T = float3(1.0, wave_vec_sum[1], 0.0);
                const float3 B = float3(0.0, wave_vec_sum[2], 1.0);
                const float3 n = normalize(cross(B, T));
                vert.y = wave_vec_sum[0];

                o.pos = UnityObjectToClipPos(vert);
                o.posWS = mul(unity_ObjectToWorld, float4(vert));
                o.normal = n;
                o.normalWS = UnityObjectToWorldNormal(n);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                UNITY_TRANSFER_FOG(o,o.pos);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
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
                return col;
                return col; 
            }

            ENDCG
        }
    }
}
