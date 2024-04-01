using UnityEngine;
using OceanLib.Structs;
public class TesselatedOcean : MonoBehaviour
{

    public TessellationParams tesselationParams = new TessellationParams {
        minTessellationDistance = 100f,
        maxTessellationDistance = 600f,
        minTessellation = 1f,
        maxTessellation = 100f
    };

    public OceanParams oceanParams = new OceanParams {
        numberOfWaves = 12,
        baseAmplitude = 0.65f,
        baseFrequency = 0.05f,
        baseSpeed = 6.28f,
        amplitudeFalloff = 0.32f,
        frequencyGain = 0.21f,
        speedGain = 0.9f,
        regenerateDirs = false,
    };
    public LightingParams lightingParams = new LightingParams {
        ambientColor = new Color(0.125f, 0.125f, 0.41f), // dark blue
        ambientGain = 0.1f,
        diffuseColor = new Color(0.03f, 0.03f, 0.06f), // black-blue
        specularColor = Color.white,
        specularExponent = 60f,
        specularGain = 1f,
        lightVector = new Vector3(0f, -1f, 0f),
    };

    const float pi = Mathf.PI;

    private float[] a;
    private float[] k;
    private float[] c;
    private float[] d;
    private OceanParams prevOceanParams;
    private TessellationParams prevTessParams;
    private LightingParams prevLightParams; 

    private Material mat;
    private Vector3 lightVector = new Vector3(0.0f, -1.0f, 0.0f);  

    void Start() {
        mat = GetComponent<Renderer>().material;
        mat.SetVector("_L", lightVector);

        a = new float[128];
        k = new float[128];
        c = new float[128];
        d = new float[128];
        for (int i = 0; i < oceanParams.numberOfWaves; i++){
            if (i == 0){
                a[i] = oceanParams.baseAmplitude;
                k[i] = oceanParams.baseFrequency;
                c[i] = oceanParams.baseSpeed;
            }
            else if (i < oceanParams.numberOfWaves){
                k[i] = k[i-1]*(1+oceanParams.frequencyGain);
                a[i] = a[i-1]*(1-oceanParams.amplitudeFalloff);
                c[i] = c[i-1]*(1+oceanParams.speedGain);
            }
            else {
                k[i] = 0f;
                a[i] = 0f;
            }

            d[i] = Random.Range(0f, 2f*pi);
        }
        prevTessParams = tesselationParams;
        prevOceanParams = oceanParams;
        prevLightParams = lightingParams;
    }


    void Update() {
        if (!oceanParams.Equals(prevOceanParams)){
            for (int i = 0; i < oceanParams.numberOfWaves; i++){
                if (i == 0){
                    a[i] = oceanParams.baseAmplitude;
                    k[i] = oceanParams.baseFrequency;
                    c[i] = oceanParams.baseSpeed;
                }
                else if (i < oceanParams.numberOfWaves){
                    k[i] = k[i-1]*(1+oceanParams.frequencyGain);
                    a[i] = a[i-1]*(1-oceanParams.amplitudeFalloff);
                    c[i] = c[i-1]*(1+oceanParams.speedGain);
                }
                else {
                    k[i] = 0f;
                    a[i] = 0f;
                }
                if (oceanParams.regenerateDirs){
                    d[i] = Random.Range(0f, 2f*pi);
                    oceanParams.regenerateDirs = false;
                }
            }
            mat.SetInt("_NumWaves", oceanParams.numberOfWaves);
            mat.SetFloatArray("_A", a);
            mat.SetFloatArray("_D", d);
            mat.SetFloatArray("_K", k);
            mat.SetFloatArray("_C", c);
        }

        if (!lightingParams.Equals(prevLightParams)) {
            lightVector = lightingParams.lightSource.transform.TransformDirection(Vector3.forward);
            mat.SetVector("_L", lightVector);
            mat.SetVector("_DiffuseColor", lightingParams.diffuseColor);
            mat.SetVector("_SpecularColor", lightingParams.specularColor);
            mat.SetVector("_AmbientColor", lightingParams.ambientColor);
            mat.SetFloat("_SpecularExponent", lightingParams.specularExponent);
            mat.SetFloat("_SpecularGain", lightingParams.specularGain);
            mat.SetFloat("_AmbientGain", lightingParams.ambientGain);
        }

        if (!tesselationParams.Equals(prevTessParams)) {
            mat.SetFloat("_MinTessDist", tesselationParams.minTessellationDistance);
            mat.SetFloat("_MaxTessDist", tesselationParams.maxTessellationDistance);
            mat.SetFloat("_MinTess", tesselationParams.minTessellation);
            mat.SetFloat("_MaxTess", tesselationParams.maxTessellation);
        }
    }
}
