function [locomotionEpisodes, fileInfo] = extractGaitEpisodes(fileNameClassList, fileNameMeasurementData, epochLength, useAcc, useGyr, useMag, verbosityLevel)
%% function [locomotionEpisodes, fileInfo] = extractGaitEpisodes(fileNameClassList, fileNameMeasurementData, epochLength, useAcc, useGyr, useMag, verbosityLevel)
%
% Extract gait data from raw .OMX measurement with the aid of the
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
%   useMag: 1 if magnifier data should be included, 0 otherwise
%
% OUTPUT:
%   locomotionEpisodes (struct): Struct containing the signal and
%       information of each gait episode.
%   fileInfo (struct): Information about the raw data

%% 2021, kaass@fbw.vu.nl 
% Last updated: Mei 2023, kaass@fbw.vu.nl

%% set to true if OMX_readFile() version is 2019 or up
newOMXReadFileVersion = true; 

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
elseif (nargin < 6)
    modality = [useAcc useGyr 0];
else
    modality = [useAcc useGyr useMag];
end

useAcc = modality(1);
useGyr = modality(2);
useMag = modality(3);

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

days2sec = 24*60*60;
    
%% extract the episodes
prLog("Extract the locomotion episodes.\n", fncName);
episodeStruct = struct('signal', [], 'timestamps', [],...
                       'signalGyr', [], 'timestampsGyr', [],...
                       'signalMag', [], 'timestampsMag', [],...
                       'relativeStartTime', [], 'absoluteStartTime', []);

if isempty(startWalking)
    % initialise output
    fileInfo = struct('packetInfo', [], 'start', [], 'stop', [],...
                       'deviceType', [], 'deviceId', [], 'rawMetadata', []);
    locomotionEpisodes = [];
else
    % get information
    fileInfo  = OMX_readFile(fileNameMeasurementData,'info',1);
    startTime = fileInfo.start.mtime;
    stopTime  = max(fileInfo.stop.mtime, fileInfo.packetInfo(end,2)); % sometimes stop.mtime is not set properly (perhaps battery low?)
   
    % create empty struct
    len = length(startWalking);
    locomotionEpisodes(len) = episodeStruct;
    n = 0;
   
    firstSample = datenum(startWalking(1)) + datenum(0,0,0,0,0,1);
    lastSample  = datenum(startWalking(len)) + datenum(0,0,0,0,0,durationWalking(len)) - datenum(0,0,0,0,0,1);
    
    if (firstSample < startTime || lastSample > stopTime)
        str = sprintf("Time stamp mismatch; classification file and data file probably don't agree.\n");
        fprintf (idOut, str); 
        prLog (str, fncName);
        locomotionEpisodes = [];
        return;
    end
       
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
        startSample = datenum(startWalking(iWalk));
        endSample = startSample + datenum(0,0,0,0,0,durationWalking(iWalk)); 

        % extend the walking episode with a second, as OMX_readfile() rounds to blocks of 80 samples
        oneSec       = datenum(0,0,0,0,0,1);
        nSecBefore   = min(startSample-startTime, oneSec);
        nSecAfter    = min(stopTime-endSample, oneSec);
        episodeStart = startSample - nSecBefore;
        episodeEnd   = endSample + nSecAfter;
        if (episodeStart > episodeEnd)
            str = sprintf("Time stamp mismatch; classification file and data file probably don't agree.\n");
            fprintf (idOut, str); 
            prLog (str, fncName);
            locomotionEpisodes = [];
            return;
        end

        % get signal
        try
            data = OMX_readFile(fileNameMeasurementData,'modality', modality,...
                                'startTime', episodeStart, 'stopTime', episodeEnd,...
                                'packetInfo', fileInfo.packetInfo);
        catch ME % if that does not work, exclude MAG
            str = sprintf ("Warning: reading OMX file failed with error '%s'.\n", ME.message);
            fprintf (idOut, str);
            prLog (str, fncName);
            if checkAbortFromGui() 
                return;
            end
            if (useMag)
                try
                    str = sprintf("Trying again without magnetic data...\n");
                    fprintf (idOut, str); 
                    prLog (str, fncName);
                    data = OMX_readFile(fileNameMeasurementData,'modality', [useAcc useGyr 0], 'startTime',episodeStart,...
                                        'stopTime', episodeEnd, 'packetInfo', fileInfo.packetInfo);
                    data.MAG = [];                
                catch
                    str = sprintf("Failed again.\n");
                    fprintf (idOut, str); 
                    prLog (str, fncName);
                    data.ACC = [];
                    data.GYR = [];
                    data.MAG = [];
                end
            else
                data.ACC = [];
                data.GYR = [];
                data.MAG = [];
            end
        end
       
        if ~useAcc
            data.ACC=[];
        end
        if ~useGyr
            data.GYR=[];
        end
        if ~useMag
            data.MAG=[];
        end
    
        epsilon = 0.005/days2sec; % allow for 5ms deviation as time stamps in the classification appear not to be an exact match 
        if ~isempty(data.ACC)
            idx = find(data.ACC(:,1)>=startSample-epsilon, 1) : find(data.ACC(:,1)<=endSample+epsilon, 1, 'last');
            signal = data.ACC(idx,2:4);             
            if (~newOMXReadFileVersion) % already done in OMX_readfile() from spring 2019 and up!
               signal = signal*[0 1 0; -1 0 0; 0 0 1]; % rerotate to old convention: VT + up, ML + right, AP + forward.
            end
            % resample
            [ts, s, fs, error, errorStr] = resampleData(data.ACC(idx,1), signal);           
            if (error)
                % episode without proper acceleration data is useless
                str = sprintf ('%s; episode %d skipped.\n', errorStr, iWalk);
                fprintf(idOut, str);
                prLog(str, fncName);
                locomotionEpisodes(n) = [];
                n = n-1;
                continue;
            else
                locomotionEpisodes(n).timestamps = ts;
                locomotionEpisodes(n).signal     = s;
                locomotionEpisodes(n).sampleRate = fs;
                startSample = ts(1); 
            end
        else 
            % episode without acceleration data is useless
            locomotionEpisodes(n) = [];
            n = n-1;
            continue;
        end
        
        if ~isempty(data.GYR) % TODO: not tested yet            
            idx = find(data.GYR(:,1)>=startSample-epsilon, 1) : find(data.GYR(:,1)>endSample+epsilon, 1) -1;
            [ts, s, fs, error, errorStr] = resampleData(data.GYR(idx,1), data.GYR(idx,2:4));
            if (error)
                str = sprintf ('%s; gyroscope data of episode %d skipped.\n', errorStr, iWalk);
                fprintf(idOut, str);
                prLog(str, fncName);
            else
                locomotionEpisodes(n).timestampsGyr = ts;
                locomotionEpisodes(n).signalGyr     = s;
                locomotionEpisodes(n).sampleRateGyr = fs;
            end
        end
        
        if ~isempty(data.MAG) % TODO: not tested yet             
            idx = find(data.MAG(:,1)>=startSample-epsilon, 1) : find(data.MAG(:,1)>endSample+epsilon, 1) -1;
            [ts, s, fs, error, errorStr] = resampleData(data.MAG(idx,1), data.MAG(idx,2:4));
            if (error)
                str = sprintf ('%s; magnetic data of episode %d skipped.\n', errorStr, iWalk);
                fprintf(idOut, str);
                prLog(str, fncName);
            else
                locomotionEpisodes(n).timestampsMag = ts;
                locomotionEpisodes(n).signalMag     = s;
                locomotionEpisodes(n).sampleRateMag = fs;
            end
        end
         
        % store start sample
        locomotionEpisodes(n).relativeStartTime = startSample-startMeasurement;
        locomotionEpisodes(n).absoluteStartTime = startSample;
           
        if (verbosityLevel > 1) || (iWalk==len) || (mod(iWalk,100)==0)
            str = sprintf ("Extracted %d out of %d episodes.\n", iWalk, length(startWalking));
            prLog(str, fncName);
        end

    end % for iWalk = 1:len
 
    
