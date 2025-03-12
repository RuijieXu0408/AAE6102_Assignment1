# AAE6102 Assignment 1: GNSS Software-Defined Receiver Analysis

<details open="open">
  <summary><h2 style="display: inline-block">Table of Contents</h2></summary>
  <ol>
    <li>
      <a href="#introduction">Introduction</a>
    </li>
    <li>
      <a href="#task-1-acquisition">Task 1: Acquisition</a>
    </li>
    <li>
      <a href="#task-2-tracking">Task 2: Tracking</a>
    </li>
    <li>
      <a href="#task-3-navigation-data-decoding">Task 3: Navigation Data Decoding</a>
    </li>
    <li>
      <a href="#task-4-position-and-velocity-estimation">Task 4: Position and Velocity Estimation</a>
    </li>
    <li>
      <a href="#task-5-kalman-filter-based-positioning">Task 5: Kalman filter-based positioning</a>
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

![Fig1](https://github.com/RuijieXu0408/AAE6102_Assignment1/blob/main/img/Fig1.png)

Figure 1. Data collection locations (Source: Assignment 1)

The code is modified and implemented on SoftGNSS, a MATLAB-based GNSS software receiver, with modifications to address the specific requirements of each task.

## Task 1: Acquisition

### 1 Objective

The acquisition process aims to identify visible satellites and determine coarse values of carrier Doppler frequency and code phase for each satellite signal. For this task, we implemented the parallel code phase search method using Fast Fourier Transform (FFT) to efficiently compute the correlation between the received signal and locally generated replicas.

### 2 Implementation

Our acquisition methodology employed a parallel frequency space search approach to efficiently identify visible satellites and determine their Doppler frequencies and code phases. After conditioning the input signal to remove DC bias, we established a search space with Doppler range of ±5 kHz (500 Hz steps) and full code phase range (1023 chips). For each PRN, we generated local C/A code replicas and transformed them to the frequency domain using FFT. The acquisition process then performed circular cross-correlation between the incoming signal and code replicas across all frequency bins by multiplying their spectral representations and applying inverse FFT. This computationally efficient approach simultaneously evaluated all possible code phases for each Doppler hypothesis. Signal detection relied on comparing the maximum correlation peak to the second highest peak, with threshold determination based on desired false alarm probability. For detected satellites, fine frequency estimation using longer integration periods provided refined Doppler estimates, accommodating the different sampling frequencies and intermediate frequencies between open-sky and urban datasets.

#### Detection Criteria

The decision threshold was set based on the desired false alarm probability (Pfa) as described in Slide 53. We used the formula $V_t=\sigma_n \sqrt{-2 \ln P_{f a}}$ to determine the appropriate threshold value, where $σ_n$ is the noise standard deviation.

#### Implementation Considerations

For practical implementation, we utilized the SoftGNSS framework which employs efficient FFT-based correlation techniques. Several important considerations were made:

- **Sampling Frequency Adjustments**: The different sampling frequencies between the open-sky (58 MHz) and urban (26 MHz) datasets required appropriate parameter adjustments.
- **Intermediate Frequency Handling**: The different IF values (4.58 MHz for open-sky, 0 MHz for urban) were accounted for in the carrier generation process.

### 3 Experiment Results and Discussions

#### Scenario 1: Opensky

The acquisition results demonstrate successful satellite signal detection in an open-sky environment. The bar chart clearly identifies five satellites (PRNs 16, 22, 26, 27, and 31) with acquisition metrics significantly exceeding the detection threshold, indicating strong signal presence. The acquisition process successfully identified the following satellites in the open-sky dataset:

| Channel | PRN  | Frequency   | Doppler | Code Offset | Status |
| ------- | ---- | ----------- | ------- | ----------- | ------ |
| 1       | 16   | 4.57976e+06 | -240    | 31994       | T      |
| 2       | 26   | 4.58192e+06 | 1917    | 57754       | T      |
| 3       | 31   | 4.58107e+06 | 1066    | 18744       | T      |
| 4       | 22   | 4.58157e+06 | 1571    | 55101       | T      |
| 5       | 27   | 4.57678e+06 | -3220   | 8814        | T      |

The acquisition metric results are visualized in the figure below:

<img src="C:\01_Study\AAE6102\img\Acquisition_metric_o.png" alt="Acquisition_metric_o"  />

<img src="C:\01_Study\AAE6102\img\skyplot_sky.png" alt="skyplot_sky" style="zoom:50%;" />

The acquisition results demonstrate successful satellite signal detection in an open-sky environment. The bar chart clearly identifies five satellites (PRNs 16, 22, 26, 27, and 31) with acquisition metrics significantly exceeding the detection threshold, indicating strong signal presence. 

#### Scenario 2: Urban

Four satellites signal are acquired. Compared to the Opensky scenario, the acquisition result of urban shows that fewer satellites are visible in this scheme, which may perform lower positioning precision in the following tasks. The results are listed as follows:

| Channel | PRN  | Frequency   | Doppler | Code Offset | Status |
| ------- | ---- | ----------- | ------- | ----------- | ------ |
| 1       | 1    | 1.20258e+03 |    1203   |      3329   |     T  |
|       2 |   3 |  4.28963e+03 |    4290   |     25173   |     T  |
|       3 |  11 |  4.09126e+02 |     409   |      1155   |     T  |
|       4 |  18 |  -3.22342e+02 |    -322   |     10581   |     T  |

![Acquisition_metric_u](C:\01_Study\AAE6102\img\Acquisition_metric_u.png)

<img src="C:\01_Study\AAE6102\img\skyplot_urban.png" alt="skyplot_urban" style="zoom:67%;" />


## Task 2: Tracking

### 1 Objective

The tracking process refines the coarse estimates obtained from the acquisition stage using feedback loops to continuously track the satellite signals. For this task, we focused on analyzing the impact of urban interference on the correlation function shape by implementing and examining multiple correlators.

### 2 Implementation

Our approach implements a multi-correlator tracking architecture to analyze GNSS signal characteristics in varying environments. The tracking system incorporates a Phase Lock Loop with Costas discriminator for carrier tracking and a non-coherent Delay Lock Loop for code tracking. We extended the standard Early-Prompt-Late correlator configuration to include nine correlators with 0.1-chip spacing covering ±0.4 chips around the prompt position. This enhanced setup enables detailed visualization of the correlation function shape, facilitating detection of multipath-induced distortions. A Delay Lock Loop (DLL) with non-coherent early-minus-late power discriminator was implemented to track the code phase. The discriminator, as described in slide 67, computes: 

$$I_E=\sum_{i=1}^N s_i \cdot c_{E, i} \cdot \cos \left(\hat{\phi}_i\right)$$
$Q_E=\sum_{i=1}^N s_i \cdot c_{E, i} \cdot \sin \left(\hat{\phi}_i\right)$
$I_P=\sum_{i=1}^N s_i \cdot c_{P, i} \cdot \cos \left(\hat{\phi}_i\right)$
$Q_P=\sum_{i=1}^N s_i \cdot c_{P, i} \cdot \sin \left(\hat{\phi}_i\right)$
$I_L=\sum_{i=1}^N s_i \cdot c_{L, i} \cdot \cos \left(\hat{\phi}_i\right)$
$Q_L=\sum_{i=1}^N s_i \cdot c_{L, i} \cdot \sin \left(\hat{\phi}_i\right)$

The DLL discriminator implements a normalized early-minus-late power formula:

$\epsilon_{\text {code }}=\frac{\sqrt{I_E^2+Q_E^2}-\sqrt{I_L^2+Q_L^2}}{\sqrt{I_E^2+Q_E^2}+\sqrt{I_L^2+Q_L^2}}$

To analyze correlation function shape and detect multipath effects, we extended the standard early-prompt-late configuration to include multiple correlators with 0.1-chip spacing:
$c_\delta(t)=c\left(t-\tau_p+\delta\right)$
where $\delta \in {-0.5, -0.4, -0.3, -0.2, -0.1, 0, 0.1, 0.2, 0.3, 0.4, 0.5}$ chips.

These multiple correlation points enable detailed visualization of the auto-correlation function (ACF), providing insight into signal quality and multipath presence.

### 3 Experiment Results and Discussions

#### Scenario 1: Opensky (Take PRN16 as an example)

**Auto-correlation Function Analysis:**

The figures below show the ACF analysis of each visible PRN. The ACF exhibits symmetric, well-defined correlation peaks across all measurement epochs, characteristic of clean line-of-sight signal reception with minimal distortion. This symmetry confirms the absence of significant multipath effects in the open-sky environment. 

![ACF_sky](C:\01_Study\AAE6102\img\ACF_sky.png)

Since the signal of PRN16 has the best performance in this observation, we select PRN16 as an example for detailed analysis. 

![tracking](C:\01_Study\AAE6102\img\tracking.png)

The tracking performance in open-sky conditions demonstrates:

1. Q-channel oscillating around zero, confirming proper carrier alignment
2. DLL discriminator output remaining near zero, indicating stable code tracking
3. PLL discriminator output maintaining minimal error, showing stable carrier phase tracking
4. Prompt correlation power significantly exceeding Early/Late powers, confirming optimal code alignment

#### Scenario 2: Urban (Take PRN16 as an example)

The urban ACF exhibits asymmetric correlation peaks with notable distortions. This asymmetry is a telltale signature of multipath effects, where reflected signals combine with the direct path signal to create correlation function deformations. These distortions lead to biased pseudorange measurements and degraded positioning accuracy.

Urban tracking results reveal several challenges:

1. Q-channel showing significant oscillations, sometimes exceeding I-channel magnitude, indicating carrier phase misalignment
2. PLL discriminator experiencing larger fluctuations, demonstrating carrier tracking instability
3. Correlation power distributions showing inconsistent patterns, with prompt power occasionally falling below early/late values

#### 3.3 The impact of urban interference on the correlation peaks:

## Task 3: Navigation Data Decoding

### 1 Objective

The tracking outputs enable navigation message extraction through bit synchronization and frame structure decoding. The I-prompt values, after appropriate filtering and bit synchronization, reveal the 50 Hz navigation data:

### 2 Implementation

The navigation data decoding process extracts the broadcast navigation message from the tracked signals. The implementation includes:

1. Bit synchronization to determine data bit boundaries
2. Frame synchronization using preamble detection
3. Subframe identification and data decoding
4. Parity checking to ensure data integrity
5. Extraction of ephemeris parameters, time of week, and other relevant data

### 3 Experiment Results and Discussions

#### Scenario 1: Opensky (Take PRN16 as an example)

The demodulated signal shows stable bit transitions with consistent amplitude, confirming excellent signal quality and reliable data recovery. Key ephemeris parameters successfully extracted from the navigation messages include:

| PRN      | 16          | 22          | 26          | 27          | 31          |
|----------|-------------|-------------|-------------|-------------|-------------|
| C_ic     | -1.01E-07   | -1.01E-07   | -2.05E-08   | 1.08E-07    | -1.14E-07   |
| omega_0  | -1.674261429| 1.272735322 | -1.812930701| -0.71747466 | -2.787272903|
| C_is     | 1.36E-07    | -9.31E-08   | 8.94E-08    | 1.15E-07    | -5.03E-08   |
| i_0      | 0.971603403 | 0.936454583 | 0.939912327 | 0.974727542 | 0.95588255  |
| C_rc     | 237.6875    | 266.34375   | 234.1875    | 230.34375   | 240.15625   |
| omega    | 0.679609497 | -0.887886686| 0.295685419 | 0.630881665 | 0.311626182 |
| omegaDot | -8.01E-09   | -8.67E-09   | -8.31E-09   | -8.02E-09   | -7.99E-09   |
| IODE_sf3 | 9           | 22          | 113         | 30          | 83          |
| iDot     | -4.89E-10   | -3.04E-11   | -4.18E-10   | -7.14E-13   | 3.21E-11    |
| idValid  | [2,0,3]     | [2,0,3]     | [2,0,3]     | [2,0,3]     | [2,0,3]     |
| weekNumber| 1155       | 1155        | 1155        | 1155        | 1155        |
| accuracy | 0           | 0           | 0           | 0           | 0           |
| health   | 0           | 0           | 0           | 0           | 0           |
| T_GD     | -1.02E-08   | -1.77E-08   | 6.98E-09    | 1.86E-09    | -1.30E-08   |
| IODC     | 234         | 218         | 15          | 4           | 228         |
| t_oc     | 396000      | 396000      | 396000      | 396000      | 396000      |
| a_f2     | 0           | 0           | 0           | 0           | 0           |
| a_f1     | -6.37E-12   | 9.21E-12    | 3.98E-12    | -5.00E-12   | -1.93E-12   |
| a_f0     | -0.000406925| -0.000489472| 0.00014479  | -0.000206121| -0.0001449  |
| IODE_sf2 | 9           | 22          | 113         | 30          | 83          |
| C_rs     | 23.34375    | -99.8125    | 21.25       | 70.4375     | 30.71875    |
| deltan   | 4.25E-09    | 5.28E-09    | 5.05E-09    | 4.03E-09    | 4.81E-09    |
| M_0      | 0.718116855 | -1.260965589| 1.735570934 | -0.173022281| 2.82452322  |
| C_uc     | 1.39E-06    | -5.16E-06   | 1.15E-06    | 3.73E-06    | 1.46E-06    |
| e        | 0.012296279 | 0.006713538 | 0.006253509 | 0.009574107 | 0.010271554 |
| C_us     | 7.69E-06    | 5.17E-06    | 7.04E-06    | 8.24E-06    | 7.23E-06    |
| sqrtA    | 5153.771322 | 5153.712273 | 5153.636459 | 5153.652021 | 5153.622389 |
| t_oe     | 396000      | 396000      | 396000      | 396000      | 396000      |
| TOW      | 390102      | 390102      | 390102      | 390102      | 390102      |

#### Scenario 2: Urban (Take PRN16 as an example)

The urban navigation data exhibits amplitude fluctuations and occasional inconsistencies, reflecting the challenging signal environment and tracking instabilities previously observed.

## Task 4: Position and Velocity Estimation

### 1 Implementation
The position solution employs a weighted least squares (WLS) approach. For each visible satellite, we formulate the linearized pseudorange equation:
$\rho_i=\sqrt{\left(x_i-x\right)^2+\left(y_i-y\right)^2+\left(z_i-z\right)^2+c \cdot d t+\varepsilon_i}$

This leads to the linearized system:
 $\Delta \rho=A \cdot \Delta x+\varepsilon$

Where $A$ is the geometry matrix containing line-of-sight unit vectors and $\Delta\rho$ represents the pseudorange residuals.

We implement elevation-based weighting:
 $w_i=\sin ^2\left(e l_i\right)$

The weighted solution is given by:
 $\Delta x=\left(A^T W A\right)^{-1} A^T W \Delta \rho$

For velocity estimation, we leverage Doppler measurements:
$\dot{\rho}_i=-\lambda \cdot f_{\text {doppler }, i}$

The velocity solution follows a similar WLS structure:
 $\Delta v=\left(A^T W A\right)^{-1} A^T W(b)$

Where $b_i = \dot{\rho}*i - \vec{v}*{sat,i} \cdot \vec{u}_i$ and $\vec{u}_i$ is the unit line-of-sight vector.

### 2 Experiment Results and Discussions

#### Scenario 1: Opensky 

Figure below shows the WLS **positioning result** of the opensky scenario, where red dots represent the estimation and yellow dot means the ground truth.

![WLS_sky](C:\01_Study\AAE6102\img\WLS_sky.png)

This figure below shows **velocity estimation** result of the opensky scenario.

#### Scenario 2: Urban

Figure below shows the WLS positioning result of the urban scenario, where red dots represent the estimation and yellow dot means the ground truth.

This figure below shows velocity estimation result of the urban scenario.


## Task 5: Kalman filter-based positioning

### 1 Objective

The tracking process refines the coarse estimates obtained from the acquisition stage using feedback loops to continuously track the satellite signals. For this task, we focused on analyzing the impact of urban interference on the correlation function shape by implementing and examining multiple correlators.

### 2 Implementation

The tracking process refines the coarse estimates from acquisition using feedback loops to continuously track the signals. A standard tracking architecture was implemented with the following components:

### 3 Experiment Results and Discussions

## Conclusion

## References