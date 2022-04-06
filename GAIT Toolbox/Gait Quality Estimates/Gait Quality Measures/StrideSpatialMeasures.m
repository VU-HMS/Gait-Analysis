function MeasuresStruct = StrideSpatialMeasures(MeasuresStruct, AccData, FS, Realigned, LegLength, StrideTimeSamples)
%% function MeasuresStruct = StrideSpatialMeasures(MeasuresStruct, AccData, FS, Realigned, LegLength, StrideTimeSamples)
%
% Measures from height variation by double integration of VT accelerations and high-pass filtering
% Zijlstra & Hof 2003, Assessment of spatio-temporal gait parameters from trunk accelerations
% during human walking, Gait&Posture Volume 18, Issue 2, October 2003, Pages 1-10
%
%% Input
% MeasuresStruct:    Structure to which the output is added
% AccData:           Acceleration data
% FS:                Sample frequency
% Realigned:         If false, AccData will be realigned; if true, AccData is assumed
%                    to be realigned already
% LegLength:         Leg length (unit:m)
% StrideTimeSamples: A parameter from StrideTimesMeasures.m
%
%% Output
% MeasuresStruct.Distance,
% MeasuresStruct.WalkingSpeedMean
% MeasuresStruct.StepLengthMean
% MeasuresStruct.StrideTimeVariabilityBestEvent 
% MeasuresStruct.StrideSpeedVariabilityBestEvent
% MeasuresStruct.StrideLengthVariability 
% MeasuresStruct.StrideTimeVariabilityOmitMinMax
% MeasuresStruct.StrideSpeedVariabilityOmitMinMax 
% MeasuresStruct.StrideLengthVariabilityOmitMinMax 

%% History:
% 2021-12 (YZG/RC): Modified the code into function
% 2022-01 (RC):     Modified inputs/outputs and above help section

%% parameters
IgnoreMinMaxStrides = 0.10;  % number or percentage of highest&lowest values ignored for imrpoved variability estimation
Cutoff = 0.1;
MinDist = floor(0.7*0.5*StrideTimeSamples);  

%% Integrate, filter and select vertical component
[bz,az] = butter(2,20/(FS/2),'low');
AccDataLow20 = filtfilt(bz,az,AccData);
Vel = cumsum(detrend(AccDataLow20,'constant'))/FS;
[b,a] = butter(2,Cutoff/(FS/2),'high');
Pos = cumsum(filtfilt(b,a,Vel))/FS;
PosFilt = filtfilt(b,a,Pos);
PosFiltVT = PosFilt(:,1);

if ~Realigned % Signals were not realigned, so it has to be done here
    MeanAcc = mean(AccData);
    VT = MeanAcc'/norm(MeanAcc);
    PosFiltVT = PosFilt*VT;
end

%% Find minima and maxima in vertical position
[PosPks,PosLocs] = findpeaks(PosFiltVT(:,1),'minpeakdistance',MinDist);
[NegPks,NegLocs] = findpeaks(-PosFiltVT(:,1),'minpeakdistance',MinDist);
NegPks = -NegPks;

if isempty(PosPks) && isempty(NegPks)
    PksAndLocs = zeros(0,3);
else
    PksAndLocs = sortrows([PosPks,PosLocs,ones(size(PosPks)) ; NegPks,NegLocs,-ones(size(NegPks))], 2);
end

