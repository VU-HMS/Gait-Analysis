function [locomotionEpisodes, fileInfo] = extractGaitEpisodes3ac(fileNameClassList, fileNameMeasurementData, epochLength, useAcc, useGyr, verbosityLevel)
%% function [locomotionEpisodes, fileInfo] = extractGaitEpisodes(fileNameClassList, fileNameMeasurementData, epochLength, useAcc, useGyr, verbosityLevel)
%
% Extract gait data from raw .3ac measurement with the aid of the
% PA classification list. The start and duration of each gait episode,
% as described in the classification list, can be used to extract 
% the locomotion data from the raw measurements files.
%
% INPUT:
%   fileNameClassList (str): Filename of the classification list
%   fileNameMeasurementData (str): Filename of the raw measurement file
%   epochLength (int): epoch length in seconds
%   useAcc: 1 if accelleration data should be included, 0 otherwise
%   useGyr: 1 if gyroscope data should be included, 0 otherwise
%
% OUTPUT:
%   locomotionEpisodes (struct): Struct containing the signal and
%                                information of each gait episode.
%   fileInfo (struct): Information about the raw data

%% 2022, kaass@fbw.vu.nl 
% Last updated: Dec 2022, kaass@fbw.vu.nl

    
st = dbstack;
fncName = st.name;
str = sprintf ("Enter %s().\n", fncName);
prLog(str, fncName);

%% process input arguments
global guiApp
if (nargin < 4)
    modality = [1 0 0];
elseif (nargin < 5)
    modality = [useAcc 0 0];
else
    modality = [useAcc useGyr 0];
end

useAcc = modality(1);
useGyr = modality(2);

if (nargin < 7)
    verbosityLevel = 1;
end

if exist('guiApp', 'var') && ~isempty(guiApp) && ~isnumeric(guiApp)
    idOut = guiApp;
    isGui = true;
else 
    idOut = 1; % refers to standard output
    isGui = false;
end

%% read classification list
prLog("Read the classification file.\n", fncName);
data = fileread(fileNameClassList);
if contains(data, ',')
   data = strrep(data, ',', '.');
   newFile = [fileNameClassList '_tmp.csv'];
   fid = fopen(newFile, 'w+');
   fwrite(fid, data, 'char');
   fclose(fid);
   table = readtable(newFile, 'delimiter', ';', 'TreatAsEmpty',{'.','NA','N/A'});
   delete(newFile);
else
   table = readtable(fileNameClassList,'delimiter', ';', 'TreatAsEmpty',{'.','NA','N/A'});
end
clear data

%% convert start datetime into datenum
startMeasurement = datenum(table.start(1,1));

%% we are only interested in walking
idx = strcmp (table{:,4}, 'walking') == 0;
table(idx,:) = [];

%% merge consecutive activities
for i = 2:size(table,1)
    if (datenum(table.start(i)) <= datenum(table.start(i-1)) + datenum(0,0,0,0,0,table.duration(i-1)+0.01)) 
        table.duration(i) = table.duration(i) + table.duration(i-1);
        table.start(i) = table.start(i-1);
        table.duration(i-1) = nan;
    end
end
table(isnan(table.duration),:)=[];

%% only read episodes that are at least as long as the epochLength
idx = table.duration >= epochLength;
startWalking = table.start(idx);
durationWalking = table.duration(idx);

    
%% extract the episodes
prLog("Extract the locomotion episodes.\n", fncName);
episodeStruct = struct('signal', [], 'timestamps', [],...
                       'signalGyr', [], 'timestampsGyr', [],...
                       'signalMag', [], 'timestampsMag', [],...
                       'relativeStartTime', [], 'absoluteStartTime', []);

fileInfo = struct('mmInfo', [], 'mmUserInfo', [], 'measurements', []);

if isempty(startWalking)
    locomotionEpisodes = [];
else
    % get signal and .3ac info
    [signal, fileInfo] = ac3_readFile(fileNameMeasurementData, 1);
    whos signal
    if isempty(signal)
        locomotionEpisodes = [];
        str = sprintf ('%s is not a valid .3ac or .ac3 file\n', ...
                      fileNameMeasurementData);
        prLog(str);
        eprintf(str);
        str = sprintf ("Leave %s().\n", fncName);
        prLog(str, fncName);
        return;
    end

    % create empty struct
    len = length(startWalking);
    locomotionEpisodes(len) = episodeStruct;
    n = 0;
   
    for iWalk = 1:len

        n=n+1;
        
        if checkAbortFromGui() 
            return;
        end
        
        if (verbosityLevel > 0)
            if isGui
                if (iWalk > 1)
                   idOut.pReplace = true;
                end
                fprintf(idOut, 'Extracting %5d/%d.\n', iWalk, length(startWalking));
            elseif (verbosityLevel > 1) || (iWalk==1) || (iWalk==len) || (mod(iWalk,100)==0) 
                fprintf(idOut, 'Extracting: %5d/%d.\n', iWalk, length(startWalking));
            end
        end

        % determine start and end sample
        startSample = max (1, round((datenum(startWalking(iWalk)) - startMeasurement)*24*60*60*100) + 1);
        endSample = min(fileInfo.mmInfo.mm_samplecnt, startSample + durationWalking(iWalk)*100);
        
        % get signal
        s = signal(startSample:endSample, :);
        data.ACC = s(:,1:3);
        data.MAG = [];
        if (useGyr)
            data.GYR = s(4:6);
        else
            data.GYR = [];
        end
            
        % store info
        locomotionEpisodes(n).relativeStartTime = datenum(startWalking(iWalk))-startMeasurement;
        locomotionEpisodes(n).absoluteStartTime = datenum(startWalking(iWalk));
        if (useAcc)
           locomotionEpisodes(n).signal     = data.ACC;
           locomotionEpisodes(n).sampleRate = 100;
           locomotionEpisodes(n).timestamps = startSample:0.01:startSample+0.01*length(data.ACC)-1;
        end     
        if (useGyr)
            locomotionEpisodes(n).signalGyr     = data.GYR;
            locomotionEpisodes(n).sampleRateGyr = 100;
            locomotionEpisodes(n).timestampsGyr = startSample:0.01:startSample+0.01*length(data.ACC)-1;
        end
        
        if (verbosityLevel > 1) || (iWalk==len) || (mod(iWalk,100)==0)
            str = sprintf ("Extracted %d out of %d episodes.\n", iWalk, length(startWalking));
            prLog(str, fncName);
        end

    end % for iWalk = 1:len
 
    
end %% if isempty(startWalking)

str = sprintf ("Leave %s().\n", fncName);
prLog(str, fncName);

end


