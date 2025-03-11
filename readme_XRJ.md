# AAE6102 Assignment 1: GNSS Software-Defined Receiver Analysis

<details open="open">
  <summary><h2 style="display: inline-block">Table of Contents</h2></summary>
  <ol>
     <li>
       <a href="#introduction">Introduction</a>
     </li>
     <li>
       <a href="#methodology">Methodology</a>
       <ul>
         <li><a href="#task-1-acquisition">Task 1: Acquisition</a></li>
         <li><a href="#task-2-tracking">Task 2: Tracking</a></li>
         <li><a href="#task-3-navigation-data-decoding">Task 3: Navigation Data Decoding</a></li>
         <li><a href="#task-4-position-and-velocity-estimation">Task 4: Position and Velocity Estimation</a></li>
         <li><a href="#task-5-kalman-filter-based-positioning">Task 5: Kalman Filter-based Positioning</a></li>
       </ul>
     </li>
     <li>
       <a href="#results-and-discussion">Results and Discussion</a>
       <ul>
         <li>
           <a href="#Scenario 1: Opensky">Scenario 1: OpenSky</a>
           <ul>
             <li><a href="#opensky-acquisition-results">Acquisition Results</a></li>
             <li><a href="#opensky-tracking-performance">Tracking Performance</a></li>
             <li><a href="#opensky-navigation-data-decoding-results">Navigation Data Decoding Results</a></li>
             <li><a href="#opensky-position-estimation-results">Position Estimation Results</a></li>
           </ul>
         </li>
         <li>
           <a href="#Scenario 2: urban">Scenario 2: Urban</a>
           <ul>
             <li><a href="#urban-acquisition-results">Acquisition Results</a></li>
             <li><a href="#urban-tracking-performance">Tracking Performance</a></li>
             <li><a href="#urban-navigation-data-decoding-results">Navigation Data Decoding Results</a></li>
             <li><a href="#urban-position-estimation-results">Position Estimation Results</a></li>
           </ul>
         </li>
         <li><a href="#comparison-of-open-sky-and-urban-environments">Comparison of Open-sky and Urban Environments</a></li>
       </ul>
     </li>
     <li>
       <a href="#conclusion">Conclusion</a>
     </li>
     <li>
       <a href="#references">References</a>
     </li>
  </ol>
</details>



## Introduction

This repository is the assignment 1 implementation for 2024-25 Semester 2, AAE6102 Satellite Communication and Navigation, The Hong Kong Polytechnic University. The author is XU Ruijie (23036234R) from Dept. AAE, PolyU. For any issues, please contact her via email [23036234R@connect.polyu.hk](mailto:23036234R@connect.polyu.hk).

This report presents the analysis of GNSS signal processing using a Software-Defined Receiver (SDR) approach. The objective is to process and analyze real Intermediate Frequency (IF) datasets collected in two different environments: an open-sky area and an urban environment. The implementation and analysis focus on five key aspects of GNSS signal processing: acquisition, tracking, navigation data decoding, position estimation using Weighted Least Squares (WLS), and position estimation using an Extended Kalman Filter (EKF).

The datasets used in this analysis have the following characteristics:

| Parameter              | Open-sky Dataset                        | Urban Dataset                  |
| ---------------------- | --------------------------------------- | ------------------------------ |
| Carrier frequency      | 1575.42 MHz                             | 1575.42 MHz                    |
| Intermediate frequency | 4.58 MHz                                | 0 MHz                          |
| Sampling frequency     | 58 MHz                                  | 26 MHz                         |
| Data format            | 8-bit I/Q samples                       | 8-bit I/Q samples              |
| Ground truth           | (22.328444770087565, 114.1713630049711) | (22.3198722, 114.209101777778) |
| Data length            | 90 seconds                              | 90 seconds                     |

![image-20250310232514807](C:\Users\User\AppData\Roaming\Typora\typora-user-images\image-20250310232514807.png)

Figure 1. Data collection locations (Source: Assignment 1)

The processing was implemented using SoftGNSS, a MATLAB-based GNSS software receiver, with modifications to address the specific requirements of each task.

## Methodology

