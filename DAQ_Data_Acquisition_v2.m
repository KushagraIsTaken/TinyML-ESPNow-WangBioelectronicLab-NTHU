cfunction EMG_DatasetCollection()
% EMG_DatasetCollection - Complete EMG gesture recognition dataset collection
% This script collects EMG data using NI DAQ USB-6001 and AD8232 sensor
% with real-time filtering, visualization, and feature extraction

%% Configuration Parameters
config = struct();
config.deviceID = 'Dev1';           % NI DAQ device ID
config.channelID = 'ai0';           % Analog input channel
config.sampleRate = 1000;           % Hz - sampling frequency
config.gestureNames = {'Rest', 'Fist', 'Open Hand', 'Pinch', 'Wave'};
config.numRepetitions = 5;          % Repetitions per gesture
config.gestureDuration = 3;         % seconds per gesture
config.restDuration = 2;            % seconds rest between gestures
config.windowSize = 0.2;            % seconds - feature extraction window
config.windowOverlap = 0.1;         % seconds - overlap between windows

% Filter parameters
config.highpassCutoff = 20;         % Hz - remove baseline wander
config.notchFreq = 60;              % Hz - power line interference (50 or 60)
config.notchBandwidth = 2;          % Hz - notch filter bandwidth
config.envelopeCutoff = 5;          % Hz - envelope extraction

fprintf('=== EMG Gesture Recognition Dataset Collection ===\n');
fprintf('Configuration loaded. Press any key to continue...\n');
pause;

%% Initialize DAQ Session
try
    dq = daq("ni");
    ch = addinput(dq, config.deviceID, config.channelID, "Voltage");
    ch.Range = [-10, 10];  % Voltage range for USB-6001
    dq.Rate = config.sampleRate;
    fprintf('✓ DAQ initialized successfully\n');
catch ME
    error('Failed to initialize DAQ: %s', ME.message);
end

%% Design Filters
fprintf('Designing filters...\n');
filters = designFilters(config);
fprintf('✓ Filters designed\n');

%% Prepare Data Storage
allFeatures = [];
allLabels = [];
acquisitionInfo = struct();
acquisitionInfo.config = config;
acquisitionInfo.timestamp = datetime('now');
acquisitionInfo.filterInfo = filters.info;

%% Main Data Collection Loop
fprintf('\n=== Starting Data Collection ===\n');
fprintf('Total gestures: %d, Repetitions each: %d\n', ...
    length(config.gestureNames), config.numRepetitions);

gestureCount = 0;
totalGestures = length(config.gestureNames) * config.numRepetitions;

for gestureIdx = 1:length(config.gestureNames)
    gestureName = config.gestureNames{gestureIdx};
    
    for rep = 1:config.numRepetitions
        gestureCount = gestureCount + 1;
        
        fprintf('\n--- Gesture %d/%d: %s (Rep %d) ---\n', ...
            gestureCount, totalGestures, gestureName, rep);
        
        % Rest period with countdown
        fprintf('Rest period... ');
        for i = config.restDuration:-1:1
            fprintf('%d ', i);
            pause(1);
        end
        fprintf('\n');
        
        % Gesture acquisition
        fprintf('Perform gesture: %s\n', gestureName);
        [rawData, features, labels] = acquireGesture(dq, config, filters, ...
            gestureName, gestureIdx);
        
        % Store data
        allFeatures = [allFeatures; features];
        allLabels = [allLabels; labels];
        
        fprintf('✓ Collected %d feature windows\n', size(features, 1));
    end
end

%% Save Dataset
timestamp = datestr(now, 'yyyymmdd_HHMMSS');
filename = sprintf('EMG_Dataset_%s.mat', timestamp);

% Prepare final dataset structure
dataset = struct();
dataset.X = allFeatures;                    % Feature matrix (N x features)
dataset.Y = allLabels;                      % Labels (N x 1)
dataset.gestureNames = config.gestureNames; % Gesture name mapping
dataset.featureNames = {'MAV', 'RMS'};     % Feature names
dataset.acquisitionInfo = acquisitionInfo;  % All metadata

