function [L_Estimate,ExtraArgsOut] = CalcMaxLyapConvGait(ThisTimeSeries,FS,ExtraArgsIn)
if nargin > 2
    if isfield(ExtraArgsIn,'J')
        J=ExtraArgsIn.J;
    end
    if isfield(ExtraArgsIn,'m')
        m=ExtraArgsIn.m;
    end
    if isfield(ExtraArgsIn,'FitWinLen')
        FitWinLen=ExtraArgsIn.FitWinLen;
    end
end

%% Initialize output args
L_Estimate=nan;ExtraArgsOut.Divergence=nan;ExtraArgsOut.J=nan;ExtraArgsOut.m=nan;ExtraArgsOut.FitWinLen=nan;

%% Some checks 
% predefined J and m should not be NaN or Inf
if (exist('J','var') && ~isempty(J) && ~isfinite(J)) || (exist('m','var') && ~isempty(m) && ~isfinite(m))
    warning('Predefined J and m cannot be NaN or Inf');
    return;
end
% multidimensional time series need predefined J and m
if size(ThisTimeSeries,2) > 1 && (~exist('J','var') || ~exist('m','var') || isempty(J) || isempty(m)) 
    warning('Multidimensional time series needs predefined J and m, can''t determine Lyapunov');
    return;
end
%Check that there are no NaN or Inf values in the TimeSeries
if any(~isfinite(ThisTimeSeries(:)))
    warning('Time series contains NaN or Inf, can''t determine Lyapunov');
    return;
end
%Check that there is variation in the TimeSeries
if ~(nanstd(ThisTimeSeries) > 0)
    warning('Time series is constant, can''t determine Lyapunov');
    return;
end

%% Determine FitWinLen (=cycle time) of ThisTimeSeries
if ~exist('FitWinLen','var') || isempty(FitWinLen)
    if size(ThisTimeSeries,2)>1
        for dim=1:size(ThisTimeSeries,2),
            [Pd(:,dim),F] = pwelch(detrend(ThisTimeSeries(:,dim)),[],[],[],FS);
        end
        P = sum(Pd,2);
    else
        [P,F] = pwelch(detrend(ThisTimeSeries),[],[],[],FS);
    end
    MeanF = sum(P.*F)./sum(P);
    CycleTime = 1/MeanF;
    FitWinLen = round(CycleTime*FS);
else
    CycleTime = FitWinLen/FS;
end
ExtraArgsOut.FitWinLen=FitWinLen;

%% Determine J
if ~exist('J','var') || isempty(J)
    % Calculate mutual information and take first local minimum Tau as J
    bV = min(40,floor(sqrt(size(ThisTimeSeries,1))));
    tauVmax = FitWinLen;
    [mutMPro,cummutMPro,minmuttauVPro] = MutualInformationHisPro(ThisTimeSeries,(0:tauVmax),bV,1); % (xV,tauV,bV,flag)
    if isnan(minmuttauVPro)
        display(mutMPro);
        warning('minmuttauVPro is NaN. Consider increasing tauVmax.');
        return;
    end
    J=minmuttauVPro;
end
ExtraArgsOut.J=J;

%% Determine m
if ~exist('m','var') || isempty(m)
    escape = 10;
    max_m = 20;
    max_fnnM = 0.02;
    mV = 0;
    fnnM = 1;
    for mV = 2:max_m % for m=1, FalseNearestNeighbors is slow and lets matlab close if N>500000
        fnnM = FalseNearestNeighborsSR(ThisTimeSeries,J,mV,escape,FS); % (xV,tauV,mV,escape,theiler)
        if fnnM <= max_fnnM || isnan(fnnM)
            break
        end
    end
    if fnnM <= max_fnnM
        m = mV;
    else
        warning('Too many false nearest neighbours');
        return;
    end
end
ExtraArgsOut.m=m;

%% Create state space based upon J and m
N_ss = size(ThisTimeSeries,1)-(m-1)*J;
StateSpace=nan(N_ss,m*size(ThisTimeSeries,2)); 
for dim=1:size(ThisTimeSeries,2),
    for delay=1:m,
        StateSpace(:,(dim-1)*m+delay)=ThisTimeSeries((1:N_ss)'+(delay-1)*J,dim);
    end
end

%% Parameters for Lyapunov
WindowLen = floor(min(N_ss/5,10*FitWinLen));
if WindowLen < FitWinLen
        warning('Not enough samples for Lyapunov estimation');
        return;
end    
WindowLenSec=WindowLen/FS;

%% Calculate divergence
Divergence=div_calc(StateSpace,WindowLenSec,FS,CycleTime,0);
ExtraArgsOut.Divergence=Divergence;

%% Calculate slope of first FitWinLen samples of divergence curve
p = polyfit((1:FitWinLen)/FS,Divergence(1:FitWinLen),1);
L_Estimate = p(1);

