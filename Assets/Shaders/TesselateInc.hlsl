
float _MinTessDist, _MaxTessDist, _MinTess, _MaxTess;

// mesh data inputs to vertex shader
struct appdata
{
    float4 vertex : POSITION;
};


float getTessellationFactor(const float d) {
    const float clampedDistance = clamp(d, _MinTessDist, _MaxTessDist);
    float normalizedDistance = (clampedDistance - _MinTessDist) / (_MaxTessDist - _MinTessDist);
    float tessellationFactor = lerp(_MaxTess, _MinTess, normalizedDistance);
    return tessellationFactor;
}

// helper macro for domain shader
#define BARYCENTRIC_INTERPOLATE(fieldName) \
patch[0].fieldName * barycentricCoordinates.x + \
patch[1].fieldName * barycentricCoordinates.y + \
patch[2].fieldName * barycentricCoordinates.z


// runs on each vertex, outputs data to the hull shader
TessellationControlPoint vert (appdata v)
{
    TessellationControlPoint o;
    
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
TessellationControlPoint hull(
    InputPatch<TessellationControlPoint, 3> patch, // Input triangle
    uint id : SV_OutputControlPointID) { // Vertex index on the triangle
        
        return patch[id];
}
    
TessellationFactors PatchConstantFunction(InputPatch<TessellationControlPoint, 3> patch) {
    UNITY_SETUP_INSTANCE_ID(patch[0]);
    // calculate tessellation factors
    TessellationFactors f;
    const float3 p = (patch[0].posWS + patch[1].posWS + patch[2].posWS)/3.0;
    const float d = length(_WorldSpaceCameraPos - p);
    int tessFactor = 1;
    if (d < _MinTessDist){
        tessFactor = _MaxTess;
    }
    else if (d > _MaxTessDist){
        tessFactor = _MinTess;
    }
    else {
        tessFactor = getTessellationFactor(d);
    }
    f.edge[0] = tessFactor;
    f.edge[1] = tessFactor;
    f.edge[2] = tessFactor;
    f.inside = (f.edge[0] + f.edge[1] + f.edge[2]) * (1 / 3.0);
    return f;
}