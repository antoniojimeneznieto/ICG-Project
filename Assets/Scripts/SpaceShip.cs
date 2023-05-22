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

    private Rigidbody rb;
    private Camera spaceshipCamera; // Reference to the spaceship's camera

    private void Start()
    {
        // Get the rigidbody component
        rb = GetComponent<Rigidbody>();

        // Get the camera component
        spaceshipCamera = GetComponent<Camera>();

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

        // Get the inputs for moving forwards and backwards
        if (Input.GetKey(KeyCode.W) || Input.GetKey(KeyCode.UpArrow))
        {
            // Apply a force in the direction the spaceship is facing
            rb.AddForce(transform.forward * thrust);
        }
        if (Input.GetKey(KeyCode.S) || Input.GetKey(KeyCode.DownArrow))
        {
            // Apply a force in the opposite direction the spaceship is facing
            rb.AddForce(-transform.forward * thrust);
        }

        // Get the inputs for moving left and right
        if (Input.GetKey(KeyCode.A) || Input.GetKey(KeyCode.LeftArrow))
        {
            // Apply a force to the left
            rb.AddForce(-transform.right * thrust);
        }
        if (Input.GetKey(KeyCode.D) || Input.GetKey(KeyCode.RightArrow))
        {
            // Apply a force to the right
            rb.AddForce(transform.right * thrust);
        }

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

