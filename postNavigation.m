function [navSolutions, eph] = postNavigation(trackResults, settings)
%Function calculates navigation solutions for the receiver (pseudoranges,
%positions). At the end it converts coordinates from the WGS84 system to
%the UTM, geocentric or any additional coordinate system.
%
%[navSolutions, eph] = postNavigation(trackResults, settings)
%
%   Inputs:
%       trackResults    - results from the tracking function (structure
%                       array).
%       settings        - receiver settings.
%   Outputs:
%       navSolutions    - contains measured pseudoranges, receiver
%                       clock error, receiver coordinates in several
%                       coordinate systems (at least ECEF and UTM).
%       eph             - received ephemerides of all SV (structure array).

%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
% 
% Copyright (C) Darius Plausinaitis
% Written by Darius Plausinaitis with help from Kristin Larson
%--------------------------------------------------------------------------
%This program is free software; you can redistribute it and/or
%modify it under the terms of the GNU General Public License
%as published by the Free Software Foundation; either version 2
%of the License, or (at your option) any later version.
%
%This program is distributed in the hope that it will be useful,
%but WITHOUT ANY WARRANTY; without even the implied warranty of
%MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%GNU General Public License for more details.
%
%You should have received a copy of the GNU General Public License
%along with this program; if not, write to the Free Software
%Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301,
%USA.
%--------------------------------------------------------------------------

%CVS record:
%$Id: postNavigation.m,v 1.1.2.22 2006/08/09 17:20:11 dpl Exp $

%% Check is there enough data to obtain any navigation solution ===========
% It is necessary to have at least three subframes (number 1, 2 and 3) to
% find satellite coordinates. Then receiver position can be found too.
% The function requires all 5 subframes, because the tracking starts at
% arbitrary point. Therefore the first received subframes can be any three
% from the 5.
% One subframe length is 6 seconds, therefore we need at least 30 sec long
% record (5 * 6 = 30 sec = 30000ms). We add extra seconds for the cases,
% when tracking has started in a middle of a subframe.

if (settings.msToProcess < 36000) 
    % Show the error message and exit
    disp('Record is to short. Exiting!');
    navSolutions = [];
    eph          = [];
    return
end

%% Pre-allocate space =======================================================
% Starting positions of the first message in the input bit stream 
% trackResults.I_P in each channel. The position is PRN code count
% since start of tracking. Corresponding value will be set to inf 
% if no valid preambles were detected in the channel.
subFrameStart  = inf(1, settings.numberOfChannels);

% Time Of Week (TOW) of the first message(in seconds). Corresponding value
% will be set to inf if no valid preambles were detected in the channel.
TOW  = inf(1, settings.numberOfChannels);
%% EKF P and Q matrix for initialization from RayJ
P = diag([10000,10000,10000,100,100,100,10000,100]);
Q = diag([1,1,1,100,100,100,1,100]);
%--- Make a list of channels excluding not tracking channels ---------------
activeChnList = find([trackResults.status] ~= '-');

%% Decode ephemerides =======================================================
for channelNr = activeChnList
    
    % Get PRN of current channel
    PRN = trackResults(channelNr).PRN;
    
    fprintf('Decoding NAV for PRN %02d -------------------- \n', PRN);
    %=== Decode ephemerides and TOW of the first sub-frame ==================
    [eph(PRN), subFrameStart(channelNr), TOW(channelNr)] = ...
                                  NAVdecoding(trackResults(channelNr).I_P);  %#ok<AGROW>

    %--- Exclude satellite if it does not have the necessary nav data -----
    if (isempty(eph(PRN).IODC) || isempty(eph(PRN).IODE_sf2) || ...
        isempty(eph(PRN).IODE_sf3))

        %--- Exclude channel from the list (from further processing) ------
        activeChnList = setdiff(activeChnList, channelNr);
        fprintf('    Ephemeris decoding fails for PRN %02d !\n', PRN);
    else
        fprintf('    Three requisite messages for PRN %02d all decoded!\n', PRN);
    end
end

%% Check if the number of satellites is still above 3 =====================
if (isempty(activeChnList) || (size(activeChnList, 2) < 4))
    % Show error message and exit
    disp('Too few satellites with ephemeris data for postion calculations. Exiting!');
    navSolutions = [];
    eph          = [];
    return
end

%% Set measurement-time point and step  =====================================
% Find start and end of measurement point locations in IF signal stream with available
% measurements
sampleStart = zeros(1, settings.numberOfChannels);
sampleEnd = inf(1, settings.numberOfChannels);

for channelNr = activeChnList
    sampleStart(channelNr) = ...
          trackResults(channelNr).absoluteSample(subFrameStart(channelNr));
    
    sampleEnd(channelNr) = trackResults(channelNr).absoluteSample(end);
