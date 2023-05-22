using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlanetMovement : MonoBehaviour
{
    public float gravitationalConstant = 6.674f;
    private Rigidbody bodyRigidbody;
    public Rigidbody otherBody;

    public float orbitalEccentricity = 0.0f;
    public bool setInitialOrbitalVelocity = true;

    public float rotationalSpeed = 360.0f; // Rotational speed in degrees per second. For Earth, this is roughly 360 degrees per day.

    void Start()
    {
        bodyRigidbody = GetComponent<Rigidbody>();
        if (setInitialOrbitalVelocity)
        {
            SetInitialOrbitalVelocity();
        }

        // Set the initial rotation speed
        float rotationSpeedInRadians = rotationalSpeed * Mathf.Deg2Rad;
        bodyRigidbody.angularVelocity = transform.up * rotationSpeedInRadians;
    }

    private void FixedUpdate()
    {
        if (otherBody != null)
        {
            ApplyGravity(otherBody);
        }
    }

    private void SetInitialOrbitalVelocity()
    {
        if (otherBody == null)
            return;

        float distance = (otherBody.transform.position - transform.position).magnitude;
        float orbitalVelocityMagnitude = Mathf.Sqrt(gravitationalConstant * otherBody.mass / distance) * (1 + orbitalEccentricity);
        Vector3 orbitalVelocityDirection = Vector3.Cross((transform.position - otherBody.transform.position).normalized, Vector3.up);

        bodyRigidbody.velocity = orbitalVelocityDirection * orbitalVelocityMagnitude;
    }

    private void ApplyGravity(Rigidbody otherBody)
    {
        Vector3 forceDirection = otherBody.transform.position - transform.position;
        float distance = forceDirection.magnitude;
        float gravitationalForce = gravitationalConstant * ((bodyRigidbody.mass * otherBody.mass) / (distance * distance));
        Vector3 forceVector = forceDirection.normalized * gravitationalForce;

        bodyRigidbody.AddForce(forceVector);
    }
}