end %% if isempty(startWalking)

str = sprintf ("Leave %s().\n", fncName);
prLog(str, fncName);

end



function [timestampsOut, signalOut, fs, error, errorStr] = resampleData(timestamps, signal)
%% function [timestampsOut, signalOut, fs, error] = resampleData(timestamps, signal)
      
   error         = 0;
   fs            = 0;
   errorStr      = '';
   signalOut     = [];
   timestampsOut = [];  

   if isempty(timestamps) 
       error = 1;
       errorStr = 'Empty timestamps';
       return;
   elseif isempty(signal)
       error = 2;
       errorStr = 'Empty signal';
       return;
   end
   
   days2sec = 24*60*60;
   t1       = timestamps(1);
   tn       = timestamps(end);      
   seconds  = (tn-t1) * days2sec;
   ns       = length(timestamps);
   fs1      = (ns-1) / seconds;
   fs2      = 1/(days2sec*mean(diff(timestamps)));
   
   if (fs1 < 45)
       error = 3;
       errorStr = 'Sample rate too low';
       return;
   end
   if isnan(fs2)
       % TODO try to remove invalid samples marked nan, inf, -inf
       error = 4;
       errorStr = 'Invalid time stamps encounterd';
       return;
   end
   if abs(fs2-fs1) > 10*eps(min(fs1, fs2))
       % TODO try to remove suspicious samples, e.g., with a negative
       % time stamp      
       error = 5;
       errorStr = 'Suspicious time stamps encountered';
       return;
   end
     
   % sample times are correct: resample 
   if (fs1 >= 45 && fs1 <= 55)
       fs = 50;
   elseif (fs1 >= 95  && fs1 <= 105)
       fs = 100;
   elseif (fs1 >= 195  && fs1 <= 205)
       fs = 200;
   elseif (fs1 >= 490  && fs1 <= 510)
       fs = 500;
   elseif (fs1 >= 990  && fs1 <= 1010)
       fs = 1000;
   else
       fs = round(fs1);  
   end  
  
   told = timestamps * days2sec;
   tnew = t1*days2sec : 1/fs : t1*days2sec + seconds;
   % resample may result in an episode that is slightly shorter
   % [signalOut, timestampsOut] = resample (signal, told, fs);
   timestampsOut = tnew / days2sec;
   signalOut     = interp1(told, signal, tnew, 'spline');
     
end