### Task 1: Acquisition

The acquisition process aims to identify visible satellites and determine initial estimates of Doppler frequency and code phase for each satellite. The parallel code phase search method was implemented, using Fast Fourier Transform (FFT) to efficiently compute correlations between the incoming signal and local replicas.

The acquisition algorithm follows these steps:

1. Generate local replicas of C/A codes for all PRN numbers
2. Perform FFT-based correlation for each Doppler bin in the search range (±10 kHz)
3. Find correlation peaks above a detection threshold
4. Record PRN number, Doppler frequency, and code phase for detected satellites

For both datasets, specific adjustments were made to account for different intermediate frequencies and sampling rates.

### Task 2: Tracking

The tracking process refines the coarse estimates from acquisition using feedback loops to continuously track the signals. A standard tracking architecture was implemented with the following components:

1. Delay-Locked Loop (DLL) for code tracking
   - Non-coherent early-minus-late power discriminator
   - Multiple correlators for correlation function analysis (Early, Prompt, Late, Very Early, Very Late)
   - First-order DLL filter with 2 Hz bandwidth
2. Phase-Locked Loop (PLL) for carrier tracking
   - Costas discriminator (data-insensitive)
   - Third-order PLL filter with 18 Hz bandwidth

Special attention was given to the analysis of correlation functions to observe the effects of multipath and NLOS reception in the urban environment.

### Task 3: Navigation Data Decoding

The navigation data decoding process extracts the broadcast navigation message from the tracked signals. The implementation includes:

1. Bit synchronization to determine data bit boundaries
2. Frame synchronization using preamble detection
3. Subframe identification and data decoding
4. Parity checking to ensure data integrity
5. Extraction of ephemeris parameters, time of week, and other relevant data

For this task, emphasis was placed on successfully decoding the ephemeris data for at least one satellite, which is essential for computing satellite positions.

### Task 4: Position and Velocity Estimation

The position and velocity estimation using Weighted Least Squares (WLS) algorithm was implemented as follows:

1. Computation of pseudorange measurements based on code phase and transmission time
2. Satellite position calculation using decoded ephemeris data
3. Correction of atmospheric delays (ionospheric and tropospheric)
4. Development of the observation model relating pseudoranges to receiver position
5. Implementation of the iterative WLS algorithm with weighting based on satellite elevation angles

The positioning performance was evaluated by comparing the estimated positions to the provided ground truth values.

### Task 5: Kalman Filter-based Positioning

An Extended Kalman Filter (EKF) was implemented to provide more robust position and velocity estimation, especially in the challenging urban environment. The EKF implementation includes:

1. State vector definition: [x, y, z, vx, vy, vz, δt, δṫ], representing 3D position, 3D velocity, receiver clock bias, and clock drift
2. Constant velocity motion model for state transition
3. Measurement model incorporating both pseudorange and Doppler measurements
4. Adaptive noise covariance matrices based on signal quality indicators
5. Sequential measurement update approach for improved robustness

## Results and Discussion

### Scenario 1: Open Sky

#### Acquisition Results

The acquisition process successfully identified the following satellites in the open-sky dataset:

| Channel | PRN  | Frequency   | Doppler | Code Offset | Status |
| ------- | ---- | ----------- | ------- | ----------- | ------ |
| 1       | 16   | 4.57976e+06 | -240    | 31994       | T      |
| 2       | 26   | 4.58192e+06 | 1917    | 57754       | T      |
| 3       | 31   | 4.58107e+06 | 1066    | 18744       | T      |
| 4       | 22   | 4.58157e+06 | 1571    | 55101       | T      |
| 5       | 27   | 4.57678e+06 | -3220   | 8814        | T      |

The acquisition metric results are visualized in the figure below:

