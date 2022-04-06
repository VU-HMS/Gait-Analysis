function [result] = graphAnal(filenameMeasures, filenameAggregated)

if ~exist('locomotionMeasures', 'var')
    load(filenameMeasures, 'locomotionMeasures', 'epochLength');
end

if ~exist('BimodalFitWalkingSpeed', 'var')
    load(filenameAggregated, 'bimodalFitWalkingSpeed');
end

nEpochs        = length(locomotionMeasures);
time           = zeros(nEpochs, 1);
speed          = time;
strideLength   = time;
strideDuration = time;
distance       = time;
idx            = time;
winSize        = epochLength; % in seconds
days2seconds   = 1/(24*60*60);

startConsecutiveEpochs = 1;
for i=1:nEpochs
    time(i)           = locomotionMeasures(i).relativeStartTime;
    idx(i)            = locomotionMeasures(i).absoluteStartIndex;
    speed(i)          = locomotionMeasures(i).Measures.WalkingSpeedMean;
    strideDuration(i) = locomotionMeasures(i).Measures.StrideTimeSeconds;
    strideLength(i)   = locomotionMeasures(i).Measures.StepLengthMean;
    if i > startConsecutiveEpochs
        if time(i) <= locomotionMeasures(startConsecutiveEpochs).relativeStartTime
            time(i) = time(i) + ((idx(i)-idx(startConsecutiveEpochs))/locomotionMeasures(i).sampleRate) * days2seconds;
        else
            startConsecutiveEpochs = i;
        end
    end
    time(i) = time(i) + 0.5*winSize*days2seconds; % halfway epoch  
    if (i==1)
        distance(i)   = locomotionMeasures(i).Measures.Distance;
    else
        distance(i)   = distance(i-1) + locomotionMeasures(i).Measures.Distance;
    end 
end

% speed2 = reshape([speed'; zeros(size(speed')); zeros(size(speed'))],[],1);
% time2=reshape([time'; time'+1/360000; [time(2:end);time(end)+2/36000]'-1/360000;], [], 1);
% time2 = time2.*24;

result.time = time.*24; % to hours
result.speed = speed;
result.distance = distance;
result.strideLength = strideLength;
result.strideDuration = strideDuration;
if isfield(bimodalFitWalkingSpeed, "gmfit")
    result.gmfit = bimodalFitWalkingSpeed.gmfit;
end

end

