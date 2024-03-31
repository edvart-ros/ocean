using UnityEngine;

public class CreatePlane : MonoBehaviour
{
    private Mesh mesh;
    private MeshFilter meshFilter;
    public float size = 40.0f;
    public int resolution = 100;

    private int[] tris;
    private Vector3[] verts;
    private Vector2[] uv;
    private Vector3 origin = new Vector3();

    private int prevResolution = 0;
    private float prevSize = 0;

    void Start()
    {
        meshFilter = GetComponent<MeshFilter>();
        mesh = new Mesh();
        mesh.indexFormat = UnityEngine.Rendering.IndexFormat.UInt32;
    }

    // Update is called once per frame
    void Update()
    {
        if (prevResolution != resolution || prevSize != size){
            verts = new Vector3[(resolution+1)*(resolution+1)];
            uv = new Vector2[(resolution+1)*(resolution+1)];
            tris = new int[resolution*resolution*2*3];
            
            mesh.Clear();
            ConstructMesh();
            meshFilter.mesh = mesh;
            
            prevResolution = resolution;
            prevSize = size;
        }
    }

    void ConstructMesh(){
        origin = new Vector3(-size/2, 0, -size/2);
        float step = size/resolution;
        
        // fill in vertices
        for (int i = 0; i <= resolution; i++){
            for (int j = 0; j <= resolution; j++){
                verts[i*(resolution+1)+j].z = origin.z + step*i;
                verts[i*(resolution+1)+j].x = origin.x + step*j;
                uv[i*(resolution+1)+j].y = (step*i)/size;
                uv[i*(resolution+1)+j].x = (step*j)/size;
            }
        }
        
        int triIdx = 0;
        for (int row = 0; row < resolution; row++){
            for (int column = 0; column < resolution; column++){
                int baseVertIdx = (resolution*row) + row + column;
                
                //lower tri
                tris[triIdx] = baseVertIdx;
                tris[triIdx+1] = baseVertIdx + (resolution + 2);
                tris[triIdx+2] = baseVertIdx + 1;

                //upper tri
                tris[triIdx+3] = baseVertIdx;
                tris[triIdx+4] = baseVertIdx + (resolution + 1);
                tris[triIdx+5] = baseVertIdx + (resolution + 2);
                triIdx += 6;
            }
        }
        mesh.vertices = verts;
        mesh.triangles = tris;
        mesh.uv = uv;
    }

    void dbg(){
        for (int i = 0; i < verts.Length; i++){
            Debug.DrawRay(verts[i], Vector3.up);
        }
    }
}
