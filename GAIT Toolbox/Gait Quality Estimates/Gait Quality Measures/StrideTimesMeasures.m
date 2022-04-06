function [MeasuresStruct,StrideTimeSamples] = StrideTimesMeasures(MeasuresStruct, AccData, FS)
%% function [MeasuresStruct, StrideTimeSamples] = StrideTimesMeasures(AccData, FS)
%
% Stride time and regularity from auto correlation (according to Moe-Nilssen and Helbostad, 
% Estimation of gait cycle characteristics by trunk accelerometry. J Biomech, 2004. 37: 121-6.)
%
%% Input
% MeasuresStruct: Structure to which the output is added
% AccData:        Realigned acceleration data
% FS:             Sample frequency
%
%% Output
% StrideTimeSamples: 
% MeasuresStruct.StrideRegularity:
% MeasuresStruct.RelativeStrideVariability: 
% MeasuresStruct.StrideTimeSeconds:

%% History: 
% 2013-06 (SR):     Add condition for stride time that autocovariance must
%                   be positive for any possible direction
% 2021-12 (YZG/RC): Modified the code into function
% 2022-01 (RC):     Modified inputs/outputs and above help section

%% Parameters
StrideTimeRange = [0.4 4.0]; % Range to search for stride time (seconds)

RangeStart = round(FS*StrideTimeRange(1));
RangeEnd = round(FS*StrideTimeRange(2));
[Autocorr3x3,Lags]=xcov(AccData,RangeEnd,'unbiased');
AutocorrSum = sum(Autocorr3x3(:,[1 5 9]),2); % This sum is independent of sensor re-orientation, as long as axes are kept orthogonal
Autocorr4 = [Autocorr3x3(:,[1 5 9]),AutocorrSum];
IXRange = (numel(Lags)-(RangeEnd-RangeStart)):numel(Lags);
% check that autocorrelations are positive for any direction,
% i.e. the 3x3 matrix is positive-definite in the extended sense for
% non-symmetric matrices, meaning that M+M' is positive-definite,
% which is true if the determinants of all square upper left corner
% submatrices of M+M' are positive (Sylvester's criterion)
AutocorrPlusTrans = Autocorr3x3+Autocorr3x3(:,[1 4 7 2 5 8 3 6 9]);
IXRangeNew = IXRange( ...
    AutocorrPlusTrans(IXRange,1) > 0 ...
    & prod(AutocorrPlusTrans(IXRange,[1 5]),2) > prod(AutocorrPlusTrans(IXRange,[2 4]),2) ...
    & prod(AutocorrPlusTrans(IXRange,[1 5 9]),2) + prod(AutocorrPlusTrans(IXRange,[2 6 7]),2) + prod(AutocorrPlusTrans(IXRange,[3 4 8]),2) ...
    > prod(AutocorrPlusTrans(IXRange,[1 6 8]),2) + prod(AutocorrPlusTrans(IXRange,[2 4 9]),2) + prod(AutocorrPlusTrans(IXRange,[3 5 7]),2) ...
    );
if isempty(IXRangeNew)
    StrideTimeSamples = Lags(IXRange(AutocorrSum(IXRange)==max(AutocorrSum(IXRange)))); % to be used in other estimations
    MeasuresStruct.StrideTimeSeconds = nan;
else
    StrideTimeSamples = Lags(IXRangeNew(AutocorrSum(IXRangeNew)==max(AutocorrSum(IXRangeNew))));
    MeasuresStruct.StrideRegularity = Autocorr4(Lags==StrideTimeSamples,:)./Autocorr4(Lags==0,:); % Moe-Nilssen&Helbostatt,2004
    MeasuresStruct.RelativeStrideVariability = 1-MeasuresStruct.StrideRegularity;
    MeasuresStruct.StrideTimeSeconds = StrideTimeSamples/FS;
end