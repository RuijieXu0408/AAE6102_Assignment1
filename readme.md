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

#### 2.1 Detection Criteria

The decision threshold was set based on the desired false alarm probability (Pfa) as described in Slide 53. We used the formula $V_t=\sigma_n \sqrt{-2 \ln P_{f a}}$ to determine the appropriate threshold value, where $σ_n$ is the noise standard deviation.

#### 2.2 Implementation Considerations

For practical implementation, we utilized the SoftGNSS framework which employs efficient FFT-based correlation techniques. Several important considerations were made:

- **Sampling Frequency Adjustments**: The different sampling frequencies between the open-sky (58 MHz) and urban (26 MHz) datasets required appropriate parameter adjustments.
- **Intermediate Frequency Handling**: The different IF values (4.58 MHz for open-sky, 0 MHz for urban) were accounted for in the carrier generation process.

### 3 Experiment Results and Discussions

#### 3.1 Scenario 1: Opensky

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

The acquisition results demonstrate successful satellite signal detection in an open-sky environment. The bar chart clearly identifies five satellites (PRNs 16, 22, 26, 27, and 31) with acquisition metrics significantly exceeding the detection threshold, indicating strong signal presence. 

#### 3.2 Scenario 2: Urban




## Task 2: Tracking

### 1 Objective

The tracking process refines the coarse estimates obtained from the acquisition stage using feedback loops to continuously track the satellite signals. For this task, we focused on analyzing the impact of urban interference on the correlation function shape by implementing and examining multiple correlators.

### 2 Implementation

Our approach implements a multi-correlator tracking architecture to analyze GNSS signal characteristics in varying environments. The tracking system incorporates a Phase Lock Loop with Costas discriminator for carrier tracking and a non-coherent Delay Lock Loop for code tracking. We extended the standard Early-Prompt-Late correlator configuration to include nine correlators with 0.1-chip spacing covering ±0.4 chips around the prompt position. This enhanced setup enables detailed visualization of the correlation function shape, facilitating detection of multipath-induced distortions. A Delay Lock Loop (DLL) with non-coherent early-minus-late power discriminator was implemented to track the code phase. The discriminator, as described in slide 67, computes: 

$$I_E=\sum_{i=1}^N s_i \cdot c_{E, i} \cdot \cos \left(\hat{\phi}_i\right)$$

$Q_E=\sum_{i=1}^N s_i \cdot c_{E, i} \cdot \sin \left(\hat{\phi}_i\right)$
$ I_P=\sum_{i=1}^N s_i \cdot c_{P, i} \cdot \cos \left(\hat{\phi}_i\right) $
$ Q_P=\sum_{i=1}^N s_i \cdot c_{P, i} \cdot \sin \left(\hat{\phi}_i\right) $
$ I_L=\sum_{i=1}^N s_i \cdot c_{L, i} \cdot \cos \left(\hat{\phi}_i\right) $
$ Q_L=\sum_{i=1}^N s_i \cdot c_{L, i} \cdot \sin \left(\hat{\phi}_i\right) $

The DLL discriminator implements a normalized early-minus-late power formula:

$\epsilon_{\text {code }}=\frac{\sqrt{I_E^2+Q_E^2}-\sqrt{I_L^2+Q_L^2}}{\sqrt{I_E^2+Q_E^2}+\sqrt{I_L^2+Q_L^2}}$

By comparing normalized correlation functions across different epochs and environments, we can identify signal quality variations and multipath effects, particularly evident in urban settings where correlation peaks exhibit reduced magnitude and altered symmetry compared to open-sky scenarios.

### 3 Experiment Results and Discussions

#### 3.1 Scenario 1: Opensky

#### 3.2 Scenario 2: Urban

#### 3.3 The impact of urban interference on the correlation peaks:

## Task 3: Navigation Data Decoding

### 1 Objective

The tracking process refines the coarse estimates obtained from the acquisition stage using feedback loops to continuously track the satellite signals. For this task, we focused on analyzing the impact of urban interference on the correlation function shape by implementing and examining multiple correlators.

### 2 Implementation

The tracking process refines the coarse estimates from acquisition using feedback loops to continuously track the signals. A standard tracking architecture was implemented with the following components:

### 3 Experiment Results and Discussions

## Task 4: Position and Velocity Estimation

### 1 Objective

The tracking process refines the coarse estimates obtained from the acquisition stage using feedback loops to continuously track the satellite signals. For this task, we focused on analyzing the impact of urban interference on the correlation function shape by implementing and examining multiple correlators.

### 2 Implementation

The tracking process refines the coarse estimates from acquisition using feedback loops to continuously track the signals. A standard tracking architecture was implemented with the following components:

### 3 Experiment Results and Discussions

## Task 5: Kalman filter-based positioning

### 1 Objective

The tracking process refines the coarse estimates obtained from the acquisition stage using feedback loops to continuously track the satellite signals. For this task, we focused on analyzing the impact of urban interference on the correlation function shape by implementing and examining multiple correlators.

### 2 Implementation

The tracking process refines the coarse estimates from acquisition using feedback loops to continuously track the signals. A standard tracking architecture was implemented with the following components:

### 3 Experiment Results and Discussions

## Conclusion

## References