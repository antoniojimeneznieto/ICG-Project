using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class FollowPlanet : MonoBehaviour
{
    public Transform planet; // Drag and drop the Planet GameObject here in the Inspector window
    public Transform star; // Drag and drop the Star GameObject here in the Inspector window
    public float xOffset = 1.0f; // The distance in the X axis relative to the planet
    public float yOffset = 1.1f; // The distance in the Y axis relative to the planet
    public float tiltAngle = 30f; // The tilt angle in the X-axis


    private float distanceFromPlanet; // The distance between the camera and the planet

    private void Start()
    {
        // Calculate the initial distance from the camera to the planet
        distanceFromPlanet = Vector3.Distance(transform.position, planet.position);
    }

    private void Update()
    {
        if (planet != null)
        {
            // Calculate the direction from the star to the planet and normalize it
            Vector3 directionToStar = (star.position - planet.position).normalized;

            // Calculate the camera's position behind the planet with the X and Y offsets
            Vector3 cameraPosition = planet.position - directionToStar * xOffset;
            cameraPosition.y += yOffset;

            // Set the new position
            transform.position = cameraPosition;

            // Make the camera look at the star
            if (star != null)
            {
                Quaternion lookRotation = Quaternion.LookRotation(directionToStar);
                Quaternion tiltRotation = Quaternion.Euler(tiltAngle, 0, 0);
                transform.rotation = lookRotation * tiltRotation;
            }
        }
    }

    
}