end

% Second term is to make space to aviod index exceeds matrix dimensions, 
% thus a margin of 1 is added.
sampleStart = max(sampleStart) + 1;  
sampleEnd = min(sampleEnd) - 1;

%--- Measurement step in unit of IF samples -------------------------------
measSampleStep = fix(settings.samplingFreq * settings.navSolPeriod/1000);

%---  Number of measurment point from measurment start to end ------------- 
measNrSum = fix((sampleEnd-sampleStart)/measSampleStep);

%% Initialization =========================================================
% Set the satellite elevations array to INF to include all satellites for
% the first calculation of receiver position. There is no reference point
% to find the elevation angle as there is no receiver position estimate at
% this point.
satElev  = inf(1, settings.numberOfChannels);

% Save the active channel list. The list contains satellites that are
% tracked and have the required ephemeris data. In the next step the list
% will depend on each satellite's elevation angle, which will change over
% time.  
readyChnList = activeChnList;

% Set local time to inf for first calculation of receiver position. After
% first fix, localTime will be updated by measurement sample step.
localTime = inf;



%##########################################################################
%#   Do the satellite and receiver position calculations                  #
%##########################################################################

fprintf('Positions are being computed. Please wait... \n');
for currMeasNr = 1:measNrSum

    fprintf('Fix: Processing %02d of %02d \n', currMeasNr,measNrSum);
    %% Initialization of current measurement ==============================          
    % Exclude satellites, that are belove elevation mask 
    activeChnList = intersect(find(satElev >= settings.elevationMask), ...
                              readyChnList);

    % Save list of satellites used for position calculation
    navSolutions.PRN(activeChnList, currMeasNr) = ...
                                        [trackResults(activeChnList).PRN]; 

    % These two lines help the skyPlot function. The satellites excluded
    % do to elevation mask will not "jump" to possition (0,0) in the sky
    % plot.
    navSolutions.el(:, currMeasNr) = NaN(settings.numberOfChannels, 1);
    navSolutions.az(:, currMeasNr) = NaN(settings.numberOfChannels, 1);
                                     
    % Signal transmitting time of each channel at measurement sample location
    navSolutions.transmitTime(:, currMeasNr) = ...
                                         NaN(settings.numberOfChannels, 1);
    navSolutions.satClkCorr(:, currMeasNr) = ...
                                         NaN(settings.numberOfChannels, 1);                                                                  
       
    % Position index of current measurement time in IF signal stream
    % (in unit IF signal sample point)
    currMeasSample = sampleStart + measSampleStep*(currMeasNr-1);
    
%% Find pseudoranges revised on 03102025 by RayJ ======================================================
    % Raw pseudorange = (localTime - transmitTime) * light speed (in m)
    % All output are 1 by settings.numberOfChannels columme vecters.
    [navSolutions.rawP(:, currMeasNr),transmitTime,localTime]=  ...
                     calculatePseudoranges(trackResults,subFrameStart,TOW, ...
                     currMeasSample,localTime,activeChnList, settings);

    doppler = zeros(1, max(activeChnList));
    % 对每个活跃通道计算多普勒频�?
    for channelNr = activeChnList
        % 查找当前测量样本之前的最近索引点
        for index = 1:length(trackResults(channelNr).absoluteSample)
            if(trackResults(channelNr).absoluteSample(index) > currMeasSample)
                break
            end
        end
        
        % 使用最后一个小于当前测量样本的索引�?
        index = index - 1;
        
        % 获取该索引处的载波频�?
        carrFreq = trackResults(channelNr).carrFreq(index);
        
        % 计算多普勒频移（m/s�?
        doppler(channelNr) = (carrFreq - settings.IF) * settings.c / 1575.42e6;
    end

    % 保存计算结果到navSolutions结构�?
    navSolutions.rawD(:, currMeasNr) = doppler;

    % Save transmitTime
    navSolutions.transmitTime(activeChnList, currMeasNr) = ...
                                        transmitTime(activeChnList);

%% Find satellites positions and clocks corrections =======================
    % Outputs are all colume vectors corresponding to activeChnList
    [satPositions, satClkCorr,satVelocity] = satpos(transmitTime(activeChnList), ...
                                 [trackResults(activeChnList).PRN], eph); 
                                    
     
    % Save satClkCorr
    navSolutions.satClkCorr(activeChnList, currMeasNr) = satClkCorr;

