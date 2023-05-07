using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SunMovement : MonoBehaviour
{
    public Transform centerOfRotation;
    public float rotationSpeed = 10f;
    public Vector3 rotationAxis = new Vector3(0, 1, 0);

    void Update()
    {
        if (centerOfRotation != null)
        {
            transform.RotateAround(centerOfRotation.position, rotationAxis, rotationSpeed * Time.deltaTime);
        }
    }
}