%% Correct events for two consecutive maxima or two consecutive minima
Events = PksAndLocs(:,2);
NewEvents = PksAndLocs(:,2);
Signs = PksAndLocs(:,3);
FalseEventsIX = find(diff(Signs)==0);
PksAndLocsToAdd = zeros(0,3);
PksAndLocsToAddNr = 0;
for i=1:numel(FalseEventsIX)
    FIX = FalseEventsIX(i);
    if FIX <= 2
        % remove the event
        NewEvents(FIX) = nan;
    elseif FIX >= numel(Events)-2
        % remove the next event
        NewEvents(FIX+1) = nan;
    else
        StrideTimesWhenAdding = [Events(FIX+1)-Events(FIX-2),Events(FIX+3)-Events(FIX)];
        StrideTimesWhenRemoving = Events(FIX+3)-Events(FIX-2);
        if max(abs(StrideTimesWhenAdding-StrideTimeSamples)) < abs(StrideTimesWhenRemoving-StrideTimeSamples)
            % add an event
            [M,IX] = min(Signs(FIX)*PosFiltVT((Events(FIX)+1):(Events(FIX+1)-1)));
            PksAndLocsToAddNr = PksAndLocsToAddNr+1;
            PksAndLocsToAdd(PksAndLocsToAddNr,:) = [M,Events(FIX)+IX,-Signs(FIX)];
        else
            % remove an event
            if FIX >= 5 && FIX <= numel(Events)-5
                ExpectedEvent = (Events(FIX-4)+Events(FIX+5))/2;
            else
                ExpectedEvent = (Events(FIX-2)+Events(FIX+3))/2;
            end
            if abs(Events(FIX)-ExpectedEvent) > abs(Events(FIX+1)-ExpectedEvent)
                NewEvents(FIX) = nan;
            else
                NewEvents(FIX+1) = nan;
            end
        end
    end
end
PksAndLocsCorrected = sortrows([PksAndLocs(~isnan(NewEvents),:);PksAndLocsToAdd],2);
% Find delta height and delta time
DH = abs(diff(PksAndLocsCorrected(:,1),1,1));
DT = diff(PksAndLocsCorrected(:,2),1,1);
% Correct outliers in delta h
MaxDH = min(median(DH)+3*mad(DH,1),LegLength/2);
DH(DH>MaxDH) = MaxDH;
% Estimate total length and speed
% (Use delta h and delta t to calculate walking speed: use formula from
% Z&H, but divide by 2 (skip factor 2)since we get the difference twice
% each step, and multiply by 1.25 which is the factor suggested by Z&H)
HalfStepLen = 1.25*sqrt(2*LegLength*DH-DH.^2);
MeasuresStruct.Distance = sum(HalfStepLen);
MeasuresStruct.WalkingSpeedMean = MeasuresStruct.Distance/(sum(DT)/FS);
% Estimate variabilities between strides
StrideLengths = HalfStepLen(1:end-3) + HalfStepLen(2:end-2) + HalfStepLen(3:end-1) + HalfStepLen(4:end);
StrideTimes = PksAndLocsCorrected(5:end,2)-PksAndLocsCorrected(1:end-4,2);
StrideSpeeds = StrideLengths./(StrideTimes/FS);
WSS = nan(1,4);
STS = nan(1,4);
for i=1:4
    STS(i) = std(StrideTimes(i:4:end))/FS;
    WSS(i) = std(StrideSpeeds(i:4:end));
end

MeasuresStruct.StepLengthMean=mean(StrideLengths);

MeasuresStruct.StrideTimeVariabilityBestEvent = min(STS);
MeasuresStruct.StrideSpeedVariabilityBestEvent = min(WSS);
MeasuresStruct.StrideLengthVariability = std(StrideLengths);
% Estimate Stride time variability and stride speed variability by removing highest and lowest part
if ~isinteger(IgnoreMinMaxStrides)
    IgnoreMinMaxStrides = ceil(IgnoreMinMaxStrides*size(StrideTimes,1));
end
StrideTimesSorted = sort(StrideTimes);
MeasuresStruct.StrideTimeVariabilityOmitMinMax = std(StrideTimesSorted(1+IgnoreMinMaxStrides:end-IgnoreMinMaxStrides));
StrideSpeedSorted = sort(StrideSpeeds);
MeasuresStruct.StrideSpeedVariabilityOmitMinMax = std(StrideSpeedSorted(1+IgnoreMinMaxStrides:end-IgnoreMinMaxStrides));
StrideLengthsSorted = sort(StrideLengths);
MeasuresStruct.StrideLengthVariabilityOmitMinMax = std(StrideLengthsSorted(1+IgnoreMinMaxStrides:end-IgnoreMinMaxStrides));
