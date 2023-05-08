using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlanetShaderController : MonoBehaviour
{
    public Material planetMaterial;
    private Vector3 planetCenter;

    void Update()
    {
        planetCenter = transform.position;
        planetMaterial.SetVector("_PlanetCenter", planetCenter);
    }
}

