function MeasuresStruct = AccTimeDomainMeasures(MeasuresStruct, AccData, FS)
%% function MeasuresStruct = AccTimeDomainMeasures(MeasuresStruct, AccData, FS)
%
% Measures tested by Weiss et al. 2013.
% Note: They only analyzed epochs of 60+ seconds; we analyse all 
% epochs >= 5s (effect seems moderate).
%
%% Input
% MeasuresStruct: Structure to which the output is added
% AccData:        Realigned acceleration data
% FS:             Sample frequency
%
%% Output
% MeasuresStruct.WeissDominantFreq
% MeasuresStruct.WeissAmplitude,
% MeasuresStruct.WeissWidth
% MeasuresStruct.WeissRange

%% History
% 2013-07 (SR):     Created initial version
% 2021-12 (YZG/RC): Modified the code into function
% 2022-01 (RC):     Modified inputs/outputs and above help section
% 2022-01 (RC):     Removed cutting up the AccData in smaller epochs

%% parameters 
minEpochLength = 5; % min epoch length in seconds

WindowLen = size(AccData,1);
if WindowLen < minEpochLength*FS 
    eprintf ("Epoch length (%ds) too small.\n", floor(size(AccData,1)/FS));
    return;
end
    
% Spectral measures
ArrayFD             = nan(1,4);
ArrayFDAmp          = ArrayFD;
ArrayFDWidth        = ArrayFD;
ArrayFDClosest      = ArrayFD;
ArrayFDAmpClosest   = ArrayFD;
ArrayFDWidthClosest = ArrayFD;

clear P;
PWwin = 200;
Nfft = 2^(ceil(log(WindowLen)/log(2)+1));
for i=1:3
    AccData_i  = (AccData(:,i)-mean(AccData(:,i))) / std(AccData(:,i)); % normalize window
    [P(:,i),F] = pwelch(AccData_i,PWwin,[],Nfft,FS);
end
P(:,4) = sum(P,2);
for i=1:4
    % P_i=P(:,i)/sum(P(:,i))*Nfft/(FS*2*pi); % normalize to relative power per radian
    P_i=P(:,i);
    IXFRange = find(F>=0.5 & F<= 3);
    FDindClosest = IXFRange(find(P_i(IXFRange)==max(P_i(IXFRange)),1,'first'));
    FDClosest = F(FDindClosest);
    FDAmpClosest = P_i(FDindClosest);
    FDindRange = [find(P_i<0.5*FDAmpClosest & F<F(FDindClosest),1,'last'), find(P_i<0.5*FDAmpClosest & F>F(FDindClosest),1,'first')];
    if numel(FDindRange) == 2
        FDWidthClosest = diff(F(FDindRange));
    else
        FDWidthClosest = nan;
    end
    FD = FDClosest;
    FDAmp = FDAmpClosest;
    FDWidth = FDWidthClosest;
    if FDindClosest ~= min(IXFRange) && FDindClosest ~= max(IXFRange)
        VertexIX = [-1 0 1] + FDindClosest;
        [FD,FDAmp] = ParabolaVertex(F(VertexIX),P_i(VertexIX));
        FDindRange = [find(P_i<0.5*FDAmp & F<FD,1,'last'), find(P_i<0.5*FDAmp & F>FD,1,'first')];
        if numel(FDindRange) == 2
            StartP  = P_i(FDindRange(1)+[0 1]);
            StartF  = F(FDindRange(1)+[0 1]);
            StopP   = P_i(FDindRange(2)-[0 1]);
            StopF   = F(FDindRange(2)-[0 1]);
            FDRange = [interp1(StartP,StartF,0.5*FDAmp) , interp1(StopP,StopF,0.5*FDAmp)];
            FDWidth = diff(FDRange);
        end
    end
    ArrayFDClosest(i)      = FDClosest;
    ArrayFDAmpClosest(i)   = FDAmpClosest;
    ArrayFDWidthClosest(i) = FDWidthClosest;
    ArrayFD(i)             = FD;
    ArrayFDAmp(i)          = FDAmp;
    ArrayFDWidth(i)        = FDWidth;
end % for i=1:4

MeasuresStruct.WeissDominantFreq = [ArrayFDClosest;      ArrayFD];
MeasuresStruct.WeissAmplitude    = [ArrayFDAmpClosest;   ArrayFDAmp];
MeasuresStruct.WeissWidth        = [ArrayFDWidthClosest; ArrayFDWidth];
MeasuresStruct.WeissRange        = max(AccData) - min(AccData);

end % function



%% subfunctions
function [xvert,yvert] = ParabolaVertex(x,y)

if numel(x)~=3 || numel(y)~=3 || numel(unique(x))~=3
    error ('x and y must be 3-element vectors, and x must contain 3 unique elements');
end

abc = [x(:).^2 x(:) ones(3,1)]\y(:);

xvert = -abc(2)/abc(1)/2;
if nargout>1
    yvert = [xvert.^2 xvert 1]*abc;
end

end % function
