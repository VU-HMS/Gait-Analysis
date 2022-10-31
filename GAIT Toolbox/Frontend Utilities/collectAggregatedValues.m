function [aggregateInfo, aggMeasureNames, bimodalFitWalkingSpeed, percentilePWS, nEpochsUsed,...
          aggregateInfoPerDay, bimodalFitWalkingSpeedPerDay, percentilePWSPerDay]...
          = collectAggregatedValues(locomotionMeasures, params, verbosityLevel, app)
%% function [aggregateInfo, aggMeasureNames, bimodalFitWalkingSpeed, percentilePWS, nEpochsUsed...
%           aggregateInfoPerDay, bimodalFitWalkingSpeedPerDay, percentilePWSPerDay]...
%           = collectAggregatedValues(locomotionMeasures, params, verbosityLevel)\n

%% 2021, kaass@fbw.vu.nl 
% Last updated: Oct 2022, kaass@fbw.vu.nl

st = dbstack;
fncName = st.name;
str = sprintf ("Enter %s().\n", fncName);
prLog(str, fncName);

%% initialize output variables
aggMeasureNames=[];
bimodalFitWalkingSpeed=[];
percentilePWS=[];
nEpochsUsed=[];
aggregateInfoPerDay=[];
bimodalFitWalkingSpeedPerDay=struct('Ashman_D',[],'peakDensity',[], 'peakSpeed', []);
percentilePWSPerDay=[];


%% process input arguments
if (nargin < 3) 
    verbosity_level = 1;
end

if (nargin < 4)
    app = 1; % stdout
end


%% collect aggregate measures and other relevant data
%  to add a measure that can be calculated as a function of available measures do something like this:
%  LocomotionMeasures = AddFieldsInArrayOfStructures(LocomotionMeasures,{'AddedMeasures','LyapunovPerStrideRN'},@rdivide,{'Measures','LyapunovRN'},{'Measures','StrideFrequency'});
prLog("Make the measures structure.\n", fncName);
measuresStruct = ArrayOfStructures2StructureOfArraysRC(locomotionMeasures);


%% set parameters
prLog("Set parameter values.\n", fncName);
if isfield(params, 'percentiles')
    percentiles = params.percentiles;
else
    percentiles = [10 50 90];
    str = 'Using default percentiles [10 50 90]\n';
    prLog (str, fncName);
    if (verbosity_level > 1)
        fprintf(app, str);
    end 
end


if isfield(params, 'skipStartSeconds')
    nSecondsSkipBegin = params.skipStartSeconds;
else
    nSecondsSkipBegin = 0;
    str = 'Not skipping any data at start of measurement (use ' + ...
          '\"Skip seconds at start of measurement\" in parameter file to overrule).\n';
    prLog (str, fncName);
    if (verbosityLevel > 1)
        fprintf(app, str);
    end
end

if isfield(locomotionMeasures, 'sampleRate')
     fs = mean([locomotionMeasures.sampleRate]); % works for OMX
else
     fs = 100;
     str = sprintf ('Using default sample rate of %d Hz.\n', fs);
     prLog (str, fncName);
     fprintf(app, str);

end
    
aggregateFunction   = @nanpercentiles_atleastNepisodes;
functionArguments.N = 50; % minimum number of epochs
functionArguments.P = percentiles;

nAggregators   = numel(percentiles);
nMeasures      = 0;
aggregateInfo  = NaN(nMeasures,nAggregators);

nSkipBegin = nSecondsSkipBegin*fs;
flags = measuresStruct.absoluteStartIndex > nSkipBegin;
   
% exclude running, which we (based on experimental data) expect to result in short stride times <0.8 and high vertical SD>5)
running = measuresStruct.Measures.StandardDeviation.r1.c1 > 5 | measuresStruct.Measures.StrideTimeSeconds < 0.8;
flags(running) = 0;
  
if checkAbortFromGui() 
    return;
end

%% Get the aggregate values and field names
prLog("Get the aggregated values.\n", fncName);
[aggValues,aggMeasureNames] = GetMultipleAggValues(measuresStruct,flags,{},aggregateFunction,nAggregators,functionArguments);
aggregateInfo(1:size(aggMeasureNames,1),:) = nan;
aggregateInfo(:,:) = aggValues;


%% some info
nEpochsUsed = sum(flags);
nSamplesUsed  = sum(flags .* measuresStruct.nSamples);
str1 = sprintf ('Number of %ds epochs used: %d.\n', params.epochLength, nEpochsUsed);
str2 = sprintf ('Number of samples used:  %d.\n', nSamplesUsed);
prLog(str1, fncName);
prLog(str2, fncName);
if (verbosityLevel > 1)
    fprintf(app, str1);
    fprintf(app, str2);
end


