using UnityEngine;

public class Ocean : MonoBehaviour
{
    const float pi = Mathf.PI;
    public GameObject lightSource;

    [Range(1, 128)]
    public int numberOfWaves = 10;
    public float baseAmplitude = 1.0f;
    public float baseFrequency = 1.0f;
    [Range(0f, 2*pi)]
    public float baseSpeed;
    [Range(0.001f, 0.999f)]
    public float amplitudeFalloff = 0.18f;
    [Range(0.001f, 0.999f)]
    public float frequencyGain = 0.18f;
    [Range(0.001f, 0.999f)]
    public float speedGain = 0.18f;
    [Range(1f, 400f)]
    public float specularExponent = 60.0f;
    public bool regenerateDirs = false;
    
    private float[] a;
    private float[] k;
    private float[] c;
    private float[] d;

    public Color ambientColor = Color.blue;
    [Range(0f, 1f)]
    public float ambientGain = 0.1f;
    public Color diffuseColor = Color.blue;
    public Color specColor = Color.blue;
    [Range(0f, 1f)]
    public float specularGain = 1f;
    


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
        for (int i = 0; i < numberOfWaves; i++){
            if (i == 0){
                a[i] = baseAmplitude;
                k[i] = baseFrequency;
                c[i] = baseSpeed;
            }
            else if (i < numberOfWaves){
                k[i] = k[i-1]*(1+frequencyGain);
                a[i] = a[i-1]*(1-amplitudeFalloff);
                c[i] = c[i-1]*(1+speedGain);
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
        for (int i = 0; i < numberOfWaves; i++){
            if (i == 0){
                a[i] = baseAmplitude;
                k[i] = baseFrequency;
                c[i] = baseSpeed;
            }
            else if (i < numberOfWaves){
                k[i] = k[i-1]*(1+frequencyGain);
                a[i] = a[i-1]*(1-amplitudeFalloff);
                c[i] = c[i-1]*(1+speedGain);
            }
            else {
                k[i] = 0f;
                a[i] = 0f;
            }
            if (regenerateDirs){
                d[i] = Random.Range(0f, 2f*pi);
                regenerateDirs = false;
            }
        }
        lightVector = lightSource.transform.TransformDirection(Vector3.forward);
        mat.SetVector("_L", lightVector);
        mat.SetVector("_DiffuseColor", diffuseColor);
        mat.SetVector("_SpecularColor", specColor);
        mat.SetVector("_AmbientColor", ambientColor);
        mat.SetInt("_NumWaves", numberOfWaves);
        mat.SetFloatArray("_A", a);
        mat.SetFloatArray("_D", d);
        mat.SetFloatArray("_K", k);
        mat.SetFloatArray("_C", c);
        mat.SetFloat("_SpecularExponent", specularExponent);
        mat.SetFloat("_SpecularGain", specularGain);
        mat.SetFloat("_AmbientGain", ambientGain);
    }
}
