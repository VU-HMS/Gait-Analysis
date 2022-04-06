function mutV=mutinfHisPro(xV,tauV,b,ioxV,ixV)
% mutV=mutinfHisPro(xV,tauV,b,ioxV,ixV)
% mutinfHisPro computes the mutual information on the time series 'xV' 
% for given delays in 'tauV'. The estimation of mutual information is 
% based on 'b' partitions of equal probability at each dimension. 
% The last two input parameters are the ordered time series and the
% corresponding indices that will be used in the equiprobable binning 
% (they both have been computed before and therefore they are passed 
% here rather than computing it again).
%========================================================================
%     <mutinfHisPro.m>, v 1.0 2010/02/11 22:09:14  Kugiumtzis & Tsimpiris
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
n = length(xV);
ntau = length(tauV);
mutV = NaN*ones(ntau,1);
hM = NaN*ones(b,b);
cumhM = zeros(b,b+1);  
cpxV = [1/b:1/b:1]';
for itau=1:ntau
    tau = tauV(itau);
    ntotal = n-tau;    
    rxV = [0;round(cpxV*ntotal)];
    ix1V = ixV;
    ix1V(ioxV(end-tau+1:end)) = [];
    x2prV = prctile(xV(ix1V+tau),cpxV*100);
    for i = 1:b
        for j = 1:b
            cumhM(i,j+1) = length(find(xV(ix1V(rxV(i)+1:rxV(i+1))+tau)<=x2prV(j)));
        end
        hM(i,:) = diff(cumhM(i,:));
    end
    % The use of formula H(x)=1, when log_b is used.
    mutS = 2;
    for j=1:b
        for i=1:b
            if hM(i,j) > 0
                mutS=mutS+(hM(i,j)/ntotal)*log(hM(i,j)/ntotal)/log(b);
            end
        end
    end 
    mutV(itau) = mutS;
end