%% calculate Ashman's D, the bimodal distribution fit, and the peercentile 
%  of the the preferred walking speed
speed = measuresStruct.Measures.WalkingSpeedMean(flags)';
if length(speed) >= functionArguments.N
    prLog("Calculate Ashman's D and the bimodal distribution fit.\n", fncName);
    gm =  fitgmdist(speed, 2, 'Start', 'plus', 'Replicates', 100, 'RegularizationValue', 0.0001, 'Options', statset('MaxIter', 1000));
    % Determine Ashman's D according to: Aspeshman, K. M., Bird, C. M., & Zepf, S. E. (1994). Detecting bimodality in astronomical datasets. arXiv preprint astro-ph/9408030.
    bimodalFitWalkingSpeed.Ashman_D = abs(diff(gm.mu)) ./ sqrt(sum(gm.Sigma)./2); % difference in means divided by pooled SD - essentially a z-test... Note that sigma = SD^2
    % location and rel. height of peaks
    [bimodalFitWalkingSpeed.peakSpeed, idx] = sort(gm.mu');
    bimodalFitWalkingSpeed.peakDensity = gm.ComponentProportion(idx);
    bimodalFitWalkingSpeed.gmfit = gm;
    
    % determine P* of PWS
    prLog("Calculate the percentile corresponding to the prefered walking speed.\n", fncName);
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

%% calculate measures for individual test days
prLog("Calculate the measures for individual days.\n", fncName);
if isfield(locomotionMeasures, 'absoluteStartTimeEpoch')
    n = length(locomotionMeasures);
    testDays = NaT;
    idxDays = NaN;
    j = 1;
    for i = 1 : n        
        date = datetime(locomotionMeasures(i).absoluteStartTimeEpoch,'ConvertFrom','datenum');
        day  = datetime([date.Year, date.Month, date.Day] ,'InputFormat','yyyy-MM-dd');
        if i==1
            testDays(1) = day;
            idxDays(1,1)  = 1;
        elseif day ~= testDays(j)
            h = day - testDays(j);
            while (hours(h)>24)
               idxDays(j,2) = i-1;
               j=j+1;
               idxDays(j,1) = -1;           
               testDays(j) = testDays(j-1) + hours(24);
               h = h-hours(24);
            end
            idxDays(j,2) = i-1;
            j=j+1;
            testDays(j) = day;
            idxDays(j,1) = i;
        end
        if (i==n)
            idxDays(j,2) = i;
        end
        if mod(i, 500) == 0
            if checkAbortFromGui()
                return;
            end
        end
    end
    n = length(testDays);
    aggregateInfoPerDay = NaN(n, nMeasures, nAggregators);
    bimodalFitWalkingSpeedPerDay(n,1) =  struct('Ashman_D',[],'peakDensity',[], 'peakSpeed', []);
    percentilePWSPerDay = NaN(n,1);
    for i=1:n
        str = sprintf ("Calculate the measures for day %d.\n", i);
        if idxDays(i,1) == -1 % accelerometer not worn (or no walking episodes)
            idxDays(i,1) = 1;
            idxDays(i,2) = 1; 
        end
        prLog(str, fncName);
        if checkAbortFromGui()
            return;
        end
        dayFlags = flags(idxDays(i,1): idxDays(i,2));
        [aggValues, ~] = GetMultipleAggValues(measuresStruct,dayFlags,{},aggregateFunction,nAggregators,functionArguments);
        aggregateInfoPerDay(i, 1:size(aggMeasureNames,1),:) = nan;
        aggregateInfoPerDay(i, :, :) = aggValues;
        
        speed = measuresStruct.Measures.WalkingSpeedMean(dayFlags)';
        if length(speed) >= functionArguments.N
            gm =  fitgmdist(speed, 2, 'Start', 'plus', 'Replicates', 100, 'RegularizationValue', 0.0001, 'Options', statset('MaxIter', 1000));
            % Determine Ashman's D according to: Aspeshman, K. M., Bird, C. M., & Zepf, S. E. (1994). Detecting bimodality in astronomical datasets. arXiv preprint astro-ph/9408030.
            bimodalFitWalkingSpeedPerDay(i).Ashman_D = abs(diff(gm.mu)) ./ sqrt(sum(gm.Sigma)./2); % difference in means divided by pooled SD - essentially a z-test... Note that sigma = SD^2
            % location and rel. height of peaks
            [bimodalFitWalkingSpeedPerDay(i).peakSpeed, idx] = sort(gm.mu');
            bimodalFitWalkingSpeedPerDay(i).peakDensity = gm.ComponentProportion(idx);
            bimodalFitWalkingSpeedPerDay(i).gmfit = gm;
            
            % determine P* of PWS
            if isfield(params, 'preferredWalkingSpeed') && ~isnan(params.preferredWalkingSpeed)
                speedSorted = sort(speed);
                pws = params.preferredWalkingSpeed;
                idx = find(([0;speedSorted] < pws) & ([speedSorted;0] >= pws));
                if isempty(idx)
                    if pws > max(speed) % express PWS as percentage of max
                        percentilePWSPerDay(i) = (pws/max(speed))*100;
                    elseif pws < min(speed) % express PWS as percentage of min and change the sign to negative so that it can easily be spotted. Hasn’t happened yet.
                        percentilePWSPerDay(i) = (pws/min(speed))*-100;
                    end
                else % determine PWS
                    percentilePWSPerDay(i) = (idx/length(speed))*100;
                end
            end
        else
            bimodalFitWalkingSpeedPerDay(i).Ashman_D = NaN;
            bimodalFitWalkingSpeedPerDay(i).peakDensity = [NaN,NaN];
            bimodalFitWalkingSpeedPerDay(i).peakSpeed = [NaN, NaN];
            percentilePWSPerDay(i) = NaN;
        end
    end
end

str = sprintf ("Leave %s().\n", fncName);
prLog(str, fncName);

end


