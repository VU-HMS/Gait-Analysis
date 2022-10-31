function [StrideFrequency, PSD, F, QualityInd, PeakWidth, MeanNormalizedPeakWidth] = StrideFrequencyFrom3dAcc(AccXYZ, FS)

%% Description
% Estimate stride frequency in 3d accelerometer data, using multi-taper and
% pwelch spectral densities
%
% Input: 
%   AccXYZ: a three-dimensional time series with trunk accelerations
%   FS: the sample frequency of the time series
%
% Output:
%   StrideFrequency: the estimated stride frequency
%   PSD: Power spectrum density
%   F:   Frequencies corresponding to the PSD
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
%  February 2013, version 1.1, adapted from StrideDetectionFrom3dAcc
%   
%  2022-10 (PvD/RC): Export PSD and F. 
%                    Rename StrideFrequencyFrom3dAccBosbaan to
%                    StrideFrequencyFrom3dAcc.

PSD =[];
F = [];
QualityInd = [];
PeakWidth = [];
MeanNormalizedPeakWidth = [];

minDuration = 5;


%% Check input
if size(AccXYZ,2) ~= 3
    error('AccXYZ must be 3-d time series, i.e. contain 3 columns');
elseif (numel(FS) == 1) && (size(AccXYZ,1) < floor(minDuration*FS)) % FS is sample freq that may have been rounded up 
    error('AccXYZ must be at least %d seconds long', minDuration);
end


%% Get PSD4
% Calculate the PSD from time series AccXYZ, FS is the sample frequency
AccFilt = detrend(AccXYZ, 'constant');  % Detrend data to get rid of DC component in most of the specific windows
LenPSD = size(AccFilt,1);
PSD = zeros(0, size(AccFilt, 2));
for i=1:3
    [P1,~]  = pwelch(AccFilt(:,i),hamming(LenPSD),[],LenPSD,FS);
    [P2,F]  = pwelch(AccFilt(end:-1:1,i),hamming(LenPSD),[],LenPSD,FS);
    PSD(1:numel(P1),i) = (P1+P2)/2;
end
PSD4 = [PSD, sum(PSD,2)];


%% Estimate stride frequency
% set parameters
HarmNr = [2 1 2];
CommonRange = [0.6 1.2];
% Get modal frequencies and the 'mean freq. of the peak'
for i=1:4
    MF1I = find([zeros(5,1);PSD4(6:end,i)]==max([zeros(5,1);PSD4(6:end,i)]),1);
    MF1 = F(MF1I,1);
    IndAround = F>=MF1*0.5 & F<=MF1*1.5;
    MeanAround = mean(PSD4(IndAround,i));
    PeakBeginI = find(IndAround & F<MF1 & PSD4(:,i) < mean([MeanAround,PSD4(MF1I,i)]),1,'last');
    PeakEndI = find(IndAround & F>MF1 & PSD4(:,i) < mean([MeanAround,PSD4(MF1I,i)]),1,'first');
    if isempty(PeakBeginI), PeakBeginI = find(IndAround,1,'first'); end
    if isempty(PeakEndI), PeakEndI = find(IndAround,1,'last'); end
    ModalF(i) = sum(F(PeakBeginI:PeakEndI,1).*PSD4(PeakBeginI:PeakEndI,i))/sum(PSD4(PeakBeginI:PeakEndI,i));
    if i==4
        HarmNr(4) = HarmNr(find(PSD4(MF1I,1:3)==max(PSD4(MF1I,1:3)),1));
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
    for i=1:3
        WidthHarm = nan(1,N_Harm);
        PowerHarm  = nan(1,N_Harm);
        for HarmonicNr = 1:N_Harm
            FreqRangeIndices = ...
                F >= StrideFrequency*(HarmonicNr-0.5) ...
                & F <= StrideFrequency*(HarmonicNr+0.5);
            PeakPower = sum(PSD4(FreqRangeIndices,i));
            PeakMean = sum(PSD4(FreqRangeIndices,i).*F(FreqRangeIndices))/PeakPower;
            PeakMeanSquare = sum(PSD4(FreqRangeIndices,i).*F(FreqRangeIndices).^2)/PeakPower;
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
    IXplotw = F<10;
    figure();
    for i=1:3
        subplot(2,2,i);
        plot(F(IXplotw,1),PSD4(IXplotw,i));
    end
    subplot(2,2,4);
    plot(F(IXplotw,1),PSD4(IXplotw,1:3));
end


