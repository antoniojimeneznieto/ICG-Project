using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class SpaceshipController : MonoBehaviour
{
    public float thrust = 1.0f;
    public float rotationSpeed = 3.0f;
    public float minFOV = 60.0f; // Minimum field of view
    public float maxFOV = 90.0f; // Maximum field of view
    public float maxSpeedFOV = 20.0f; // The speed at which the FOV will be at its maximum
    public float maxSpeed = 10.0f; // The maximum speed
    public float acceleration = 0.2f; // The acceleration rate

    private Rigidbody rb;
    private Camera spaceshipCamera; // Reference to the spaceship's camera
    private Vector3 currentVelocity = Vector3.zero; // The current velocity

    private void Start()
    {
        // Get the rigidbody component
        rb = GetComponent<Rigidbody>();

        // Get the camera component
        spaceshipCamera = GetComponentInChildren<Camera>();

        // Hide the cursor and lock it to the center of the screen
        Cursor.visible = false;
        Cursor.lockState = CursorLockMode.Locked;
    }

    private void FixedUpdate()
    {
        // Get the distance (in terms of screen size) that the mouse has moved
        float horizontalRotation = Input.GetAxis("Mouse X") * rotationSpeed;
        float verticalRotation = Input.GetAxis("Mouse Y") * rotationSpeed;

        // Rotate the spaceship according to the mouse movement
        transform.Rotate(-verticalRotation, horizontalRotation, 0);

        Vector3 desiredVelocity = Vector3.zero;

        // Get the inputs for moving forwards and backwards
        if (Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow))
        {
            desiredVelocity += transform.forward;
        }
        if (Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow))
        {
            desiredVelocity -= transform.forward;
        }

        // Get the inputs for moving left and right
        if (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow))
        {
            desiredVelocity -= transform.right;
        }
        if (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow))
        {
            desiredVelocity += transform.right;
        }

        desiredVelocity = desiredVelocity.normalized * maxSpeed;
        currentVelocity = Vector3.Lerp(currentVelocity, desiredVelocity, acceleration);

        // Apply the calculated velocity
        rb.velocity = currentVelocity;

        // Adjust the field of view based on the spaceship's speed
        float speed = rb.velocity.magnitude;
        spaceshipCamera.fieldOfView = Mathf.Lerp(minFOV, maxFOV, speed / maxSpeedFOV);
    }

    void OnCollisionEnter(Collision collision)
    {
        // This method will be called when a collision happens.
        // You can add code here to handle the collision, for example:
        Debug.Log("Collided with " + collision.gameObject.name);
    }
}