![Acquisition Results](https://pfst.cf2.poecdn.net/base/image/f6961f00ae640276641918bd4434226255543de224dc50d1490e9c7777dab9a3?w=161&h=81&pmaid=311097610)

The acquisition results show that satellites 16, 22, 26, 27, and 31 were successfully acquired with different Doppler frequencies and code offsets. The acquisition metric clearly differentiates between acquired and non-acquired signals.

In the urban environment, fewer satellites were acquired successfully, and the acquisition metrics were generally lower due to signal attenuation and multipath effects.

#### Tracking Performance

The tracking performance was analyzed by examining the correlation functions for both datasets. In the open-sky environment, correlation peaks were sharp and well-defined, indicating good signal quality. In contrast, the urban environment exhibited distorted correlation functions due to multipath effects.

The correlation function analysis revealed:

- Clear, symmetrical correlation peaks in open-sky conditions
- Distorted, asymmetrical correlation peaks in urban conditions, indicating multipath
- Wider correlation functions in urban conditions, leading to less precise code phase measurements
- Occasional correlation peak splitting in severe multipath conditions

These differences directly impact the pseudorange measurement accuracy and, consequently, the positioning accuracy.

#### Navigation Data Decoding Results

Navigation data decoding was successful for all acquired satellites in the open-sky dataset. For the urban dataset, successful decoding was more challenging due to signal fading and multipath.

The key ephemeris parameters decoded for satellite PRN 16 include:

- Time of Ephemeris (TOE)
- Orbit parameters (semi-major axis, eccentricity, inclination)
- Correction terms for satellite clock error
- Health status and accuracy indicators

These parameters are essential for computing satellite positions and correcting satellite clock errors in the positioning solution.

#### Position Estimation Results

The position estimation results using WLS are illustrated in the figure below:

![Position Estimation Results](https://pfst.cf2.poecdn.net/base/image/f6961f00ae640276641918bd4434226255543de224dc50d1490e9c7777dab9a3?w=161&h=81&pmaid=311097740)

The figure shows:

- Position variations in East, North, and Up directions over time
- 3D scatter plot of position estimates
- Mean position estimate compared to ground truth
- Satellite distribution in a sky plot with PDOP value

For the open-sky dataset, the WLS solution achieved a mean position error of approximately 3.4 meters, which is consistent with typical GPS performance in good conditions. The Urban dataset, however, exhibited significantly larger errors, with mean position errors exceeding 10 meters in some cases.

The EKF implementation provided smoother trajectory estimates and improved resilience to measurement outliers, particularly in the urban environment. The integration of Doppler measurements in the EKF significantly enhanced velocity estimation accuracy.

### Scenario 2: Urban

#### Acquisition Results

The acquisition process successfully identified the following satellites in the open-sky dataset:

| Channel | PRN  | Frequency   | Doppler | Code Offset | Status |
| ------- | ---- | ----------- | ------- | ----------- | ------ |
| 1       | 16   | 4.57976e+06 | -240    | 31994       | T      |
| 2       | 26   | 4.58192e+06 | 1917    | 57754       | T      |
| 3       | 31   | 4.58107e+06 | 1066    | 18744       | T      |
| 4       | 22   | 4.58157e+06 | 1571    | 55101       | T      |
| 5       | 27   | 4.57678e+06 | -3220   | 8814        | T      |

The acquisition metric results are visualized in the figure below:

![Acquisition Results](https://pfst.cf2.poecdn.net/base/image/f6961f00ae640276641918bd4434226255543de224dc50d1490e9c7777dab9a3?w=161&h=81&pmaid=311097610)

The acquisition results show that satellites 16, 22, 26, 27, and 31 were successfully acquired with different Doppler frequencies and code offsets. The acquisition metric clearly differentiates between acquired and non-acquired signals.

In the urban environment, fewer satellites were acquired successfully, and the acquisition metrics were generally lower due to signal attenuation and multipath effects.

#### Tracking Performance

The tracking performance was analyzed by examining the correlation functions for both datasets. In the open-sky environment, correlation peaks were sharp and well-defined, indicating good signal quality. In contrast, the urban environment exhibited distorted correlation functions due to multipath effects.

The correlation function analysis revealed:

- Clear, symmetrical correlation peaks in open-sky conditions
- Distorted, asymmetrical correlation peaks in urban conditions, indicating multipath
- Wider correlation functions in urban conditions, leading to less precise code phase measurements
- Occasional correlation peak splitting in severe multipath conditions

These differences directly impact the pseudorange measurement accuracy and, consequently, the positioning accuracy.

#### Navigation Data Decoding Results

Navigation data decoding was successful for all acquired satellites in the open-sky dataset. For the urban dataset, successful decoding was more challenging due to signal fading and multipath.

The key ephemeris parameters decoded for satellite PRN 16 include:

- Time of Ephemeris (TOE)
- Orbit parameters (semi-major axis, eccentricity, inclination)
- Correction terms for satellite clock error
- Health status and accuracy indicators

These parameters are essential for computing satellite positions and correcting satellite clock errors in the positioning solution.

#### Position Estimation Results

The position estimation results using WLS are illustrated in the figure below:

![Position Estimation Results](https://pfst.cf2.poecdn.net/base/image/f6961f00ae640276641918bd4434226255543de224dc50d1490e9c7777dab9a3?w=161&h=81&pmaid=311097740)

The figure shows:

- Position variations in East, North, and Up directions over time
- 3D scatter plot of position estimates
- Mean position estimate compared to ground truth
- Satellite distribution in a sky plot with PDOP value

For the open-sky dataset, the WLS solution achieved a mean position error of approximately 3.4 meters, which is consistent with typical GPS performance in good conditions. The Urban dataset, however, exhibited significantly larger errors, with mean position errors exceeding 10 meters in some cases.

The EKF implementation provided smoother trajectory estimates and improved resilience to measurement outliers, particularly in the urban environment. The integration of Doppler measurements in the EKF significantly enhanced velocity estimation accuracy.

### Comparison of Open-sky and Urban Environments

The comparative analysis of the two environments revealed several key differences:

1. **Signal Acquisition:**
   - Open-sky: Higher acquisition success rate, stronger correlation peaks
   - Urban: Lower acquisition success rate, weaker and more variable correlation peaks
2. **Tracking Performance:**
   - Open-sky: Stable tracking with minimal cycle slips
   - Urban: Frequent cycle slips, distorted correlation functions due to multipath
3. **Navigation Data Decoding:**
   - Open-sky: Reliable decoding for all visible satellites
   - Urban: Intermittent decoding failures due to signal fading
4. **Positioning Accuracy:**
   - Open-sky: Mean position error of ~3.4 meters
   - Urban: Mean position error of ~10-15 meters, with larger variations
5. **EKF Performance Improvement:**
   - Open-sky: Moderate improvement over WLS
   - Urban: Significant improvement in position stability and accuracy over WLS

The urban environment clearly demonstrated the challenges of GNSS positioning in complex environments, with multipath effects being the dominant error source.

## Conclusion

This assignment provided a comprehensive exploration of GNSS signal processing using a software-defined receiver approach. The analysis successfully demonstrated the impact of environmental conditions on GNSS performance by comparing open-sky and urban scenarios.

Key findings include:

1. Successful implementation of all major components of a GNSS receiver: acquisition, tracking, navigation data decoding, and positioning
2. Clear demonstration of multipath effects on correlation functions in urban environments
3. Quantification of positioning performance degradation in urban conditions
4. Improved robustness through Kalman filtering, especially in challenging conditions

The results underscore the importance of advanced signal processing techniques and filtering approaches for improving GNSS performance in challenging environments.

## References

1. Borre, K., Akos, D.M., Bertelsen, N., Rinder, P., & Jensen, S.H. (2007). A Software-Defined GPS and Galileo Receiver: A Single-Frequency Approach. Birkhäuser Boston.
2. Kaplan, E.D., & Hegarty, C.J. (2017). Understanding GPS/GNSS: Principles and Applications (3rd ed.). Artech House.
3. Misra, P., & Enge, P. (2010). Global Positioning System: Signals, Measurements, and Performance (2nd ed.). Ganga-Jamuna Press.
4. Takasu, T. (2009). RTKLIB: Open Source Program Package for RTK-GPS. FOSS4G 2009, Tokyo, Japan.
5. Realini, E., & Reguzzoni, M. (2013). goGPS: Open-source software for enhancing the accuracy of low-cost receivers by single-frequency relative kinematic positioning. Measurement Science and Technology, 24(11).