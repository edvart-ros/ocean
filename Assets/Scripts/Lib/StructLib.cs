using System;
using Unity.Collections;
using UnityEngine;

namespace OceanLib.Structs
{
    [Serializable]
    public struct TessellationParams {
        public float minTessellationDistance;
        public float maxTessellationDistance;
        public float minTessellation;
        public float maxTessellation;
    }

    [Serializable]
    public struct OceanParams {
        [Range(1, 128)]
        public int numberOfWaves;
        public float baseAmplitude;
        public float baseFrequency;
        [Range(0f, 10f)]
        public float baseSpeed;
        [Range(0.001f, 0.999f)]
        public float amplitudeFalloff;
        [Range(0.001f, 0.999f)]
        public float frequencyGain;
        [Range(0.001f, 0.999f)]
        public float speedGain;
        [Range(1f, 400f)]
        public float specularExponent;
        public bool regenerateDirs;
    }

    [Serializable]
    public struct Lighting {
        public GameObject lightSource;
        public Color ambientColor;
        [Range(0f, 1f)]
        public float ambientGain;
        [Range(0f, 1f)]
        public float specularGain;
        [Range(1f, 200f)]
        public float specularExponent;
        public Color diffuseColor;
        public Color specularColor;
        [ReadOnly]
        public Vector3 lightVector;
    }

}
