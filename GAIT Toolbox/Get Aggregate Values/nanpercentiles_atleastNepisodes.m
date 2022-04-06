function [Percentiles] = nanpercentiles_atleastNepisodes(X,FunctionArguments)

P = FunctionArguments.P;
N = FunctionArguments.N;
NotXnan = ~isnan(X);
if ~(sum(NotXnan(:)) >= N)
    % At least N episodes requested
    Percentiles = nan(size(P));
else
    XS = sort(X(NotXnan));
    PXS = 100*(0:(numel(XS)-1))/(numel(XS)-1);
    Percentiles = interp1(PXS,XS,P);
end