function MeasuresStruct = StrideSpectralMeasures(MeasuresStruct, AccData, FS)
%% function MeasuresStruct = StrideSpectralMeasures(MeasuresStruct, AccData, FS)
%
% Get power spectra of detrended accelerations. Uses function StrideFrequencyFrom3dAccBosbaan.m
%
%% Input
% MeasuresStruct: Structure to which the output is added
% AccData:        Realigned acceleration data
% FS:             Sample frequency
%
%% Output
% MeasuresStruct.StrideFrequency
% MeasuresStruct.LowFrequentPercentage
% MeasuresStruct.IndexHarmonicity
% MeasuresStruct.FrequencyVariability
% MeasuresStruct.HarmonicRatio
% MeasuresStruct.HarmonicRatioP

%% History:
%% History
% 2013-05(SR):      1) Add rotation-invariant characteristics for:
%                      -standard devition
%                      -index of harmonicity
%                      -low-frequent percentage
%                   2) Update denominator of index of harmonicity for ML to sum(P(1:2:12))
%                   3) Update order of calculations in frequency analysis
% 2021-12 (YZG/RC): Modified the code into function
% 2022-01 (RC):     Modified inputs/outputs and above help section
% 2022-01 (RC):     Commented out SmoothPahse = sgolayfilt (was not used)

WindowLen = size(AccData,1);
N_Harm = 20; % number of harmonics used for harmonic ratio, index of harmonicity and phase fluctuation
LowFrequentPowerThresholds = [0.7 1.4]; % Threshold frequencies for estimation of low-frequent power percentages


%%
AccLocDetrend = detrend(AccData);
AccVectorLen = sqrt(sum(AccLocDetrend(:,1:3).^2,2));
P=zeros(0,size(AccLocDetrend,2));
for i=1:size(AccLocDetrend,2)
    [P1,~] = pwelch(AccLocDetrend(:,i),hamming(WindowLen),[],WindowLen,FS);
    [P2,F] = pwelch(AccLocDetrend(end:-1:1,i),hamming(WindowLen),[],WindowLen,FS);
    P(1:numel(P1),i) = (P1+P2)/2;
end
dF = F(2)-F(1);

% Calculate stride frequency
[StrideFrequency, ~] = StrideFrequencyFrom3dAccBosbaan(P, F);
MeasuresStruct.StrideFrequency = StrideFrequency;

% Add sum of power spectra (as a rotation-invariant spectrum)
P = [P,sum(P,2)];
PS = sqrt(P);

% Calculate the measures for the power per separate dimension
for i=1:size(P,2)
    % Relative cumulative power and frequencies that correspond to these cumulative powers
    PCumRel = cumsum(P(:,i))/sum(P(:,i));
    PSCumRel = cumsum(PS(:,i))/sum(PS(:,i));
    FCumRel = F+0.5*dF;
    
    % Derive relative cumulative power for threshold frequencies
    Nfreqs = size(LowFrequentPowerThresholds,2);
    MeasuresStruct.LowFrequentPercentage(i,1:Nfreqs) = interp1(FCumRel,PCumRel,LowFrequentPowerThresholds)*100;
    
    % Calculate relative power of first twenty harmonics, taking the power
    % of each harmonic with a band of + and - 10% of the first
    % harmonic around it
    PHarm = zeros(N_Harm,1);
    PSHarm = zeros(N_Harm,1);
    for Harm = 1:N_Harm
        FHarmRange = (Harm+[-0.1 0.1])*StrideFrequency;
        PHarm(Harm) = diff(interp1(FCumRel,PCumRel,FHarmRange));
        PSHarm(Harm) = diff(interp1(FCumRel,PSCumRel,FHarmRange));
    end
    
    % Derive index of harmonicity
    if i == 2 % for ML we expect odd instead of even harmonics
        MeasuresStruct.IndexHarmonicity(i) = PHarm(1)/sum(PHarm(1:2:12));
    elseif i == 4
        MeasuresStruct.IndexHarmonicity(i) = sum(PHarm(1:2))/sum(PHarm(1:12));
    else
        MeasuresStruct.IndexHarmonicity(i) = PHarm(2)/sum(PHarm(2:2:12));
    end
    
    % Calculate the phase speed fluctuations
    PhasePerStrideTimeFluctuation = nan(N_Harm,1);
    StrSamples = round(FS/StrideFrequency);
    for h=1:N_Harm
        CutOffs = [StrideFrequency*(h-(1/3)) , StrideFrequency*(h+(1/3))]/(FS/2);
        if all(CutOffs<1) % for Stride frequencies above FS/20/2, the highest harmonics are not represented in the power spectrum
            [b,a] = butter(2,CutOffs);
            if i==4 % Take the vector length as a rotation-invariant signal
                AccFilt = filtfilt(b,a,AccVectorLen);
            else
                AccFilt = filtfilt(b,a,AccLocDetrend(:,i));
            end
            Phase = unwrap(angle(hilbert(AccFilt)));
            % SmoothPhase = sgolayfilt(Phase,1,2*(floor(FS/StrideFrequency/2))+1); % This is in fact identical to a boxcar filter with linear extrapolation at the edges
            PhasePerStrideTimeFluctuation(h) = std(Phase(1+StrSamples:end,1)-Phase(1:end-StrSamples,1));
        end
    end
    MeasuresStruct.FrequencyVariability(i) = nansum(PhasePerStrideTimeFluctuation./(1:N_Harm)'.*PHarm)/nansum(PHarm);
    
    if i<4
        % Derive harmonic ratio (two variants)
        if i == 2 % for ML we expect odd instead of even harmonics
            MeasuresStruct.HarmonicRatio(i) = sum(PSHarm(1:2:end-1))/sum(PSHarm(2:2:end)); % relative to summed 3d spectrum
            MeasuresStruct.HarmonicRatioP(i) = sum(PHarm(1:2:end-1))/sum(PHarm(2:2:end)); % relative to own spectrum
        else
            MeasuresStruct.HarmonicRatio(i) = sum(PSHarm(2:2:end))/sum(PSHarm(1:2:end-1));
            MeasuresStruct.HarmonicRatioP(i) = sum(PHarm(2:2:end))/sum(PHarm(1:2:end-1));
        end
    end
end

