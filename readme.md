---
title: Real-Time Atmospheric Scattering
---

![Description of image](images/atmosphere_from_planet.jpg){width="600px"}

# Title and Summary

This project aims to create an interactive 3D visualization of atmospheric scattering, allowing users to explore the various phenomena associated with the scattering of light in the Earth’s atmosphere such as Rayleigh scattering, Mie scattering, the resulting colors of the sky and various atmospheric optical effects.



# Goals and Deliverables

## Goals:

- Sky color gradient: Implement a smooth gradient demonstrating the color changes of the sky due to atmospheric scattering at various times of the day.

- The Tyndall effect: Visualize the scattering of sunlight by small particles in the air, which causes the sky to appear blue.

- Sunset and sunrise: Display the vibrant colors resulting from the longer path of sunlight through the atmosphere during these times.

- Atmospheric optical effects: Create visualizations of phenomena like halos, coronas, and rainbows, which result from scattering and refraction of light.



## Baseline plan (4.0):
- Implement the Nishita algorithms for simulating atmospheric scattering.

- Implement a 3D interactive visualization of atmospheric scattering using the graphics engine Unity.

- Create an intuitive user interface allowing users to explore different scattering phenomena and their effects on sky color and atmospheric optical effects.

- Develop a flight simulation mode that allows users to navigate through the atmosphere and the space, experiencing the effects of atmospheric scattering.

## Optional extensions: 

- Advanced Atmospheric Effects: 
    - Implement more advanced atmospheric effects, such as clouds, rain, rainbow. 
    - Incorporate spectral rendering to simulate wavelength-dependent scattering.

- Procedural Planets Generation System:
    - Design and implement an efficient procedural terrain generation algorithm.
    - Integrate the procedural planet generation system into a game engine.

- Procedural Flora:
    - Integrate procedural generation techniques to create varied flora on the planets.


# Schedule

## Week 1 (28 April - 5 May):
-   Learn and explore Unity basics, focusing on its rendering and shader capabilities.
-   Research the Nishita model and algorithms and implement them. 

## Week 2 (5 May - 12 May) (Milestone report):
-   Prepare the 3D models and the environment in Unity: create the sun, the planets, the   stars and other relevant celestial bodies. 
-   Set up the basic lighting and atmospheric scattering effects based on the algorithms implemented during week 1.

## Week 3 (12 May - 19 May):
-   Design and implement the User Interface.
-   Integrate the UI with the 3D visualization in Unity. 
-   Start working on optional features.

## Week 4 (19 May - 26 May):
-   Continue working on the optional features.
-   Test and debug the project.
-   Address any unexpected issues or problems during the implementation phase. 

## Week 5 (26 May - 2 June) (Final Week):
- Prepare documentation and presentation.
- Write the final report.


# Resources

[1] Nishita 1993, Display of The Earth Taking into Account Atmospheric Scattering - http://nishitalab.org/user/nis/cdrom/sig93_nis.pdf

[2] O’Neil, Accurate Atmospheric Scattering - https://developer.nvidia.com/gpugems/gpugems2/part-ii-shading-lighting-and-shadows/chapter-16-accurate-atmospheric-scattering

[3] Bruneton & Neyret 2008, Precomputed Atmospheric Scattering - https://hal.inria.fr/inria-00288758/document

[4] Angular Diameter - https://www.astronomy.swin.edu.au/cosmos/A/Angular+Diameter

[5] A Qualitative and Quantitative Evaluation of 8 Clear Sky Models - https://arxiv.org/pdf/1612.04336.pdf

[6] Spectral rendering - https://en.wikipedia.org/wiki/Spectral_rendering