save(filename, 'dataset');
fprintf('\n✓ Dataset saved as: %s\n', filename);
fprintf('Total samples collected: %d\n', length(allLabels));
fprintf('Features per sample: %d\n', size(allFeatures, 2));

% Display dataset summary
displayDatasetSummary(dataset);

% Cleanup
clear dq;
fprintf('\n=== Data Collection Complete ===\n');

end

%% Supporting Functions

function filters = designFilters(config)
% Design all required filters for EMG processing

filters = struct();
fs = config.sampleRate;

% High-pass filter (20-30 Hz) - Remove baseline wander and motion artifacts
[b_hp, a_hp] = butter(4, config.highpassCutoff/(fs/2), 'high');
filters.highpass.b = b_hp;
filters.highpass.a = a_hp;

% Notch filter (60 Hz) - Remove power line interference
wo = config.notchFreq/(fs/2);  % Normalized frequency
bw = config.notchBandwidth/(fs/2);  % Normalized bandwidth
[b_notch, a_notch] = iirnotch(wo, bw);
filters.notch.b = b_notch;
filters.notch.a = a_notch;

% Low-pass filter for envelope extraction
[b_lp, a_lp] = butter(4, config.envelopeCutoff/(fs/2), 'low');
filters.envelope.b = b_lp;
filters.envelope.a = a_lp;

% Store filter information
filters.info.highpassCutoff = config.highpassCutoff;
filters.info.notchFreq = config.notchFreq;
filters.info.envelopeCutoff = config.envelopeCutoff;
filters.info.sampleRate = fs;

end

function [rawData, features, labels] = acquireGesture(dq, config, filters, gestureName, gestureIdx)
% Acquire EMG data for a single gesture with real-time processing and visualization

% Calculate acquisition parameters
totalSamples = config.gestureDuration * config.sampleRate;
windowSamples = round(config.windowSize * config.sampleRate);
overlapSamples = round(config.windowOverlap * config.sampleRate);
stepSamples = windowSamples - overlapSamples;

% Prepare real-time plotting
figure('Name', sprintf('Real-time EMG - %s', gestureName), 'Position', [100, 100, 1000, 600]);

% Create subplots
subplot(2,1,1);
h_raw = plot(nan, nan, 'b-', 'LineWidth', 1);
hold on;
h_filtered = plot(nan, nan, 'r-', 'LineWidth', 1);
title('Raw EMG (Blue) and Band-pass + Notch Filtered (Red)');
ylabel('Amplitude (V)');
legend('Raw EMG', 'Filtered EMG', 'Location', 'northeast');
grid on;
ylim([-0.005, 0.005]); % Adjust based on expected EMG amplitude

subplot(2,1,2);
h_envelope = plot(nan, nan, 'g-', 'LineWidth', 2);
title('Rectified and Envelope (Green)');
xlabel('Time (s)');
ylabel('Amplitude (V)');
grid on;
ylim([0, 0.002]); % Adjust based on expected envelope amplitude

% Initialize data buffers
displayBufferSize = round(1.5 * config.sampleRate); % 1.5 seconds display window
rawBuffer = zeros(displayBufferSize, 1);
filteredBuffer = zeros(displayBufferSize, 1);
envelopeBuffer = zeros(displayBufferSize, 1);
timeBuffer = (0:displayBufferSize-1) / config.sampleRate;

% Initialize filter states
z_hp = [];
z_notch = [];
z_env = [];

% Data storage
allRawData = zeros(totalSamples, 1);
sampleIdx = 1;

% Start acquisition
fprintf('Recording... ');
tic;
dq.ScansAvailableFcnCount = round(config.sampleRate/20); % Update 20 times per second
dq.ScansAvailableFcn = [];

% Continuous acquisition
start(dq, "continuous");

