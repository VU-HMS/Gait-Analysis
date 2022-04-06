function [StrideFrequency, QualityInd, PeakWidth, MeanNormalizedPeakWidth] = StrideFrequencyFrom3dAccBosbaan(AccXYZ, F)

%% Description
% Estimate stride frequency in 3d accelerometer data, using multi-taper and
% pwelch spectral densities
%
% Input: 
%   AccXYZ: a three-dimensional time series with trunk accelerations
%   FS: the sample frequency of the time series
%   StrideFreqGuess: a first guess of the stride frequency
%
% Output:
%   StrideFrequency: the estimated stride frequency
%   QualityInd: a number (0-1, 0=no confidence, 1=fully confident) indicating how much confidence we have in the
%   estimated stride frequency

%% Copyright
%     COPYRIGHT (c) 2012 Sietse Rispens, VU University Amsterdam
%
%     This program is free software: you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation, either version 3 of the License, or
%     (at your option) any later version.
% 
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
% 
%     You should have received a copy of the GNU General Public License
%     along with this program.  If not, see <http://www.gnu.org/licenses/>.

%% Author
%  Sietse Rispens

%% History
%  February 2013, version 1.1, adapted from StrideFrequencyFrom3dAcc

minDuration = 5;


%% Check input
if size(AccXYZ,2) ~= 3
    error('AccXYZ must be 3-d time series, i.e. contain 3 columns');
elseif (numel(F) == 1) && (size(AccXYZ,1) < floor(minDuration*F)) % F is sample freq that may have been rounded up 
    error('AccXYZ must be at least %d seconds long', minDuration);
end


%% Get PSD
if numel(F) == 1, % Calculate the PSD from time series AccXYZ, F is the sample frequency
    AccFilt = detrend(AccXYZ,'constant');  % Detrend data to get rid of DC component in most of the specific windows
    LenPSD = floor(minDuration*F);
    for i=1:3,
        [P1,Fwf] = pwelch(AccFilt(:,i),hamming(LenPSD),[],LenPSD,F);
        [P2,Fwf] = pwelch(AccFilt(end:-1:1,i),hamming(LenPSD),[],LenPSD,F);
        Pwf(:,i) = (P1+P2)/2;
    end
elseif numel(F)==size(AccXYZ,1), % F are the frequencies of the power spectrum AccXYZ
    Fwf = F;
    Pwf = AccXYZ;
end
Pwf(:,4) = sum(Pwf,2);
    

%% Estimate stride frequency
% set parameters
HarmNr = [2 1 2];
CommonRange = [0.6 1.2];
% Get modal frequencies and the 'mean freq. of the peak'
for i=1:4,
    MF1I = find([zeros(5,1);Pwf(6:end,i)]==max([zeros(5,1);Pwf(6:end,i)]),1);
    MF1 = Fwf(MF1I,1);
    IndAround = Fwf>=MF1*0.5 & Fwf<=MF1*1.5;
    MeanAround = mean(Pwf(IndAround,i));
    PeakBeginI = find(IndAround & Fwf<MF1 & Pwf(:,i) < mean([MeanAround,Pwf(MF1I,i)]),1,'last');
    PeakEndI = find(IndAround & Fwf>MF1 & Pwf(:,i) < mean([MeanAround,Pwf(MF1I,i)]),1,'first');
    if isempty(PeakBeginI), PeakBeginI = find(IndAround,1,'first'); end
    if isempty(PeakEndI), PeakEndI = find(IndAround,1,'last'); end
    ModalF(i) = sum(Fwf(PeakBeginI:PeakEndI,1).*Pwf(PeakBeginI:PeakEndI,i))/sum(Pwf(PeakBeginI:PeakEndI,i));
    if i==4
        HarmNr(4) = HarmNr(find(Pwf(MF1I,1:3)==max(Pwf(MF1I,1:3)),1));
    end
end
% Get stride frequency and quality indicator from modal frequencies
StrFreqFirstGuesses = ModalF./HarmNr;
StdOverMean = std(StrFreqFirstGuesses)/mean(StrFreqFirstGuesses);
StrideFrequency1 = median(StrFreqFirstGuesses(1:3));
if StrideFrequency1 > CommonRange(2) && min(StrFreqFirstGuesses(1:3)) < CommonRange(2) && min(StrFreqFirstGuesses(1:3)) > CommonRange(1)
    StrideFrequency1 = min(StrFreqFirstGuesses(1:3));
end
if StrideFrequency1 < CommonRange(1) && max(StrFreqFirstGuesses(1:3)) > CommonRange(1) && max(StrFreqFirstGuesses(1:3)) < CommonRange(2)
    StrideFrequency1 = min(StrFreqFirstGuesses(1:3));
end
HarmGuess = ModalF/StrideFrequency1;
StdHarmGuessRoundErr = std(HarmGuess - round(HarmGuess));
if StdOverMean < 0.1
    QI1 = 1;
    StrideFrequency = mean(StrFreqFirstGuesses);
else
    if StdHarmGuessRoundErr < 0.1 && all(round(HarmGuess) >= 1)
        QI1 = 0.5;
        StrideFrequency = mean(ModalF./round(HarmGuess));
    else
        QI1 = 0;
        StrideFrequency = StrideFrequency1;
    end
end
if nargout >= 2
    QualityInd = QI1;
end

if nargout >= 3
    N_Harm = 20;
    PeakWidth = nan(1,3);
    if nargout >= 4
        MeanNormalizedPeakWidth = nan(1,3);
    end
    %% Get (mean) widths of harmonic peaks
    for i=1:3,
        WidthHarm = nan(1,N_Harm);
        PowerHarm  = nan(1,N_Harm);
        for HarmonicNr = 1:N_Harm,
            FreqRangeIndices = ...
                Fwf >= StrideFrequency*(HarmonicNr-0.5) ...
                & Fwf <= StrideFrequency*(HarmonicNr+0.5);
            PeakPower = sum(Pwf(FreqRangeIndices,i));
            PeakMean = sum(Pwf(FreqRangeIndices,i).*Fwf(FreqRangeIndices))/PeakPower;
            PeakMeanSquare = sum(Pwf(FreqRangeIndices,i).*Fwf(FreqRangeIndices).^2)/PeakPower;
            WidthHarm(HarmonicNr) = sqrt(PeakMeanSquare-PeakMean.^2);
            PowerHarm(HarmonicNr) = PeakPower;
        end
        PeakWidth(i) = WidthHarm(HarmNr(i)); % Take the 1st or 2nd harmonic width as original measure
        if nargout >= 4
            MeanNormalizedPeakWidth(i) = sum(WidthHarm./(1:N_Harm).*PowerHarm)/sum(PowerHarm);
        end
    end
end

if nargout == 0
    IXplotw = Fwf<10;
    figure();
    for i=1:3,
        subplot(2,2,i);
        plot(Fwf(IXplotw,1),Pwf(IXplotw,i));
    end
    subplot(2,2,4);
    plot(Fwf(IXplotw,1),Pwf(IXplotw,1:3));
end




