function [measures] = collectDesiredMeasures(params, aggMeasureNames, aggregateInfo)
%% function [measures] = collectDesiredMeasures(params, aggMeasureNames, aggregateInfo)
% help utility for gaitAnalyse (undocumented)

%% 2021, kaass@fbw.vu.nl 
% Last updated: Oct 2022, kaass@fbw.vu.nl

st = dbstack;
fncName = st.name;
str = sprintf ("Enter %s().\n", fncName);
prLog(str, fncName);

showNames = false; % for debugging

WalkingSpeedIdx     = [];
StrideLengthIdx     = [];
SampleEntropyIdx    = [];
StrideRegularityIdx = [];
IndexHarmonicityIdx = [];
RMSIdx              = [];
PowerAtStepFreqIdx  = [];

measures=[];

for i=1:size(aggMeasureNames)-4
    if (showNames)
        fprintf('%d: ', i);
        disp(aggMeasureNames{i});
    end
    if Contains(aggMeasureNames{i}, 'WalkingSpeed')
        WalkingSpeedIdx = [WalkingSpeedIdx i];
    elseif Contains(aggMeasureNames{i}, 'StrideLengthMean') || Contains(aggMeasureNames{i},'StepLengthMean')
        StrideLengthIdx = [StrideLengthIdx i];
    elseif Contains(aggMeasureNames{i}, 'SampleEntropy')
        SampleEntropyIdx = [SampleEntropyIdx i];
    elseif Contains(aggMeasureNames{i}, 'StrideRegularity')
        StrideRegularityIdx = [StrideRegularityIdx i];
    elseif Contains(aggMeasureNames{i}, 'IndexHarmonicity')
        IndexHarmonicityIdx = [IndexHarmonicityIdx i];
    elseif Contains(aggMeasureNames{i}, 'RMS') || Contains(aggMeasureNames{i}, 'STD') || Contains(aggMeasureNames{i}, 'StandardDeviation')  
        RMSIdx = [RMSIdx i];
    elseif Contains(aggMeasureNames{i}, 'WeissAmp')
        PowerAtStepFreqIdx = [PowerAtStepFreqIdx i];
    end
end

VT=1; ML=2; AP=3;   
if isfield(params, 'calcWalkingSpeed') && params.calcWalkingSpeed
    measures.WalkingSpeed = aggregateInfo(WalkingSpeedIdx,:);
end
if isfield(params, 'calcStrideLength') && params.calcStrideLength
    measures.StrideLength = aggregateInfo(StrideLengthIdx,:);
end
if isfield(params, 'calcSampleEntropyVT') && params.calcSampleEntropyVT
    measures.SampleEntropy_VT = aggregateInfo(SampleEntropyIdx(VT),:);
end
if isfield(params, 'calcSampleEntropyML') && params.calcSampleEntropyML
    measures.SampleEntropy_ML = aggregateInfo(SampleEntropyIdx(ML),:);
end
if isfield(params, 'calcSampleEntropyAP') && params.calcSampleEntropyAP
    measures.SampleEntropy_AP = aggregateInfo(SampleEntropyIdx(AP),:);
end
if isfield(params, 'calcStrideRegularityVT') && params.calcStrideRegularityVT
    measures.StrideRegularity_VT = aggregateInfo(StrideRegularityIdx(VT),:);
end
if isfield(params, 'calcStrideRegularityML') && params.calcStrideRegularityML
    measures.StrideRegularity_ML = aggregateInfo(StrideRegularityIdx(ML),:);
end
if isfield(params, 'calcStrideRegularityAP') && params.calcStrideRegularityAP
    measures.StrideRegularity_AP = aggregateInfo(StrideRegularityIdx(AP),:);
end
if isfield(params, 'calcRMSVT') && params.calcRMSVT
    measures.RMS_VT = aggregateInfo(RMSIdx(VT),:);
end
if isfield(params, 'calcRMSML') && params.calcRMSML
    measures.RMS_ML = aggregateInfo(RMSIdx(ML),:);
end
if isfield(params, 'calcRMSAP') && params.calcRMSAP
    measures.RMS_AP = aggregateInfo(RMSIdx(AP),:);
