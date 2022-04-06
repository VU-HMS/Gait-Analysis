function [locomotionMeasures] = getMeasures(locomotionEpisodes, epochLength, legLength, verbosityLevel, analyzeTime)
%% function [locomotionMeasures] = getMeasures(locomotionEpisodes, epochLength, legLength, verbosityLevel)
% help utility for gaitAnalyse (undocumented)

%% 2021, kaass@fbw.vu.nl 
% Last updated: Dec 2021, kaass@fbw.vu.nl

%% process input arguments
global guiApp

if (nargin < 3)
    verbosityLevel = 1;
end

if (nargin < 4)
    analyzeTime = 0;
end

if exist('guiApp', 'var') && ~isempty(guiApp) && ~isnumeric(guiApp)
    idOut = guiApp;
    isGui = true;
else 
    idOut = 1; % refers to standard output
    isGui = false;
end

%% calculate measures for all epochs
nEpisodes = length(locomotionEpisodes);
locomotionMeasures = zeros(0,nEpisodes);
epoch = 1;
ndiscard = 0;

for i=1:nEpisodes
    
    if checkAbortFromGui() 
        return;
    end
     
    if isempty(locomotionEpisodes(i).signal)
        ndiscard = ndiscard+1;
        if (verbosityLevel > 1)
           fprintf (1, "Discarded sample %d (tot=%d), duration: %f (%f), len (%d) < winSize (%d), sample rate: %f\n", n, ndiscard, episodeLength/sampleRate, seconds, episodeLength, winSize, sampleRate);
        end
    else
        episodeLength = length(locomotionEpisodes(i).signal);
        sampleRate    = locomotionEpisodes(i).sampleRate;
        winSize       = round(sampleRate*epochLength);
       
        if episodeLength >= winSize 
            % take middle windows
            nEpochs = floor(episodeLength/winSize);
            startEpochs = 1 + floor((episodeLength-nEpochs*winSize)/2);
            for j=1:nEpochs
                first = startEpochs + (j-1)*winSize;
                last  = startEpochs + j*winSize -1;
                [locomotionMeasures(epoch).Measures] = ...
                      GaitQualityFromTrunkAccelerations(...
                          locomotionEpisodes(i).signal(first:last,:),...
                          sampleRate, legLength,...
                          'analyzeTime', analyzeTime); 
                startTimeRel = locomotionEpisodes(i).relativeStartTime;
                locomotionMeasures(epoch).relativeStartTime  = startTimeRel;
                locomotionMeasures(epoch).absoluteStartIndex = first + round(startTimeRel*24*60*60*sampleRate);
                locomotionMeasures(epoch).nSamples           = last-first+1;
                locomotionMeasures(epoch).sampleRate         = sampleRate;
                epoch = epoch+1;
            end          
         end
    end
    
    if (verbosityLevel > 0)
        if isGui
            if (i > 1)
                idOut.pReplace = true;
            end
            fprintf(idOut, 'Completed episodes = %5d/%d.\n', i, nEpisodes);
        elseif (verbosityLevel > 1) || (i==1) || (i==nEpisodes) || (mod(i,100)==0)
            fprintf(idOut, 'Completed episodes = %5d/%d.\n', i, nEpisodes);
        end
    end
    
end

end

