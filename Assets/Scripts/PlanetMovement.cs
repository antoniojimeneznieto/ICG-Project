using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class PlanetMovement : MonoBehaviour
{
    // Variables to store the gravitational constant, the rigidbody component of the object, and another rigidbody that the object will orbit.
    public float gravitationalConstant = 6.674f;
    private Rigidbody bodyRigidbody;
    public Rigidbody otherBody;

    // Variables for the orbital eccentricity and whether to set the initial orbital velocity.
    public float orbitalEccentricity = 0.0f;
    public bool setInitialOrbitalVelocity = true;

    // The speed of rotation in degrees per second.
    public float rotationalSpeed = 360.0f;

    void Start()
    {
        // Retrieve the rigidbody component and set the initial orbital velocity if required.
        bodyRigidbody = GetComponent<Rigidbody>();
        if (setInitialOrbitalVelocity)
        {
            SetInitialOrbitalVelocity();
        }

        // Convert the rotational speed to radians and set the angular velocity.
        float rotationSpeedInRadians = rotationalSpeed * Mathf.Deg2Rad;
        bodyRigidbody.angularVelocity = transform.up * rotationSpeedInRadians;
    }

    private void FixedUpdate()
    {
        // If there's another body specified, apply the gravitational force towards it.
        if (otherBody != null)
        {
            ApplyGravity(otherBody);
        }
    }

    private void SetInitialOrbitalVelocity()
    {
        // If no other body is specified, don't set the orbital velocity.
        if (otherBody == null)
            return;

        // Calculate the distance to the other body and the magnitude of the orbital velocity.
        float distance = (otherBody.transform.position - transform.position).magnitude;
        float orbitalVelocityMagnitude = Mathf.Sqrt(gravitationalConstant * otherBody.mass / (distance * (1 + orbitalEccentricity)));

        // Calculate the direction of the orbital velocity.
        Vector3 directionToOther = (transform.position - otherBody.transform.position).normalized;
        Vector3 arbitraryPerpendicular = GetArbitraryPerpendicular(directionToOther);
        Vector3 orbitalVelocityDirection = Vector3.Cross(directionToOther, arbitraryPerpendicular);

        // Set the velocity of the rigidbody.
        bodyRigidbody.velocity = orbitalVelocityDirection * orbitalVelocityMagnitude;
    }

    private Vector3 GetArbitraryPerpendicular(Vector3 vector)
    {
        // If the vector is zero, return zero.
        if (vector == Vector3.zero)
            return Vector3.zero;
        // If the vector is not parallel to the up vector, return a vector perpendicular to the input vector and the up vector.
        else if (vector != Vector3.up && vector != Vector3.down)
            return Vector3.Cross(vector, Vector3.up);
        // If the vector is parallel to the up vector, return a vector perpendicular to the input vector and the right vector.
        else
            return Vector3.Cross(vector, Vector3.right);
    }

    private void ApplyGravity(Rigidbody otherBody)
    {
        // Calculate the direction of the gravitational force and the distance to the other body.
        Vector3 forceDirection = otherBody.transform.position - transform.position;
        float distance = forceDirection.magnitude;

        // Calculate the magnitude of the gravitational force.
        float gravitationalForce = gravitationalConstant * ((bodyRigidbody.mass * otherBody.mass) / (distance * distance));

        // Calculate the gravitational force vector.
        Vector3 forceVector = forceDirection.normalized * gravitationalForce;

        // Apply the gravitational force to the rigidbody.
        bodyRigidbody.AddForce(forceVector);
    }
}

