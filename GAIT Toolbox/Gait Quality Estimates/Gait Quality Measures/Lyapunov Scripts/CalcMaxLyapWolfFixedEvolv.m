function [L_Estimate,ExtraArgsOut] = CalcMaxLyapWolfFixedEvolv(ThisTimeSeries,FS,ExtraArgsIn)

%% Description
% This function calculates the maximum Lyapunov exponent from a time 
% series, based on the method described by Wolf et al. in 
%    Wolf, A., et al., Determining Lyapunov exponents from a time series. 
%    Physica D: 8 Nonlinear Phenomena, 1985. 16(3): p. 285-317.
% 
% Input:
%   ThisTimeSeries: a vector or matrix with the time series
%   FS: sample frequency of the ThisTimeSeries
%   ExtraArgsIn: a struct containing optional input arguments 
%       J (embedding delay)
%       m (embedding dimension)
% Output:
%   L_Estimate: The Lyapunov estimate
%   ExtraArgsOut: a struct containing the additional output arguments
%       J (embedding delay)
%       m (embedding dimension)

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
%  April 2012, initial version of CalcMaxLyapWolf
%  23 October 2012, use fixed evolve time instead of adaptable

if nargin > 2
    if isfield(ExtraArgsIn,'J')
        J=ExtraArgsIn.J;
    end
    if isfield(ExtraArgsIn,'m')
        m=ExtraArgsIn.m;
    end
end

%% Initialize output args
L_Estimate=nan;ExtraArgsOut.J=nan;ExtraArgsOut.m=nan;

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

%% Determine J
if ~exist('J','var') || isempty(J)
    % Calculate mutual information and take first local minimum Tau as J
    bV = min(40,floor(sqrt(size(ThisTimeSeries,1))));
    tauVmax = 70;
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

%% Parameters for Lyapunov estimation
CriticalLen=J*m;
max_dist = sqrt(sum(std(StateSpace).^2))/10;
max_dist_mult = 5;
min_dist = max_dist/2;
max_theta = 0.3;
evolv = J;

%% Calculate Lambda
[L_Estimate]=div_wolf_fixed_evolv(StateSpace, FS, min_dist, max_dist, max_dist_mult, max_theta, CriticalLen, evolv);