end
if isfield(params, 'calcIndexHarmonicityVT') && params.calcIndexHarmonicityVT
    measures.IndexHarmonicity_VT = aggregateInfo(IndexHarmonicityIdx(VT),:);
end
if isfield(params, 'calcIndexHarmonicityML') && params.calcIndexHarmonicityML
    measures.IndexHarmonicity_ML = aggregateInfo(IndexHarmonicityIdx(ML),:);
end
if isfield(params, 'calcIndexHarmonicityAP') && params.calcIndexHarmonicityAP
    measures.IndexHarmonicity_AP = aggregateInfo(IndexHarmonicityIdx(AP),:);
end
if isfield(params, 'calcPowerAtStepFreqVT') && params.calcPowerAtStepFreqVT
    if length(PowerAtStepFreqIdx)==8
        measures.PowerAtStepFreq_VT = aggregateInfo(PowerAtStepFreqIdx(VT+4),:);
    else
        measures.PowerAtStepFreq_VT = aggregateInfo(PowerAtStepFreqIdx(VT),:);
    end
end
if isfield(params, 'calcPowerAtStepFreqML') && params.calcPowerAtStepFreqML
    if length(PowerAtStepFreqIdx)==8
        measures.PowerAtStepFreq_ML = aggregateInfo(PowerAtStepFreqIdx(ML+4),:);
    else
        measures.PowerAtStepFreq_ML = aggregateInfo(PowerAtStepFreqIdx(ML),:);
    end
end
if isfield(params, 'calcPowerAtStepFreqAP') && params.calcPowerAtStepFreqAP
    if length(PowerAtStepFreqIdx)==8
        measures.PowerAtStepFreq_AP = aggregateInfo(PowerAtStepFreqIdx(AP+4),:);
    else
        measures.PowerAtStepFreq_AP = aggregateInfo(PowerAtStepFreqIdx(AP),:);
    end
end

prLog("Calculate gait quality composite score.\n", fncName);
%% calculate GaitQualityComposite as reported in van Schooten, Pijnappels,
% Rispens, Elders, Lips, Daffertshofer, Beek, & Van Dieen (2016). 
% Daily-life gait quality as predictor of falls in older people: a 1-year 
% prospective cohort study. PLoS one, 11(7), e0158623. 
% NB: one minor correction (changed sign to facilitate interpretation)
%     positive values indicate better quality & lower risk of falls, in 
%     original dataset the range of this compositescore is [-2.5 to 2.5], 
%     the mean is 0 and standard deviation is 1
if isfield(params, 'calcGaitQualityCompositeScore') && params.calcGaitQualityCompositeScore
    % select autocorrelation at dominant frequency in VT, standard deviation of the signal in ML,
    % index of harmoncity in ML and power at dominant frequency in AP
    for i=1:length(params.percentiles)
        GaitQualityforComposite = [measures.StrideRegularity_VT(i) ...
                                   measures.RMS_ML(i) ...
                                   measures.IndexHarmonicity_ML(i) ...
                                   measures.PowerAtStepFreq_AP(i)];
        
        % Rescale gait quality characteristics to z-scores using mean and std from van Schooten et al. 2016
        GaitQuality = (GaitQualityforComposite - repmat([0.4537 1.2124 0.4838 0.5176], ...
                       size(GaitQualityforComposite,1),1)) ./ repmat([0.1591 0.2708 0.2228 0.1231], ...
                       size(GaitQualityforComposite,1),1);
        
        % Regression coefficients determined in van Schooten et al. 2016
        measures.GaitQualityCompositeScore(i) = -1 * sum(GaitQuality.*[-0.718286325476242 0.175229558047312 0.268658378355463 -0.200339103183014], 2);
    end
end

str = sprintf ("Leave %s().\n", fncName);
prLog(str, fncName);

    
function bool = Contains (str, pattern)

if exist('contains', 'builtin')
    bool = sum(contains(str, pattern, 'IgnoreCase', true)) > 0;
else
    if iscell(str)
        bool = ~isempty(strfind(upper(str{2}), upper(pattern)));  
    else
        bool = ~isempty(strfind(upper(str), upper(pattern)));   
    end
end