%% Find receiver position =================================================
    % 3D receiver position can be found only if signals from more than 3
    % satellites are available  
    if size(activeChnList, 2) > 3

        %=== Calculate receiver position ==================================
        % Correct pseudorange for SV clock error
        clkCorrRawP = navSolutions.rawP(activeChnList, currMeasNr)' + ...
                                                   satClkCorr * settings.c;
        
        
        clkCorrRawD = navSolutions.rawD(activeChnList, currMeasNr)';
        % Calculate receiver position
        % [xyzdt,navSolutions.el(activeChnList, currMeasNr), ...
        %        navSolutions.az(activeChnList, currMeasNr), ...
        %        navSolutions.DOP(:, currMeasNr)] =...
        %                leastSquarePos(satPositions, clkCorrRawP, settings,satVelocity,clkCorrRawD);
        [xyzdt,navSolutions.el(activeChnList, currMeasNr), ...
               navSolutions.az(activeChnList, currMeasNr), ...
               navSolutions.DOP(:, currMeasNr)] =...
                       leastSquarePos(satPositions, clkCorrRawP, settings);

        %=== Save results ===========================================================
        % Receiver position in ECEF
        navSolutions.X(currMeasNr)  = xyzdt(1);
        navSolutions.Y(currMeasNr)  = xyzdt(2);
        navSolutions.Z(currMeasNr)  = xyzdt(3);       
        

                %=== Calculate receiver velocity using WLS =================================
        % Initialize parameters for WLS velocity calculation
        numSatellites = size(activeChnList, 2);
        A = zeros(numSatellites, 4);  % Design matrix for velocity
        b = zeros(numSatellites, 1);  % Observation vector

        % Form the geometry matrix and observation vector
        for i = 1:numSatellites
            % Unit vector from receiver to satellite
            dx = satPositions(1, i) - xyzdt(1);
            dy = satPositions(2, i) - xyzdt(2);
            dz = satPositions(3, i) - xyzdt(3);
            range = sqrt(dx^2 + dy^2 + dz^2);

            % Line-of-sight unit vector components
            A(i, 1) = dx / range;
            A(i, 2) = dy / range;
            A(i, 3) = dz / range;
            A(i, 4) = 1; % Clock drift term

            % Observation: Doppler measurement adjusted by satellite velocity projection
            % Convert Doppler to range rate (negative sign because positive Doppler = decreasing range)
            rangeRate = -clkCorrRawD(i);

            % Remove satellite velocity component along line-of-sight
            % satRangeRateComponent = (satVelocity(1,i)*dx + satVelocity(2,i)*dy + satVelocity(3,i)*dz) / range;
            svVel = satVelocity(:,i);
            satRangeRateComponent = dot([dx dy dz], svVel)/range;

            % Observation is measured range rate minus satellite contribution
            b(i) = rangeRate - satRangeRateComponent;
        end

        % Apply elevation-dependent weighting
        weights = sin(navSolutions.el(activeChnList, currMeasNr) * pi/180).^2;
        W = diag(weights);

        % Weighted least squares solution for velocity
        vel_solution = inv(A' * W * A) * A' * W * b;

        % Save velocity components
        navSolutions.vX(currMeasNr) = vel_solution(1);
        navSolutions.vY(currMeasNr) = vel_solution(2);
        navSolutions.vZ(currMeasNr) = vel_solution(3);
        navSolutions.driftRate(currMeasNr) = vel_solution(4); % Clock drift rate

        navSolutions.satllitePosition{currMeasNr} = satPositions; 
        navSolutions.satelliteVelocity{currMeasNr} = satVelocity; % Store satellite velocities

        %% static SPP with Extended Kalman Filter --sbs
        if currMeasNr == 1
            X = [xyzdt(1:3),0,0,0,xyzdt(4),0]';
        else
            X(7)=0;  % rcv clk bias has been corrected after 1st epoch, so it should be 0 --sbs
        end
        [X_k, P_k]= ExtendedKF(satPositions,satVelocity,clkCorrRawP,clkCorrRawD,settings,X,P,Q);

        % save the ekf result --sbs
        navSolutions.X_kf(currMeasNr)  = X_k(1);
        navSolutions.Y_kf(currMeasNr)  = X_k(2);
        navSolutions.Z_kf(currMeasNr)  = X_k(3);     
        navSolutions.VX_kf(currMeasNr)  = X_k(4);
        navSolutions.VY_kf(currMeasNr)  = X_k(5);
        navSolutions.VZ_kf(currMeasNr)  = X_k(6);   
        X = X_k;
        P = P_k;


		% For first calculation of solution, clock error will be set 
        % to be zero
        if (currMeasNr == 1)
        navSolutions.dt(currMeasNr) = 0;  % in unit of (m)
        else
            navSolutions.dt(currMeasNr) = xyzdt(4);  
        end
                
		%=== Correct local time by clock error estimation =================
        localTime = localTime - xyzdt(4)/settings.c;       
        navSolutions.localTime(currMeasNr) = localTime;
        
        % Save current measurement sample location 
        navSolutions.currMeasSample(currMeasNr) = currMeasSample;

        % Update the satellites elevations vector
        satElev = navSolutions.el(:, currMeasNr)';

        %=== Correct pseudorange measurements for clocks errors ===========
        navSolutions.correctedP(activeChnList, currMeasNr) = ...
                navSolutions.rawP(activeChnList, currMeasNr) + ...
                satClkCorr' * settings.c - xyzdt(4);
            
%% Coordinate conversion ==================================================

        %=== Convert to geodetic coordinates ==============================
        [navSolutions.latitude(currMeasNr), ...
         navSolutions.longitude(currMeasNr), ...
         navSolutions.height(currMeasNr)] = cart2geo(...
                                            navSolutions.X(currMeasNr), ...
                                            navSolutions.Y(currMeasNr), ...
                                            navSolutions.Z(currMeasNr), ...
                                            5);
        
        %=== Convert to UTM coordinate system =============================
        navSolutions.utmZone = findUtmZone(navSolutions.latitude(currMeasNr), ...
                                       navSolutions.longitude(currMeasNr));
        
        % Position in ENU
        [navSolutions.E(currMeasNr), ...
         navSolutions.N(currMeasNr), ...
         navSolutions.U(currMeasNr)] = cart2utm(xyzdt(1), xyzdt(2), ...
                                                xyzdt(3), ...
                                                navSolutions.utmZone);

                                                logStart = 0;
                                                if currMeasNr>logStart
                                                    %=== Convert to geodetic coordinates ==============================
                                                    [navSolutions.latitude_kf(currMeasNr-logStart), ...
                                                        navSolutions.longitude_kf(currMeasNr-logStart), ...
                                                        navSolutions.height_kf(currMeasNr-logStart)] = cart2geo(...
                                                        navSolutions.X_kf(currMeasNr-logStart), ...
                                                        navSolutions.Y_kf(currMeasNr-logStart), ...
                                                        navSolutions.Z_kf(currMeasNr-logStart), ...
                                                        5);
                                        
                                                    %=== Convert to UTM coordinate system =============================
                                                    % navSolutions.utmZone_kf = findUtmZone(navSolutions.latitude_kf(currMeasNr-logStart), ...
                                                    %                                navSolutions.longitude_kf(currMeasNr-logStart));
                                                    %
                                                    % Position in ENU
                                                    [navSolutions.E_kf(currMeasNr-logStart), ...
                                                        navSolutions.N_kf(currMeasNr-logStart), ...
                                                        navSolutions.U_kf(currMeasNr-logStart)] = cart2utm(X(1), X(2), ...
                                                        X(3), ...
                                                        navSolutions.utmZone);
                                        
                                                end 
                                                
    else
        %--- There are not enough satellites to find 3D position ----------
        disp(['   Measurement No. ', num2str(currMeasNr), ...
                       ': Not enough information for position solution.']);

        %--- Set the missing solutions to NaN. These results will be
        %excluded automatically in all plots. For DOP it is easier to use
        %zeros. NaN values might need to be excluded from results in some
        %of further processing to obtain correct results.
        navSolutions.X(currMeasNr)           = NaN;
        navSolutions.Y(currMeasNr)           = NaN;
        navSolutions.Z(currMeasNr)           = NaN;
        navSolutions.dt(currMeasNr)          = NaN;
        navSolutions.DOP(:, currMeasNr)      = zeros(5, 1);
        navSolutions.latitude(currMeasNr)    = NaN;
        navSolutions.longitude(currMeasNr)   = NaN;
        navSolutions.height(currMeasNr)      = NaN;
        navSolutions.E(currMeasNr)           = NaN;
        navSolutions.N(currMeasNr)           = NaN;
        navSolutions.U(currMeasNr)           = NaN;

        navSolutions.az(activeChnList, currMeasNr) = ...
                                             NaN(1, length(activeChnList));
        navSolutions.el(activeChnList, currMeasNr) = ...
                                             NaN(1, length(activeChnList));

        % TODO: Know issue. Satellite positions are not updated if the
        % satellites are excluded do to elevation mask. Therefore rasing
        % satellites will be not included even if they will be above
        % elevation mask at some point. This would be a good place to
        % update positions of the excluded satellites.

    end % if size(activeChnList, 2) > 3

    %=== Update local time by measurement  step  ====================================
    localTime = localTime + measSampleStep/settings.samplingFreq ;

end %for currMeasNr...
