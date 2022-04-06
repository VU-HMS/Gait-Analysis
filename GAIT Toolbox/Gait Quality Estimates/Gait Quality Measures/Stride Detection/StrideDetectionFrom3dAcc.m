function [Strides,FirstGuess,StrideTimeGuess,RelativeStrideVariability] = StrideDetectionFrom3dAcc(AccXYZ, FS, StrideFreqGuess, Delay)

%% Description
% Detect strides in 3d accelerometer data
%
% Input: 
%   AccXYZ: a three-dimensional time series
%   FS: the sample frequency of the time series
%   StrideFreqGuess: a first guess of the stride frequency
%
% Output:
%   Strides: the indices of stride events
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
%  May 2012, version 1.0

%% Check input
if nargin < 3
    StrideFreqGuess = 1;
end
if nargin < 4
    Delay = ceil(FS/StrideFreqGuess/4);
end

if size(AccXYZ,2) ~= 3
    error('AccXYZ must be 3-d time series, i.e. contain 3 columns');
elseif size(AccXYZ,1) < 3*FS/StrideFreqGuess
    error('AccXYZ must be at least three times the expected stride time long');
end

%% Get stride time estimate and variability estimate
DistRange = round(FS/StrideFreqGuess/2):round(FS/StrideFreqGuess*2);
MedianDiff = nan(size(DistRange));
StartI = 1+round(FS/StrideFreqGuess); 
EndI = size(AccXYZ,1)-round(FS/StrideFreqGuess);
for DistNr = 1:numel(DistRange),
    Dist = DistRange(DistNr);
    MedianDiff(DistNr) = median(sum((AccXYZ(StartI:EndI-Dist,:)-AccXYZ(StartI+Dist:EndI,:)).^2,2));
end
StrideTimeAverage = mean(DistRange(MedianDiff == min(MedianDiff)));
RelativeStrideVariability = min(MedianDiff)/sum(var(AccXYZ(StartI:EndI,:),0,1));

%% Create state space
StateSpace = [AccXYZ(1:end-Delay,:),AccXYZ(1+Delay:end,:)];
StateSpaceEuclidSqr = sum(StateSpace.^2,2);

%% Initial search for events
% set search range settings
% StrideTimeGuess = FS/StrideFreqGuess;
StrideTimeGuess = StrideTimeAverage;
SearchRangeBegin = round(StrideTimeGuess*0.7);
SearchRangeEnd = round(StrideTimeGuess*1.4);
SearchRange = (1:SearchRangeEnd);
StrideIndex = find(StateSpaceEuclidSqr(SearchRange,1)==min(StateSpaceEuclidSqr(SearchRange,1)),1);
Strides = StrideIndex;
while StrideIndex <= size(StateSpaceEuclidSqr,1) - SearchRangeEnd
    SearchRange = StrideIndex+(SearchRangeBegin:SearchRangeEnd);
    StrideIndex = StrideIndex + SearchRangeBegin -1 + find(StateSpaceEuclidSqr(SearchRange,1)==min(StateSpaceEuclidSqr(SearchRange,1)),1);
    Strides(size(Strides,1)+1,1) = StrideIndex;
end
if nargout > 1 
    FirstGuess = Strides;
end

%% Second search, search closest to median of first search results
% define new Eucidian distance as distance to MedianStrideState
MedianStrideState = median(StateSpace(Strides,:),1);
StateSpaceEuclidSqr = sum((StateSpace-ones(size(StateSpace,1),1)*MedianStrideState).^2,2);
% update search range settings
MedianStrideTime = median(diff(Strides));
SearchRangeBegin = round(MedianStrideTime*0.7);
SearchRangeEnd = round(MedianStrideTime*1.4);
SearchRange = (1:SearchRangeEnd);
StrideIndex = find(StateSpaceEuclidSqr(SearchRange,1)==min(StateSpaceEuclidSqr(SearchRange,1)),1);
Strides = StrideIndex;
while StrideIndex <= size(StateSpaceEuclidSqr,1) - SearchRangeEnd
    SearchRange = StrideIndex+(SearchRangeBegin:SearchRangeEnd);
    StrideIndex = StrideIndex + SearchRangeBegin -1 + find(StateSpaceEuclidSqr(SearchRange,1)==min(StateSpaceEuclidSqr(SearchRange,1)),1);
    Strides(size(Strides,1)+1,1) = StrideIndex;
end


