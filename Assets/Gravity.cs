using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Gravity : MonoBehaviour
{
    public float gravitationalConstant = 6.674f; // Adjust this value to control the strength of the gravitational force
    private static List<Gravity> celestialBodies = new List<Gravity>();
    private Rigidbody bodyRigidbody;

    public float mass = 1.0f; // Mass of the celestial body
    public float orbitalEccentricity = 0.0f; // Eccentricity of the celestial body's orbit
    public bool isStationary = false;
    public bool setInitialOrbitalVelocity = true;

    private void Awake() {
        celestialBodies.Add(this);
    }

    private void OnDestroy() {
        celestialBodies.Remove(this);
    }

    private void Start() {
        // Add a Rigidbody to the celestial body and disable gravity
        bodyRigidbody = gameObject.AddComponent<Rigidbody>();
        bodyRigidbody.useGravity = false;
        bodyRigidbody.mass = mass;

        if (isStationary)
        {
            bodyRigidbody.constraints = RigidbodyConstraints.FreezeAll;
            bodyRigidbody.velocity = Vector3.zero;
        }

        if (setInitialOrbitalVelocity)
        {
            SetInitialOrbitalVelocity();
        }
    }

    private void FixedUpdate() {
        foreach (Gravity otherBody in celestialBodies)
        {
            if (otherBody != this)
            {
                ApplyGravity(otherBody);
            }
        }
    }

    private void ApplyGravity(Gravity otherBody) {
        // Calculate the gravitational force
        Vector3 forceDirection = otherBody.transform.position - transform.position;
        float distance = forceDirection.magnitude;
        float gravitationalForce = gravitationalConstant * ((mass * otherBody.mass) / (distance * distance));
        Vector3 forceVector = forceDirection.normalized * gravitationalForce;

        // Apply the force to the celestial body
        bodyRigidbody.AddForce(forceVector);
    }

    private void SetInitialOrbitalVelocity()
    {
        // Find the most massive celestial body
        Gravity mostMassiveBody = null;
        float maxMass = float.MinValue;

        foreach (Gravity otherBody in celestialBodies)
        {
            if (otherBody != this)
            {
                if (otherBody.mass > maxMass)
                {
                    maxMass = otherBody.mass;
                    mostMassiveBody = otherBody;
                }
            }
        }

        if (mostMassiveBody == null)
            return;

        // Calculate the orbital velocity
        float distance = (mostMassiveBody.transform.position - transform.position).magnitude;
        float orbitalVelocityMagnitude = Mathf.Sqrt(gravitationalConstant * mostMassiveBody.mass / distance) * (1 + orbitalEccentricity);
        Vector3 orbitalVelocityDirection = Vector3.Cross((transform.position - mostMassiveBody.transform.position).normalized, Vector3.up);

        // Set the initial velocity
        bodyRigidbody.velocity = orbitalVelocityDirection * orbitalVelocityMagnitude;
    }
}
