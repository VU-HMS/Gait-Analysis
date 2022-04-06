function fnnM = FalseNearestNeighborsSR(xV,tauV,mV,escape,theiler)
% fnnM = FalseNearestNeighbors(xV,tauV,mV,escape,theiler)
% FALSENEARESTNEIGHBORS computes the percentage of false nearest neighbors
% for a range of delays in 'tauV' and embedding dimensions in 'mV'.
% INPUT 
%  xV       : Vector of the scalar time series
%  tauV     : A vector of the delay times.
%  mV       : A vector of the embedding dimension.
%  escape   : A factor of escaping from the neighborhood. Default=10.
%  theiler  : the Theiler window to exclude time correlated points in the
%             search for neighboring points. Default=0.
% OUTPUT: 
%  fnnM     : A matrix of size 'ntau' x 'nm', where 'ntau' is the number of
%             given delays and 'nm' is the number of given embedding
%             dimensions, containing the percentage of false nearest
%             neighbors.
%========================================================================
%     <FalseNearestNeighbors.m>, v 1.0 2010/02/11 22:09:14  Kugiumtzis & Tsimpiris
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
% Updates:
%   Sietse Rispens, January 2012: use a different kdtree algorithm, 
%   searching k nearest neighbours, to improve performance
%
%========================================================================= 
fthres = 0.1; % A factor of the data SD to be used as the maximum radius 
              % for searching for valid nearest neighbor.
propthres = fthres; % Limit for the proportion of valid points, i.e. points 
                    % for which a nearest neighbor was found. If the proporion 
                    % of valid points is beyond this limit, do not compute
                    % FNN.
              
n = length(xV);
if isempty(escape), escape=10; end
if isempty(theiler), theiler=0; end
% Rescale to [0,1] and add infinitesimal noise to have distinct samples
xmin = min(xV);
xmax = max(xV);
xV = (xV - xmin) / (xmax-xmin);
xV = AddNoise(xV,10^(-10));
ntau = length(tauV);
nm = length(mV);
fnnM = NaN*ones(ntau,nm);
for itau = 1:ntau
    tau = tauV(itau);
    for im=1:nm
        m = mV(im);
        nvec = n-m*tau; % to be able to add the component x(nvec+tau) for m+1 
        if nvec-theiler < 2
            break;
        end
        xM = NaN*ones(nvec,m);
        for i=1:m
            xM(:,m-i+1) = xV(1+(i-1)*tau:nvec+(i-1)*tau);
        end
        % k-d-tree data structure of the training set for the given m
        TreeRoot=kdtree_build(xM); 
        % For each target point, find the nearest neighbor, and check whether 
        % the distance increase over the escape distance by adding the next
        % component for m+1.
        idxV = NaN*ones(nvec,1);
        distV = NaN*ones(nvec,1);
        k0 = 2; % The initial number of nearest neighbors to look for
        kmax = min(2*theiler + 2,nvec); % The maximum number of nearest neighbors to look for
        for i=1:nvec
            tarV = xM(i,:);
            iV = [];
            k=k0;
            kmaxreached = 0;
            while isempty(iV) && ~kmaxreached
                [neiindV, neidisV] = kdtree_k_nearest_neighbors(TreeRoot,tarV,k);
%                [neiM,neidisV,neiindV]=kdrangequery(TreeRoot,tarV,rthres*sqrt(m));
                [oneidisV,oneiindV]=sort(neidisV);
                neiindV = neiindV(oneiindV);
                neidisV = neidisV(oneiindV);
                iV = find(abs(neiindV(1)-neiindV(2:end))>theiler);
                if k >= kmax
                    kmaxreached = 1;
                elseif isempty(iV)
                    k = min(kmax,k*2);
                end
            end
            if ~isempty(iV)
                idxV(i) = neiindV(iV(1)+1);
                distV(i) = neidisV(iV(1)+1);
            end
        end % for i
        iV = find(~isnan(idxV));
        nproper = length(iV);
        % Compute fnn only if there is a sufficient number of target points 
        % having nearest neighbor (in R^m) within the threshold distance
        if nproper>propthres*nvec
            nnfactorV = 1+(xV(iV+m*tau)-xV(idxV(iV)+m*tau)).^2./distV(iV).^2;
            fnnM(itau,im) = length(find(nnfactorV > escape^2))/nproper;
        end
        kdtree_delete(TreeRoot); % Free the pointer to k-d-tree
    end
end
