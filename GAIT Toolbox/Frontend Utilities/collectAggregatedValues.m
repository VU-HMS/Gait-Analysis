function [aggregateInfo, aggMeasureNames, bimodalFitWalkingSpeed, percentilePWS, nEpochsUsed] = collectAggregatedValues(locomotionMeasures, params, verbosityLevel, app)
%% function [aggregateInfo, aggMeasureNames, bimodalFitWalkingSpeed, percentilePWS, nEpochsUsed] = collectAggregatedValues(locomotionMeasures, params, verbosityLevel)

%% 2021, kaass@fbw.vu.nl 
% Last updated: Dec 2021, kaass@fbw.vu.nl

%% define some variables needed to calculate and store aggregated measures
aggMeasureNames=[];
bimodalFitWalkingSpeed=[];
percentilePWS=[];
nEpochsUsed=[];

aggregateFunction = @nanpercentiles_atleastNepisodes;

%% process input arguments
if (nargin < 3) 
    verbosity_level = 1;
end

if (nargin < 4)
    app = 1; % stdout
    isApp = false;
else
    isApp = ~isa(app, 'numeric');
end

%% collect aggregate measures and other relevant data
%  to add a measure that can be calculated as a function of available measures do something like this:
%  LocomotionMeasures = AddFieldsInArrayOfStructures(LocomotionMeasures,{'AddedMeasures','LyapunovPerStrideRN'},@rdivide,{'Measures','LyapunovRN'},{'Measures','StrideFrequency'});
measuresStruct = ArrayOfStructures2StructureOfArraysRC(locomotionMeasures);


%% set parameters

if isfield(params, 'percentiles')
    percentiles = params.percentiles;
else
    percentiles = [10 50 90];
    if (verbosity_level > 1)
        fprintf(app, 'Using default percentiles [10 50 90]\n');
    end 
end


if isfield(params, 'skipStartSeconds')
    nSecondsSkipBegin = params.skipStartSeconds;
else
    nSecondsSkipBegin = 0;
    if (verbosityLevel > 1)
        fprintf(app, 'Not skipping any data at start of measurement (use ');
        fprintf(app, '\"Skip seconds at start of measurement\" in parameter file to overrule).\n');
    end
end

if isfield(locomotionMeasures, 'sampleRate')
     fs = mean([locomotionMeasures.sampleRate]); % works for OMX
else
     fs = 100;
     fprintf(app, 'Using default sample rate of %d Hz.\n', fs);
end
    
functionArguments.N = 50; % minimum number of epochs
functionArguments.P = percentiles;

nAggregators   = numel(percentiles);
nMeasures      = 0;
aggregateInfo  = nan(nMeasures,nAggregators);

nSkipBegin = nSecondsSkipBegin*fs;
flags = measuresStruct.absoluteStartIndex > nSkipBegin;
   
% exclude running, which we (based on experimental data) expect to result in short stride times <0.8 and high vertical SD>5)
running = measuresStruct.Measures.StandardDeviation.r1.c1 > 5 | measuresStruct.Measures.StrideTimeSeconds < 0.8;
flags(running) = 0;
  
if isApp && app.abort
    return;
end

%% Get the aggregate values and field names
[aggValues,aggMeasureNames] = GetMultipleAggValues(measuresStruct,flags,{},aggregateFunction,nAggregators,functionArguments);
aggregateInfo(1:size(aggMeasureNames,1),:,:) = nan;
aggregateInfo(:,:) = aggValues;


%% some info
nEpochsUsed = sum(flags);
if (verbosityLevel > 1)
    nSamplesUsed  = sum(flags .* measuresStruct.nSamples);
    fprintf(app, 'Number of %ds epochs used: %d\n', params.epochLength, nEpochsUsed);
    fprintf(app, 'Number of samples used:  %d\n', nSamplesUsed);
end


%% calculate Ashman's D mean walking speed and bimodal distribution fit
speed = measuresStruct.Measures.WalkingSpeedMean(flags)';
if length(speed) >= functionArguments.N
    gm =  fitgmdist(speed, 2, 'Start', 'plus', 'Replicates', 100, 'RegularizationValue', 0.0001, 'Options', statset('MaxIter', 1000));
    % Determine Ashman's D according to: Aspeshman, K. M., Bird, C. M., & Zepf, S. E. (1994). Detecting bimodality in astronomical datasets. arXiv preprint astro-ph/9408030.
    bimodalFitWalkingSpeed.Ashman_D = abs(diff(gm.mu)) ./ sqrt(sum(gm.Sigma)./2); % difference in means divided by pooled SD - essentially a z-test... Note that sigma = SD^2
    % location and rel. height of peaks
    [bimodalFitWalkingSpeed.peakSpeed, idx] = sort(gm.mu');
    bimodalFitWalkingSpeed.peakDensity = gm.ComponentProportion(idx);
    bimodalFitWalkingSpeed.gmfit = gm;
    
    % determine P* of PWS
    if isfield(params, 'preferredWalkingSpeed') && ~isnan(params.preferredWalkingSpeed)
        speedSorted = sort(speed);
        pws = params.preferredWalkingSpeed;
        idx = find(([0;speedSorted] < pws) & ([speedSorted;0] >= pws));
        if isempty(idx)
            if pws > max(speed) % express PWS as percentage of max
                percentilePWS = (pws/max(speed))*100;
            elseif pws < min(speed) % express PWS as percentage of min and change the sign to negative so that it can easily be spotted. Hasn’t happened yet.
                percentilePWS = (pws/min(speed))*-100;
            end
        else % determine PWS
            percentilePWS = (idx/length(speed))*100;
        end
    end
else
    bimodalFitWalkingSpeed.Ashman_D = NaN;
    bimodalFitWalkingSpeed.peakDensity = [NaN,NaN];
    bimodalFitWalkingSpeed.peakSpeed = [NaN, NaN];
    percentilePWS = NaN;
end
 
end


