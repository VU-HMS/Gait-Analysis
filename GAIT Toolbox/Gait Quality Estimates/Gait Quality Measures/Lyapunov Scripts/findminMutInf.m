function minmuttau = findminMutInf(miV,nsam)
% minmuttau = findminMutInf(miV,nsam)
% findminMutInf finds the lag tau of the first local minimum of mutual 
% information 'miV' (given from lag 0 and up to a maximum lag 'taumax') 
% and using a sliding window of length 2*nsam+1.
%========================================================================
%     <findminMutInf.m>, v 1.0 2010/02/11 22:09:14  Kugiumtzis & Tsimpiris
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
taumax = length(miV)-1;
minmuttau = NaN;
if taumax>2*nsam
    i=nsam+1;
    found = 0;
    while i<taumax+1-nsam & found==0
        winx = miV([i-nsam:i-1 i+1:i+nsam]);
        check = find(miV(i) < winx);
        if length(check) == length(winx) 
            found=1;
        else
            i=i+1;
        end
    end
    if found
        minmuttau = i-1;
    end
end
