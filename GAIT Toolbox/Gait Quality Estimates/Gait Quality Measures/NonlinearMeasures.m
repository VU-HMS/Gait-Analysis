function MeasuresStruct = NonlinearMeasures (MeasuresStruct, AccData, FS)
%% MeasuresStruct = NonlinearMeasures (MeasuresStruct, AccData, FS)
% Calculate maximum Lyapunov Index and SampleEntropy.
%
% Input
% MeasuresStruct: Structure to which te output is added
% AccData:        Realigned acceleration data
% FS:             Sample frequency
%
% Output
% MeasuresStruct.LyapunovW 
% MeasuresStruct.LyapunovRC 
% MeasuresStruct.SampleEntropy
% MeasuresStruct.LyapunovPerStrideW 
% MeasuresStruct.LyapunovPerStrideRC
%
%% History
% 2014-09 (KS):     Add entropy and updated settings
% 2021-12 (YZG/RC): Modified the code into function
% 2022-01 (RC):     Modified inputs/outputs and above help section
% 2022-01 (RC):     Removed cutting up the AccData in smaller epochs

%% Parameters
Ly_J = round(10/100*FS);         % Embedding delay (used in Lyapunov estimations)
Ly_m = 7;                        % Embedding dimension (used in Lyapunov estimations)
Ly_FitWinLen = round(60/100*FS); % Fitting window length (used in Lyapunov estimations Rosenstein's method)
En_m = 5;                        % Dimension, the length of the subseries to be matched (used in sample entropy estimation)
En_r = 0.3;                      % Tolerance, the maximum distance between two samples to qualify as match, relative to std of DataIn (used in sample entropy estimation)

%% Calculations
LyapunovW  = nan(1,4);
LyapunovRC = nan(1,4);
SE         = nan(1,3);

for i=1:3
    [LyapunovW(i),~]  = CalcMaxLyapWolfFixedEvolv(AccData(:,i),FS,struct('J',Ly_J,'m',Ly_m));
    [LyapunovRC(i),~] = CalcMaxLyapConvGait(AccData(:,i),FS,struct('J',Ly_J,'m',Ly_m,'FitWinLen',Ly_FitWinLen));
    [SE(1, i)]        = SampleEntropy(AccData(:,i), En_m, En_r); % no correction for FS; SE does increase with higher FS but effect is considered negligible as range is small (98-104HZ). Might consider updating r to account for larger ranges.
end
Ly_m_allaxes = ceil(Ly_m/size(AccData,2));
[LyapunovW(4),~]  = CalcMaxLyapWolfFixedEvolv(AccData,FS,struct('J',Ly_J,'m',Ly_m_allaxes));
[LyapunovRC(4),~] = CalcMaxLyapConvGait(AccData,FS,struct('J',Ly_J,'m',Ly_m_allaxes,'FitWinLen',Ly_FitWinLen));

MeasuresStruct.LyapunovW     = LyapunovW;
MeasuresStruct.LyapunovRC    = LyapunovRC;
MeasuresStruct.SampleEntropy = SE;

if isfield(MeasuresStruct,'StrideFrequency')
    MeasuresStruct.LyapunovPerStrideW  = MeasuresStruct.LyapunovW/MeasuresStruct.StrideFrequency;
    MeasuresStruct.LyapunovPerStrideRC = MeasuresStruct.LyapunovRC/MeasuresStruct.StrideFrequency;
end

