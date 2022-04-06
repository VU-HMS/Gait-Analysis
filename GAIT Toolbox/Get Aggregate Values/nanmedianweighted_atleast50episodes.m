function WeightedMedian = nanmedianweighted_atleast50episodes(X,W)

if any(size(X) ~= size(W)) || sum(size(X)>1) > 1
    error('X and W must be vectors of equal size');
end
if any(W<0)
    error('W must contain only non-negative values');
end

XWnan = isnan(X) | isnan(W);
W(XWnan) = 0;
if ~(sum(W>0) >= 50)
    % Demand at least 50 episodes
    WeightedMedian = nan;
else
    X=X(:);
    W=W(:);
    
    [XS,IX] = sort(X);
    WS = W(IX);
    
    WCR = cumsum(WS)/sum(WS);
    
    WCR50I = find(WCR>=0.5,1);
    
    if WCR(WCR50I) == 0.5
        WeightedMedian = (XS(WCR50I)+XS(WCR50I+1))/2;
    else
        WeightedMedian = XS(WCR50I);
    end
end