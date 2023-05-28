using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlanetMovement : MonoBehaviour
{
    public float gravitationalConstant = 6.674f;  // Gravitational constant used to calculate the gravitational force.
    private Rigidbody bodyRigidbody;  // Rigidbody of the current object (planet).
    public Rigidbody otherBody;  // Rigidbody of the other body (typically, a star or another planet) with which the current object interacts gravitationally.

    public float orbitalEccentricity = 0.0f;  // The eccentricity of the orbit (0 for a circle, 0-1 for an ellipse).
    public bool setInitialOrbitalVelocity = true;  // Whether to set the initial orbital velocity.

    public float rotationalSpeed = 360.0f;  // Rotational speed in degrees per second. For Earth, this is roughly 360 degrees per day.

    void Start()
    {
        bodyRigidbody = GetComponent<Rigidbody>();  // Get the Rigidbody component attached to this GameObject.
        if (setInitialOrbitalVelocity)  // Check if we need to set the initial orbital velocity.
        {
            SetInitialOrbitalVelocity();  // Set the initial orbital velocity.
        }

        // Set the initial rotation speed
        float rotationSpeedInRadians = rotationalSpeed * Mathf.Deg2Rad;  // Convert rotational speed from degrees to radians.
        bodyRigidbody.angularVelocity = transform.up * rotationSpeedInRadians;  // Set the initial angular velocity.
    }

    private void FixedUpdate()
    {
        if (otherBody != null)  // Check if there's another body to interact with.
        {
            ApplyGravity(otherBody);  // Apply the gravitational force to this body.
        }
    }

    private void SetInitialOrbitalVelocity()
    {
        if (otherBody == null)
            return;

        float distance = (otherBody.transform.position - transform.position).magnitude;  // Calculate the distance between the bodies.
        // Calculate the magnitude of the orbital velocity.
        float orbitalVelocityMagnitude = Mathf.Sqrt(gravitationalConstant * otherBody.mass / distance) * (1 + orbitalEccentricity);
        // Calculate the direction of the orbital velocity.
        Vector3 orbitalVelocityDirection = Vector3.Cross((transform.position - otherBody.transform.position).normalized, Vector3.up);

        bodyRigidbody.velocity = orbitalVelocityDirection * orbitalVelocityMagnitude;  // Set the initial velocity of the Rigidbody.
    }

    private void ApplyGravity(Rigidbody otherBody)
    {
        Vector3 forceDirection = otherBody.transform.position - transform.position;  // Calculate the direction of the gravitational force.
        float distance = forceDirection.magnitude;  // Calculate the distance to the other body.
        // Calculate the magnitude of the gravitational force.
        float gravitationalForce = gravitationalConstant * ((bodyRigidbody.mass * otherBody.mass) / (distance * distance));
        Vector3 forceVector = forceDirection.normalized * gravitationalForce;  // Calculate the gravitational force vector.

        bodyRigidbody.AddForce(forceVector);  // Apply the gravitational force to this Rigidbody.
    }
}