while sampleIdx <= totalSamples
    if dq.NumScansAvailable > 0
        % Read available data
        [newData, ~] = read(dq, dq.NumScansAvailable, "OutputFormat", "Matrix");
        
        for i = 1:size(newData, 1)
            if sampleIdx > totalSamples
                break;
            end
            
            currentSample = newData(i, 1);
            allRawData(sampleIdx) = currentSample;
            
            % Apply filters in real-time
            [filteredSample, z_hp] = filter(filters.highpass.b, filters.highpass.a, currentSample, z_hp);
            [filteredSample, z_notch] = filter(filters.notch.b, filters.notch.a, filteredSample, z_notch);
            
            % Rectification
            rectifiedSample = abs(filteredSample);
            
            % Envelope extraction
            [envelopeSample, z_env] = filter(filters.envelope.b, filters.envelope.a, rectifiedSample, z_env);
            
            % Update display buffers (circular buffer)
            rawBuffer = [rawBuffer(2:end); currentSample];
            filteredBuffer = [filteredBuffer(2:end); filteredSample];
            envelopeBuffer = [envelopeBuffer(2:end); envelopeSample];
            
            % Update plots every 50 samples (reduce computational load)
            if mod(sampleIdx, 50) == 0
                set(h_raw, 'XData', timeBuffer, 'YData', rawBuffer);
                set(h_filtered, 'XData', timeBuffer, 'YData', filteredBuffer);
                set(h_envelope, 'XData', timeBuffer, 'YData', envelopeBuffer);
                drawnow limitrate;
            end
            
            sampleIdx = sampleIdx + 1;
        end
    else
        pause(0.001); % Small pause to prevent busy waiting
    end
    
    % Progress indicator
    if mod(sampleIdx, config.sampleRate) == 0
        fprintf('%.1fs ', toc);
    end
end

stop(dq);
fprintf('Done!\n');
close(gcf);

rawData = allRawData;

% Post-process the entire signal for feature extraction
processedSignal = processEMGSignal(rawData, filters);

% Extract features using sliding window
[features, labels] = extractFeatures(processedSignal, windowSamples, stepSamples, gestureIdx);

end

function processedSignal = processEMGSignal(rawSignal, filters)
% Apply all filters to the entire signal for feature extraction

% High-pass filter
filtered = filtfilt(filters.highpass.b, filters.highpass.a, rawSignal);

% Notch filter
filtered = filtfilt(filters.notch.b, filters.notch.a, filtered);

% Rectification
rectified = abs(filtered);

% Envelope extraction (low-pass filter)
envelope = filtfilt(filters.envelope.b, filters.envelope.a, rectified);

processedSignal = struct();
processedSignal.raw = rawSignal;
processedSignal.filtered = filtered;
processedSignal.rectified = rectified;
processedSignal.envelope = envelope;

end

function [features, labels] = extractFeatures(processedSignal, windowSamples, stepSamples, gestureLabel)
% Extract features from overlapping windows

envelope = processedSignal.envelope;
rectified = processedSignal.rectified;

% Calculate number of windows
numWindows = floor((length(envelope) - windowSamples) / stepSamples) + 1;

% Initialize feature matrix
features = zeros(numWindows, 2); % MAV and RMS
labels = gestureLabel * ones(numWindows, 1);

for i = 1:numWindows
    startIdx = (i-1) * stepSamples + 1;
    endIdx = startIdx + windowSamples - 1;
    
    windowData = rectified(startIdx:endIdx);
    
    % Mean Absolute Value (MAV)
    features(i, 1) = mean(abs(windowData));
    
    % Root Mean Square (RMS)
    features(i, 2) = sqrt(mean(windowData.^2));
end

end

function displayDatasetSummary(dataset)
% Display summary statistics of the collected dataset

fprintf('\n=== Dataset Summary ===\n');
fprintf('Total samples: %d\n', size(dataset.X, 1));
fprintf('Features per sample: %d (%s)\n', size(dataset.X, 2), ...
    strjoin(dataset.featureNames, ', '));

fprintf('\nSamples per gesture:\n');
for i = 1:length(dataset.gestureNames)
    count = sum(dataset.Y == i);
    fprintf('  %s: %d samples\n', dataset.gestureNames{i}, count);
end

fprintf('\nFeature statistics:\n');
for i = 1:length(dataset.featureNames)
    fprintf('  %s - Mean: %.6f, Std: %.6f\n', dataset.featureNames{i}, ...
        mean(dataset.X(:, i)), std(dataset.X(:, i)));
end

end