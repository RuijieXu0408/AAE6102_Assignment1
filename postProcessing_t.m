% Script postProcessing.m processes the raw signal from the specified data
% file (in settings) operating on blocks of 37 seconds of data.
%
% First it runs acquisition code identifying the satellites in the file,
% then the code and carrier for each of the satellites are tracked, storing
% the 1msec accumulations.  After processing all satellites in the 37 sec
% data block, then postNavigation is called. It calculates pseudoranges
% and attempts a position solutions. At the end plots are made for that
% block of data.

%--------------------------------------------------------------------------
%                           SoftGNSS v3.0
% 
% Copyright (C) Darius Plausinaitis
% Written by Darius Plausinaitis, Dennis M. Akos
% Some ideas by Dennis M. Akos
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

%                         THE SCRIPT "RECIPE"
%
% The purpose of this script is to combine all parts of the software
% receiver.
%
% 1.1) Open the data file for the processing and seek to desired point.
%
% 2.1) Acquire satellites
%
% 3.1) Initialize channels (preRun.m).
% 3.2) Pass the channel structure and the file identifier to the tracking
% function. It will read and process the data. The tracking results are
% stored in the trackResults structure. The results can be accessed this
% way (the results are stored each millisecond):
% trackResults(channelNumber).XXX(fromMillisecond : toMillisecond), where
% XXX is a field name of the result (e.g. I_P, codePhase etc.)
%
% 4) Pass tracking results to the navigation solution function. It will
% decode navigation messages, find satellite positions, measure
% pseudoranges and find receiver position.
%
% 5) Plot the results.

%% Initialization =========================================================
addpath include
addpath common
disp ('Starting processing...');

settings = initSettings();
[fid, message] = fopen(settings.fileName, 'rb');
probeData(settings);
%Initialize the multiplier to adjust for the data type
if (settings.fileType==1) 
    dataAdaptCoeff=1;
else
    dataAdaptCoeff=2;
end

%If success, then process the data
if (fid > 0)
    
    % Move the starting point of processing. Can be used to start the
    % signal processing at any point in the data record (e.g. good for long
    % records or for signal processing in blocks).
    fseek(fid, dataAdaptCoeff*settings.skipNumberOfBytes, 'bof'); 

%% Acquisition ============================================================

    % Do acquisition if it is not disabled in settings or if the variable
    % acqResults does not exist.
    if ((settings.skipAcquisition == 0) || ~exist('acqResults', 'var'))
        
        % Find number of samples per spreading code
        samplesPerCode = round(settings.samplingFreq / ...
                           (settings.codeFreqBasis / settings.codeLength));
        
        % Read data for acquisition. 11ms of signal are needed for the fine
        % frequency estimation
        
        data  = fread(fid, dataAdaptCoeff*11*samplesPerCode, settings.dataType)';
    
        if (dataAdaptCoeff==2)    
            data1=data(1:2:end);    
            data2=data(2:2:end);    
            data=data1 + 1i .* data2;    
        end

        %--- Do the acquisition -------------------------------------------
        disp ('   Acquiring satellites...');
        acqResults = acquisition(data, settings);

        plotAcquisition(acqResults);
    end

%% Initialize channels and prepare for the run ============================

    % Start further processing only if a GNSS signal was acquired (the
    % field FREQUENCY will be set to 0 for all not acquired signals)
    if (any(acqResults.carrFreq))
        channel = preRun(acqResults, settings);
        showChannelStatus(channel, settings);
    else
        % No satellites to track, exit
        disp('No GNSS signals detected, signal processing finished.');
        trackResults = [];
        return;
    end

%% Track the signal =======================================================
if ~exist(['trackingResults','.mat'])
    startTime = now;
    disp (['   Tracking started at ', datestr(startTime)]);
    
    % Process all channels for given data block
    [trackResults, channel] = tracking(fid, channel, settings);
    
    % Close the data file
    fclose(fid);
    
    disp(['   Tracking is over (elapsed time ', ...
        datestr(now - startTime, 13), ')'])
    
    % Auto save the acquisition & tracking results to a file to allow
    % running the positioning solution afterwards.
%     disp('   Saving Acq & Tracking results to file "trackingResults.mat"')
%     save('trackingResults', ...
%         'trackResults', 'settings', 'acqResults', 'channel');
    
else
    load('trackingResults.mat');
end
%% Calculate navigation solutions =========================================
    disp('   Calculating navigation solutions...');

    [navSolutions, eph] = postNavigation(trackResults, settings);

    disp('   Processing is complete for this data block');

