function [SE] = SampleEntropy(DataIn, m, r)

%% Description
% Calculate the sample entropy as described in 
% Richman JS, Moorman JR (2000) 
% "Physiological time-series analysis using approximate entropy and sample entropy"
% American Journal of Physiology. Heart and Circulatory Physiology [2000, 278(6):H2039-49]
%
% The sample entropy is calculated as the natural logarithm of the
% probability that two samples of length m that are within a distance of r,
% remain within a distance of r when adding one additional sample. Note
% that distance is considered as the maximum of the distances for the
% individual dimensions 1 to m, and that the input data is normalised. 
%
% Input: 
%   DataIn: a one-dimensional time series
%   m: the dimension of the vectors to be used. The vectors consist of m
%   consecutive samples
%   r: the maximum distance between two samples to qualify as a
%   mathch, relative to the std of DataIn
%
% Output:
%   SE: the calculated sample entropy
%

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
%  7 May 2012, version 1.0

%% Check input
if size(DataIn,1) ~= 1 && size(DataIn,2) ~= 1 
    error('DataIn must be a vector');
end
DataIn = DataIn(:)/std(DataIn(:));
N = size(DataIn,1);
if N-m <= 0
    error('m must be smaller than the length of the time series DataIn');
end

%% Create the vectors Xm to be compared
Xm = zeros(N-m,m);
for i = 1:m,
    Xm(:,i) = DataIn(i:end-1-m+i,1);
end

%% Count the numbers of matches for Xm and Xmplusone
CountXm = 0;
CountXmplusone = 0;
XmDist = nan(size(Xm));
for i = 1:N-m,
    for j=1:m,
        XmDist(:,j)=abs(Xm(:,j)-Xm(i,j));
    end
    IdXmi = find(max(XmDist,[],2)<=r);
    CountXm = CountXm + length(IdXmi) - 1;
    CountXmplusone = CountXmplusone + sum(abs(DataIn(IdXmi+m)-DataIn(i+m))<=r) - 1;
end

%% Return sample entropy
SE = -log(CountXmplusone/CountXm); 

