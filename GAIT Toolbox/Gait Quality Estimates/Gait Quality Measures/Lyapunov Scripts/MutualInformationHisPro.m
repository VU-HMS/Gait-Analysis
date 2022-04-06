function [mutM,cummutM,minmuttauV] = MutualInformationHisPro(xV,tauV,bV,flag)
% [mutM,cummutM,minmuttauV] =  MutualInformationHisPro(xV,tauV,bV,flag)
% MUTUALINFORMATIONHISPRO computes the mutual information on the time
% series 'xV' for given delays in 'tauV'. The estimation of mutual
% information is based on 'b' partitions of equal probability at each dimension. 
% A number of different 'b' can be given in the input vector 'bV'.
% According to a given flag, it can also compute the cumulative mutual 
% information for each given lag, as well as the time of the first minimum 
% of the mutual information.
% INPUT
% - xV      : a vector for the time series
% - tauV    : a vector of the delays to be evaluated for
% - bV      : a vector of the number of partitions of the histogram-based
%             estimate. 
% - flag    : if 0-> compute only mutual information,
%           : if 1-> compute the mutual information, the first minimum of
%             mutual information and the cumulative mutual information. 
%             if 2-> compute (also) the cumulative mutual information
%             if 3-> compute (also) the first minimum of mutual information
% OUTPUT
% - mutM    : the vector of the mutual information values s for the given
%             delays. 
% - cummutM : the vector of the cumulative mutual information values for
%             the given delays 
% - minmuttauV : the time of the first minimum of the mutual information.
%========================================================================
%     <MutualInformationHisPro.m>, v 1.0 2010/02/11 22:09:14  Kugiumtzis & Tsimpiris
%     This is part of the MATS-Toolkit http://eeganalysis.web.auth.gr/

%========================================================================
% Copyright (C) 2010 by Dimitris Kugiumtzis and Alkiviadis Tsimpiris 
%                       <dkugiu@gen.auth.gr>

%========================================================================
% Version: 1.0

% LICENSE:
%     This program is free software; you can redistribute it and/or modify
%     it under the terms of the GNU General Public License as published by
%     the Free Software Foundation; either version 3 of the License, or
%     any later version.
%
%     This program is distributed in the hope that it will be useful,
%     but WITHOUT ANY WARRANTY; without even the implied warranty of
%     MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
%     GNU General Public License for more details.
%
%     You should have received a copy of the GNU General Public License
%     along with this program. If not, see http://www.gnu.org/licenses/>.

%=========================================================================
% Reference : D. Kugiumtzis and A. Tsimpiris, "Measures of Analysis of Time Series (MATS): 
% 	          A Matlab  Toolkit for Computation of Multiple Measures on Time Series Data Bases",
%             Journal of Statistical Software, in press, 2010

% Link      : http://eeganalysis.web.auth.gr/
%========================================================================= 
nsam = 1;
n = length(xV);
if nargin==3
    flag = 1;
elseif nargin==2 
    flag = 1;
    bV = round(sqrt(n/5));
end
if isempty(bV)
    bV = round(sqrt(n/5));
end
bV(bV==0)=round(sqrt(n/5));
tauV = sort(tauV);
ntau = length(tauV);
taumax = tauV(end);
nb = length(bV);
[oxV,ixV]=sort(xV);
[tmpV,ioxV]=sort(ixV);
switch flag
    case 0
        % Compute only the mutual information for the given lags
        mutM = NaN*ones(ntau,nb);
        for ib=1:nb
            b = bV(ib);
            if n<2*b
                break;
            end
            mutM(:,ib)=mutinfHisPro(xV,tauV,b,ioxV,ixV);
        end % for ib
        cummutM=[];
        minmuttauV=[];
    case 1
        % Compute the mutual information for all lags up to the
        % largest given lag, then compute the lag of the first minimum of
        % mutual information and the cumulative mutual information for the
        % given lags.
        mutM = NaN*ones(ntau,nb);
        cummutM = NaN*ones(ntau,nb);
        minmuttauV = NaN*ones(nb,1);
        miM = NaN*ones(taumax+1,nb);
        for ib=1:nb
            b = bV(ib);
            if n<2*b
                break;
            end
            miM(:,ib)=mutinfHisPro(xV,[0:taumax]',b,ioxV,ixV);
            mutM(:,ib) = miM(tauV+1,ib);
            minmuttauV(ib) = findminMutInf(miM(:,ib),nsam);
            % Compute the cumulative mutual information for the given delays
            for i=1:ntau
                cummutM(i,ib) = sum(miM(1:tauV(i)+1,ib));
            end
        end % for ib
    case 2
        % Compute the mutual information for all lags up to the largest 
        % given lag and then sum up to get the cumulative mutual information 
        % for the given lags.
        cummutM = NaN*ones(ntau,nb);
        miM = NaN*ones(taumax+1,nb);
        for ib=1:nb
            b = bV(ib);
            if n<2*b
                break;
            end
            miM(:,ib)=mutinfHisPro(xV,[0:taumax]',b,ioxV,ixV);
            % Compute the cumulative mutual information for the given delays
            for i=1:ntau
                cummutM(i,ib) = sum(miM(1:tauV(i)+1,ib));
            end
        end % for ib
        mutM = [];
        minmuttauV=[];
    case 3
        % Compute the mutual information for all lags up to the largest 
        % given lag and then compute the lag of the first minimum of the
        % mutual information.
        minmuttauV = NaN*ones(nb,1);
        miM = NaN*ones(taumax+1,nb);
        for ib=1:nb
            b = bV(ib);
            if n<2*b
                break;
            end
            miM(:,ib)=mutinfHisPro(xV,[0:taumax]',b,ioxV,ixV);
            minmuttauV(ib) = findminMutInf(miM(:,ib),nsam);
        end % for ib
        mutM = [];
        cummutM=[];
end
