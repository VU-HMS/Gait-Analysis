function [MeasuresStruct] = GaitQualityFromTrunkAccelerations(AccData, FS, LegLength, varargin)
%% function [MeasuresStruct] = GaitQualityFromTrunkAccelerations (AccData, FS, LegLength, varargin)
%
% INPUT
% AccData:   Trunk accelerations during locomotion in VT, ML, AP directions
% FS:        Sample frequency of the AccData
% LegLength: Leg length of the subject in meters

% OUTPUT
% MeasuresStruct: Structure containing the measures calculated here as
%                 fields and subfields. 
%
% Details on these measures can be found in Rispens, van Schooten, Pijnappels, 
% Daffertshofer, Beek, and van Dieen; Identification of fall risk predictors
% in daily life measurements: gait characteristics' reliability and association 
% with self-reported fall history. NNR, 2015. 29: 54-61.

%% History
% 2015-07 (KS): Add comments and explanations
% 2018-11 (KS): Updated to work with different sample frequencies. Now
%               quite crude, plan to resample for linear measures.
% 2019    (RC): Added option to time the calculations.
% 2021-12 (RC): AccData now resampled before this function is called.
% 2022-01 (RC): Merged adapatations from RC & YGZ. Mainly, the code has been
%               split into several functions. Function specific parameters 
%               and history have been moved to the corresponding m-files in
%               the subfolder "Gait Quality Measures".
% 2022-05 (RC): Added logging.


%% Undocumented options
validVerbosityLevel= @(x) isnumeric(x) && isscalar(x) && (x >= 0) && (x<=2);
p = inputParser;
addParameter(p, 'analyzeTime', false, @islogical);
addParameter(p, 'verbosityLevel', 1, validVerbosityLevel);
parse(p,varargin{:});
if p.Results.analyzeTime
    ntot = 1000;
else
    ntot = 1;
end
verbosityLevel = p.Results.verbosityLevel;

st = dbstack;
fcnName = st.name;
if (verbosityLevel > 1)
    str = sprintf ("Enter%s().\n", fcnName);
    prLog(str, fcnName);
end


%% Set some parameters
G = 9.81;                 % gravity acceleration, multiplication factor for accelerations
MinEpochLength = 5;       % Minimum number of seconds for measures estimation
ApplyRealignment = true;


%% Init output variable
MeasuresStruct = struct();


%% Only do further processing if time series is long enough
if size(AccData,1) < floor(FS*MinEpochLength)
    str = sprintf ("Epoch length (%ds) too small.\n", floor(size(AccData,1)/FS));
    eprintf (str);
    prLog(str, fcnName);
    return;
end


%% Rescale AccData
AccData = G*AccData();


%% Realign sensor data to VT-ML-AP frame
if (verbosityLevel > 1)
    prLog("Realign sensor data.\n", fcnName);
end
t = tic;
for nn = 1 : ntot
    if ApplyRealignment
        [AccData, ~] = RealignSensorSignalHRAmp(AccData, FS);
    end
end
if (ntot > 1)
    printf('Time to realign sensor data = %.3f seconds.\n', toc(t)/ntot);
end


%% Stride times measures
if (verbosityLevel > 1)
    prLog("Calculate stride time measures.\n", fcnName);
end
t=tic;
for nn = 1 : ntot    
    [MeasuresStruct, StrideTimeSamples] = StrideTimesMeasures(MeasuresStruct, AccData, FS);
end
if (ntot > 1)
    printf('Time to calculate stride time measures = %.3f seconds.\n', toc(t)/ntot);
end



%% Measures from height variation
if (verbosityLevel > 1)
   prLog("Calculate measures from height variation.\n", fcnName);
end
t=tic;
for nn = 1 : ntot
    MeasuresStruct = StrideSpatialMeasures(MeasuresStruct, AccData, FS, ApplyRealignment, LegLength, StrideTimeSamples);
end
if (ntot > 1)
    printf('Time to calculate measures from height variations = %.3f seconds.\n', toc(t) / ntot);
end


%% Movement intensity
if (verbosityLevel > 1)
    prLog("Calculate movement intensity.\n", fcnName);
end
t = tic;
for nn = 1 : ntot
    MeasuresStruct.StandardDeviation = std(AccData,0,1);
    MeasuresStruct.StandardDeviation(1,4) = sqrt(sum(MeasuresStruct.StandardDeviation.^2));
end
if (ntot > 1)
    printf('Time to calculate movement intensity = %.3f seconds.\n', toc(t) / ntot);
end


%% Measures from power spectral densities
if (verbosityLevel > 1)
    prLog("Calculate measures from power spectral density.\n", fcnName);
end
t=tic;
for nn = 1 : ntot
    MeasuresStruct = StrideSpectralMeasures(MeasuresStruct, AccData, FS);
end
if (ntot > 1)
    printf('Time to calculate measures from power spectral density = %.3f seconds.\n', toc(t)/ntot);
end


%% Time domain measures tested by Weiss et al. 2013
if (verbosityLevel > 1)
    prLog("Calculate measures from acceleration time domain (Weiss et al.)\n", fcnName);
end
t=tic;
for nn = 1 : ntot
    MeasuresStruct = AccTimeDomainMeasures(MeasuresStruct, AccData, FS);
end
if (ntot > 1)
    printf('Time to calculate measures tested by Weiss = %.3f seconds.\n', toc(t)/ntot);
end


%% Nonlinear measures
if (verbosityLevel > 1)
    prLog("Calculate non-lineair measures.\n", fcnName);
end
t=tic;
for nn = 1 : ntot
    MeasuresStruct = NonlinearMeasures(MeasuresStruct, AccData, FS);
end
if (ntot > 1)
    printf('Time to calculate non-lineair measures = %.3f seconds.\n', toc(t)/ntot);
end

if (verbosityLevel > 1)
    str = sprintf ("Leave %s().\n", fcnName);
    prLog(str, fcnName);
end