%% Plot all results =======================================================
    disp ('   Ploting results...');
    if settings.plotTracking
        plotTracking(1:settings.numberOfChannels, trackResults, settings);
    end

    plotNavigation(navSolutions, settings);
    
    % Plot ACF (Auto-Correlation Function) for satellites
    if settings.multicorr==1
        disp ('   Plotting auto-correlation functions...');
        % Get PRNs of tracked satellites with valid data
        validChannels = find([trackResults.status] ~= '-');
        allPRNs = [trackResults(validChannels).PRN];
        
        % Select top 4 satellites with strongest signal (using I_P as indicator)
        signalStrength = zeros(1, length(validChannels));
        for i = 1:length(validChannels)
            signalStrength(i) = mean(abs(trackResults(validChannels(i)).I_P));
        end
        [~, sortIdx] = sort(signalStrength, 'descend');
        topPRNs = allPRNs(sortIdx(1:min(4, length(sortIdx))));
        
        % Plot ACF for top satellites
        plotMultipleSatelliteACF(trackResults, topPRNs, 9);
        
        % Save the figure
        saveas(gcf, 'ACF_plot.png');
        disp('   ACF plot saved as "ACF_plot.png"');
    end

    disp('Post processing of the signal is over.');

else
    % Error while opening the data file.
    error('Unable to read file %s: %s.', settings.fileName, message);
end % if (fid > 0)

% Function to plot ACF for multiple satellites
function plotMultipleSatelliteACF(trackResults, PRNs, epochs)
    numPRNs = length(PRNs);
    figure('Position', [100, 100, 1200, 800]);
    
    for i = 1:numPRNs
        subplot(2, 2, i);
        plotSingleSatelliteACF(trackResults, PRNs(i), epochs);
        title(['PRN ' num2str(PRNs(i))]);
    end
    
    sgtitle('Auto-correlation Functions at Different Epochs');
end

% Function to plot ACF for a single satellite
function plotSingleSatelliteACF(trackResults, PRN, epochs)
    % Get channel index for the PRN
    channelIndex = find([trackResults.PRN] == PRN);
    
    if isempty(channelIndex)
        text(0.5, 0.5, ['PRN ' num2str(PRN) ' not found'], 'HorizontalAlignment', 'center');
        return;
    end
    
    % Check if multi-correlator data exists
    if ~isfield(trackResults, 'I_multi') || isempty(trackResults(channelIndex).I_multi)
        text(0.5, 0.5, 'No multi-correlator data available', 'HorizontalAlignment', 'center');
        return;
    end
    
    % Select epochs to plot (evenly spaced)
    totalEpochs = length(trackResults(channelIndex).I_multi);
    if totalEpochs < epochs
        selectedEpochs = 1:totalEpochs;
    else
        selectedEpochs = round(linspace(1, totalEpochs, epochs));
    end
    
    % Define correlator offsets (chips)
    % Assuming the order in I_multi is [E, E04, E03, E02, E01, P, L01, L02, L03, L04, L]
    correlatorOffsets = [-0.5, -0.4, -0.3, -0.2, -0.1, 0, 0.1, 0.2, 0.3, 0.4, 0.5];
    
    % Create colors for different epochs
    colors = jet(length(selectedEpochs));
    
    hold on;
    
    % Plot ACF for each selected epoch
    for i = 1:length(selectedEpochs)
        epoch = selectedEpochs(i);
        
        % Get I and Q values for this epoch
        if epoch <= length(trackResults(channelIndex).I_multi)
            I_values = trackResults(channelIndex).I_multi{epoch};
            Q_values = trackResults(channelIndex).Q_multi{epoch};
            
            % Calculate correlation magnitude
            magnitudes = sqrt(I_values.^2 + Q_values.^2);
            
            % Normalize to prompt correlator
            promptIndex = 6; % Index of prompt correlator in the array
            normalizedMagnitudes = magnitudes / magnitudes(promptIndex);
            
            % Plot the ACF for this epoch
            plot(correlatorOffsets, normalizedMagnitudes, '--o', 'Color', colors(i,:), ...
                 'LineWidth', 1.5, 'DisplayName', ['Epoch ' num2str(epoch)]);
        end
    end
    
    xlabel('Code Offset (chips)');
    ylabel('Normalized Correlation');
    grid on;
    legend('Location', 'best');
    xlim([-0.6, 0.6]);
    ylim([0, 1.2]);
    hold off;
end