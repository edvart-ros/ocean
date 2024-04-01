using UnityEngine;
using OceanLib.Structs;
public class TesselatedOcean : MonoBehaviour
{

    public TessellationParams tesselation = new TessellationParams {
        minTessellationDistance = 100f,
        maxTessellationDistance = 600f,
        minTessellation = 1f,
        maxTessellation = 100f
    };

    public OceanParams ocean = new OceanParams {
        numberOfWaves = 12,
        baseAmplitude = 0.65f,
        baseFrequency = 0.05f,
        baseSpeed = 6.28f,
        amplitudeFalloff = 0.32f,
        frequencyGain = 0.21f,
        speedGain = 0.9f,
        regenerateDirs = false,
    };
    public Lighting lighting = new Lighting {
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

    


    private Material mat;
    private Vector3 lightVector = new Vector3(0.0f, -1.0f, 0.0f);  

    void Start()
    {
        mat = GetComponent<Renderer>().material;
        mat.SetVector("_L", lightVector);

        a = new float[128];
        k = new float[128];
        c = new float[128];
        d = new float[128];
        for (int i = 0; i < ocean.numberOfWaves; i++){
            if (i == 0){
                a[i] = ocean.baseAmplitude;
                k[i] = ocean.baseFrequency;
                c[i] = ocean.baseSpeed;
            }
            else if (i < ocean.numberOfWaves){
                k[i] = k[i-1]*(1+ocean.frequencyGain);
                a[i] = a[i-1]*(1-ocean.amplitudeFalloff);
                c[i] = c[i-1]*(1+ocean.speedGain);
            }
            else {
                k[i] = 0f;
                a[i] = 0f;
            }

            d[i] = Random.Range(0f, 2f*pi);
        }
    }

    void Update()
    {
        for (int i = 0; i < ocean.numberOfWaves; i++){
            if (i == 0){
                a[i] = ocean.baseAmplitude;
                k[i] = ocean.baseFrequency;
                c[i] = ocean.baseSpeed;
            }
            else if (i < ocean.numberOfWaves){
                k[i] = k[i-1]*(1+ocean.frequencyGain);
                a[i] = a[i-1]*(1-ocean.amplitudeFalloff);
                c[i] = c[i-1]*(1+ocean.speedGain);
            }
            else {
                k[i] = 0f;
                a[i] = 0f;
            }
            if (ocean.regenerateDirs){
                d[i] = Random.Range(0f, 2f*pi);
                ocean.regenerateDirs = false;
            }
        }
        lightVector = lighting.lightSource.transform.TransformDirection(Vector3.forward);
        mat.SetVector("_L", lightVector);
        mat.SetVector("_DiffuseColor", lighting.diffuseColor);
        mat.SetVector("_SpecularColor", lighting.specularColor);
        mat.SetVector("_AmbientColor", lighting.ambientColor);
        mat.SetInt("_NumWaves", ocean.numberOfWaves);
        mat.SetFloatArray("_A", a);
        mat.SetFloatArray("_D", d);
        mat.SetFloatArray("_K", k);
        mat.SetFloatArray("_C", c);
        mat.SetFloat("_SpecularExponent", lighting.specularExponent);
        mat.SetFloat("_SpecularGain", lighting.specularGain);
        mat.SetFloat("_AmbientGain",lighting. ambientGain);
    }
}
