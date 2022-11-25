function gaitAnalyse(parametersFile, varargin)
%% function gaitAnalyse (parametersFile, [OPTIONS])
%
% Process 'parameterFile' and subsequently:
%     - load locomotion episodes
%     - calculate measures
%     - collect aggregated values
%     - write results
%
% INPUT
%
% parametersFile: Path to parameter file containg all the gait parameters
%
% OPTIONS
%
%   'verbosityLevel'    0  minimal output
%                       1  normal output (default)
%                       2  include debug info
%
%   'saveToJSON'        true   in addtion to MATLAB- and textformat, write 
%                              results in JSON-format 
%                       false  do not write JSON files (default)
%
%   'saveToSPSS'        true   in addtion to MATLAB- and textformat, write 
%                              results in SPSS-format 
%                       false  do not write SPSS files (default)
%
%   'overwriteFiles'    0  never overwrite existing files (default)
%                       1  overwrite aggregated values, but do use saved 
%                          episodes and measures if possible
%                       2  overwrite measures and aggregated
%                          values, but do use saved episodes if possible
%                       3  recalcuate everything
%
%   'overwriteEpisodes'         true == 'overwriteFiles', 3
%   'overwriteMeasures'         true == 'overwriteFiles', 2 
%   'overwriteAggregatedValues' true == 'overwriteFiles', 1
%
%   Note: - default value for above three options is false, mimicking
%           'overwriteFiles', 0
%         - if 'overrideFiles' is specified, above three options are
%           ignored
%         - saveToJSON and saveToSPSS, if specified, overrule the 
%           settings in paramatersFile
%
%  EXAMPLES
%
%  To process 'DATA/GaitParams.txt' and recalculate everything, use either
%    gaitAnalyse("DATA/GaitParams.txt", 'overwriteFiles', 3) or
%    gaitAnalyse("DATA/GaitParams.txt", 'overwriteEpisodes', true)
%  
%  If valid episodes have already been extracted, use either
%    gaitAnalyse("DATA/GaitParams.txt", 'overwriteFiles', 2) or
%    gaitAnalyse("DATA/GaitParams.txt", 'overwriteMeasures', true)
%
%  If the calculated measures are still valid, but aggregated values need 
%  to be recalcuted (e.g., because the percentiles as specified in the 
%  parameter file have been changed), use either
%    gaitAnalyse("DATA/GaitParams.txt", 'overwriteFiles', 1) or
%    gaitAnalyse("DATA/GaitParams.txt", 'overwriteAggregatedValues', true)
%
%  If less output is desired, use
%    gaitAnalyse("DATA/GaitParams.txt", 'verbosityLevel', 0)
%
%  To omit writing JSON files, use
%    gaitAnalyse("DATA/GaitParams.txt", 'saveToJSON', false)
%

%% UNDOCUMENTED OPTIONS
%  'analyzeTime'   0 = normal operation (default)
%                  1 = undocumented
%
%  'class'         (string) 'CLASS NAME' of the GUI App where 
%                  print statements should go

%% 2021, kaass@fbw.vu.nl
% Last updated: Nov 2022, kaass@fbw.vu.nl

%% process input arguments
global guiApp abortPrinted

st = dbstack;
fncName = st.name;
prLog("Start analyzing.\n", fncName, true, true);

validOverrideLevel = @(x) isnumeric(x) && isscalar(x) && (x >= 0) && (x<=3);
validVerbosityLevel= @(x) isnumeric(x) && isscalar(x) && (x >= 0) && (x<=2);
p = inputParser;
addParameter(p, 'overwriteEpisodes',         false, @islogical);
addParameter(p, 'overwriteMeasures',         false, @islogical);
addParameter(p, 'overwriteAggregatedValues', false, @islogical);
addParameter(p, 'overwriteFiles',            0,     validOverrideLevel);
addParameter(p, 'verbosityLevel',            1,     validVerbosityLevel);
addParameter(p, 'analyzeTime',               false, @islogical);
addParameter(p, 'saveToJSON',                false, @islogical);
addParameter(p, 'saveToSPSS',                false, @islogical);
addParameter(p, 'class',                     0,     @isobject);
parse(p,varargin{:})

app = p.Results.class;
overwriteFiles = p.Results.overwriteFiles;
verbosityLevel = p.Results.verbosityLevel;
analyzeTime    = p.Results.analyzeTime;

guiApp = [];
abortPrinted = false;
isGUI = false;
idOut = 1; % 1 refers to stdandard output in fprintf
if (isa(app, 'gaitAnalysis') || isa(app,'gaitAnalysis_exported') || ...
    isa(app, 'GaitAnalysis') || isa(app,'GaitAnalysis_exported'))   
    guiApp = app; 
    idOut  = app; % used for redirecting console output through app's method fprintf
    isGUI  = true;
end


if (~ismember('overwriteFiles', p.UsingDefaults))
    if (verbosityLevel > 0)
        if (~ismember('overwriteEpisodes',         p.UsingDefaults) || ...
            ~ismember('overwriteMeasures',         p.UsingDefaults) || ...
            ~ismember('overwriteAggregatedValues', p.UsingDefaults))
            str = sprintf ("Warning: Option 'overwriteFiles' overrules all other overwrite options!\n");
            fprintf(idOut, str);
            prLog(str, fncName);
        end
    end
else
    if (p.Results.overwriteEpisodes) 
        overwriteFiles = 3;
        if (verbosityLevel > 1)
            if (~ismember('overwriteMeasures', p.UsingDefaults) && ~p.Results.overwriteMeasures)
                str = sprintf("Warning: Option 'overwriteEpisodes' implies 'overwriteMeasures'!\n");
                fprintf(idOut, str);
                prLog(str, fncName);
            end
            if (~ismember('overwriteAggregatedValues', p.UsingDefaults) && ~p.Results.overwriteAggregatedValues)
                str = sprintf("Warning: Option 'overwriteEpisodes' implies 'overwriteAggregatedValues'!\n");
                fprintf(idOut, str);
                prLog(str, fncName);
            end
        end
    elseif (p.Results.overwriteMeasures)
        overwriteFiles = 2;
        if (verbosityLevel > 1)
            if (~ismember('overwriteMeasures', p.UsingDefaults) && ~p.Results.overwriteAggregatedValues)
                str = sprintf("Warning: Option 'overwriteMeasures' implies 'overwriteAggregatedValues'!\n");
                fprintf(idOut, str);
                prLog(str, fncName);
            end
        end
    elseif (p.Results.overwriteAggregatedValues)
        overwriteFiles = 1;
    end
end


%% prompt for parameter file if not specified
if ~nargin 
   [file, dir] = uigetfile('.txt', 'Select parameter file');
   if ~file
       fprintf(idOut, 'No parameter file selected. '); 
       str = input('Continue anyway <y/n>? ', 's');
       if ~contains(str, 'y')
           abortAnalysis(isGUI, idOut, fncName);
           return;
       end
       parametersFile=[];
   else
       parametersFile = [dir file];
   end
end


%% read the parameter file
prLog("Read parameter file.\n", fncName);
if ~isempty(parametersFile)
   [params, error] = readGaitParms (parametersFile);
else
    params = []; 
end

if error 
    abortAnalysis(isGUI, idOut, fncName);
    return;
end


%% get missing paramaters
[params, error]  = getMissingGaitParms (params);
if error 
    abortAnalysis(isGUI, idOut, fncName);
    return;
end


if ~ismember('saveToJSON', p.UsingDefaults)
    params.saveToJSON = p.Results.saveToJSON; % command line overrules
end

if ~ismember('saveToSPSS', p.UsingDefaults)
    params.saveToSPSS = p.Results.saveToSPSS; % command line overrules
end

%% construct file names and show the gait paramters that will be used
prLog("Construct file names.\n", fncName);
params.classFile    = strrep(params.classFile, '\', '/');
params.accFile      = strrep(params.accFile,   '\', '/');
[filepath, name, ~] = fileparts(params.accFile);
fileNameEpisodes    = [filepath '/' name '_GA_Episodes' '.mat'];
fileNameMeasures    = [filepath '/' name '_GA_Measures' '.mat'];
fileNameAggregated  = [filepath '/' name '_GA_Aggregated' '.mat'];
fileNameResults     = [filepath '/' name '_GA_Results' '.mat'];
fileNameResultsTxt  = [filepath '/' name '_GA_Results' '.txt'];
fileNameActivityTxt = [filepath '/' name '_GA_Activity' '.txt'];
fileNameLog         = [filepath '/' name '_GA_Log' '.txt'];

message = sprintf ("See %s for more log messages.\n\n", fileNameLog);
prLog(message, fncName);
prLog(); %% close file

params.use_acc = 1;
params.use_gyr = 0;
params.use_mag = 0;

prLog('Parameters that will be used:\n', fncName,true, true, fileNameLog);
message = sprintf('  Classification file: %s\n', params.classFile);
str = sprintf('  Raw measurement file: %s\n', params.accFile);
message = [message, str];
str = sprintf('  Leg length: %.3f\n', params.legLength);
message = [message, str];
str = sprintf('  Epoch length: %d\n', params.epochLength);
message = [message, str];
str = sprintf('  Cutoff frequency: %.2f\n', params.cutoffFrequency);
message = [message, str];
str = sprintf('  Seconds to skip from start of measurement: %d\n', params.skipStartSeconds);
message = [message, str];
str = sprintf('  Percentiles: [%d %d %d]\n', params.percentiles(1),params.percentiles(2),params.percentiles(3));
message = [message, str];
str = sprintf('  Output file locomotion episodes: %s\n', fileNameEpisodes);
message = [message, str];
str = sprintf('  Output file locomotion measures: %s\n', fileNameMeasures);
message = [message, str];
str = sprintf('  Output file aggregated values:   %s\n', fileNameAggregated);
message = [message, str];
str = sprintf('  Output file requested results:   %s\n', fileNameResults);
message = [message, str];
str = sprintf('  Output file physical activities: %s\n', fileNameActivityTxt);
message = [message, str];
str = sprintf('  Get physical activity from classification: %s\n', bool2str(params.getPhysicalActivityFromClassification));
message = [message, str];
if (params.getPhysicalActivityFromClassification)
    str = sprintf('  Minimal sensor wear time: %d hours per day\n', params.minSensorWearTime);
    message = [message, str];
    str = sprintf('  Minimum number of valid days for activities: %d\n', params.minValidDaysActivities);
    message = [message, str];
    str = sprintf('  Minimum number of valid days for lying: %d\n', params.minValidDaysLying);
    message = [message, str];
end
prLog(message, "", false);
    
if (verbosityLevel > 0)
    fprintf(idOut, '\nParameters that will be used:\n');
    message = sprintf(message); % to get '\n' printed correctly
    fprintf(idOut, message);
end

if ~checkInputFile(params.classFile, 'class', idOut, fncName)
    abortAnalysis(isGUI, idOut, fncName);
    return;
end

%% show physical activities from classification
prLog("Get physical activity from classification.\n", fncName);
if params.getPhysicalActivityFromClassification
    fprintf(idOut, '\nCollecting physical activity from classification file...\n');
    actStruct = getActivity(params.classFile, ...
                            'minSensorWearTime', params.minSensorWearTime, ...
                            'minValidDaysActivities', params.minValidDaysActivities, ...
                            'minValidDaysLying', params.minValidDaysLying);    
    if checkAbortFromGui()
        return;
    end                    
    printActivities(actStruct, idOut, false);
    if (verbosityLevel > 0)
        fprintf(idOut,'\nDetailed information can be found in %s.\n', fileNameActivityTxt);
    end
    fid = fopen(fileNameActivityTxt,'w');
    printActivities(actStruct, fid, true);
   
end

if ~checkInputFile(params.accFile, 'acc', idOut, fncName)
    abortAnalysis(isGUI, idOut, fncName);
    return;
end

%% load or extract the gait episodes
if ~exist(fileNameEpisodes, 'file') || (overwriteFiles >=3)
    prLog("Extract locomotion episodes.\n", fncName);
    fprintf(idOut, '\nExtracting locomotion episodes (may take a while)...\n');
    t = tic;
    [locomotionEpisodes, fileInfo] = ... 
       extractGaitEpisodes(params.classFile, params.accFile, params.epochLength,...
                           params.use_acc, params.use_gyr, params.use_mag, verbosityLevel);
    if checkAbortFromGui() 
        return;
    end

    fprintf(idOut, 'Time to extract locomotion episodes = %.2f seconds.\n', toc(t));
    epochLength = params.epochLength;
    if ~isempty(locomotionEpisodes)
        save (fileNameEpisodes, 'locomotionEpisodes', 'fileInfo', 'epochLength');
    end
    overwriteFiles = 2; % if episodes have been extracted, everything else needs to be recalculated
else
    prLog("Load locomotion episodes.\n", fncName);
    fprintf(idOut, '\nLoading gait episodes.\n');
    load (fileNameEpisodes, 'locomotionEpisodes', 'fileInfo', 'epochLength');
end

if checkAbortFromGui() 
    return;
end

if ~exist('locomotionEpisodes', 'var') || isempty(locomotionEpisodes)
    prLog("Unable to compute measures: no locomotion episodes found.\n", fncName);
    fprintf(idOut, "Unable to compute measures: no locomotion episodes found.\n\n");
    if params.saveToJSON
        emptyJSON(filepath, name, params);
    end
    abortAnalysis(isGUI, idOut, fncName);
    return;
end

    
%% load or calculate measures for all epochs
if ~exist(fileNameMeasures, 'file') || (overwriteFiles >= 2)
    prLog("Calculate locomotion measures.\n", fncName);
    fprintf(idOut, 'Calculating locomotion measures (may take a while)...\n');
    t = tic;
    legLength = params.legLength;
    cutoffFreq = params.cutoffFrequency;
    [locomotionMeasures] = getMeasures(locomotionEpisodes, epochLength,...
                           legLength, cutoffFreq,...
                           verbosityLevel, analyzeTime);
    if checkAbortFromGui() 
        return;
    end
    startMeasurement = locomotionEpisodes(1).absoluteStartTime - locomotionEpisodes(1).relativeStartTime;
    startDateTime = datetime(startMeasurement,'ConvertFrom','datenum','Format','yyyy-MM-dd HH:mm:ss');
    j=0;
    for i=1:length(locomotionMeasures)
        startEpisode = startDateTime + days(locomotionMeasures(i).relativeStartTime);
        if (i>1) && (locomotionMeasures(i).relativeStartTime == locomotionMeasures(i-1).relativeStartTime)
            j=j+1;
        else
            j=0;
        end
        locomotionMeasures(i).absoluteStartTimeEpoch = datenum(startEpisode + seconds(j*epochLength));
    end
    fprintf(idOut, 'Time to calculate locomotion measures = %.2f seconds.\n', toc(t));
    save (fileNameMeasures, 'locomotionMeasures', 'fileInfo', 'epochLength', 'legLength', 'cutoffFreq');
    overwriteFiles = 1; % if measures have been recalculated, aggregated values need to be recollected also
else
    prLog("Load locomotion measures.\n", fncName);
    fprintf(idOut, 'Loading locomotion measures.\n');
    load (fileNameMeasures, 'locomotionMeasures', 'legLength');
end

%% load or calculate the aggregated values
if length(locomotionMeasures) < 50
    prLog("Too few epochs to reliably calculated aggregated measures.\n", fncName);
    str = sprintf('Only %d epochs of at least %d seconds found (cannot reliably calculate the aggregated measures).\n', length(locomotionMeasures), params.epochLength);
    fprintf(idOut, str);
    fprintf(idOut, "");
    if params.saveToJSON 
        emptyJSON(filepath, name, params);
    end
    abortAnalysis(isGUI, idOut, fncName);
    return;
end

if checkAbortFromGui() 
    return;
end

if ~exist(fileNameAggregated, 'file') || (overwriteFiles >= 1)
    prLog("Collect aggregated values.\n", fncName);
    fprintf(idOut, 'Collect aggregated values...\n');
    [aggregateInfo, aggMeasureNames, bimodalFitWalkingSpeed, percentilePWS, nEpochsUsed, ...
     aggregateInfoPerDay, bimodalFitWalkingSpeedPerDay, percentilePWSPerDay] ...
     = collectAggregatedValues (locomotionMeasures, params, verbosityLevel, idOut);
    if checkAbortFromGui() 
        return;
    end
    percentiles = params.percentiles;
    if isfield(params, "preferredWalkingSpeed")
        preferredWalkingSpeed = params.preferredWalkingSpeed;
    else
        preferredWalkingSpeed = NaN;
    end
    skipStartSeconds = params.skipStartSeconds;
    save (fileNameAggregated, 'aggregateInfo', 'aggMeasureNames', 'bimodalFitWalkingSpeed',...
          'percentilePWS', 'preferredWalkingSpeed', 'percentiles', 'skipStartSeconds', 'nEpochsUsed', ...
          'aggregateInfoPerDay', 'bimodalFitWalkingSpeedPerDay', 'percentilePWSPerDay');
else    
    prLog("Load aggregated values.\n", fncName);
    fprintf(idOut, 'Loading aggregated values.\n');
    percentilePWS=NaN; % for backwards compatibility   
    bimodalFitWalkingSpeedPerDay=NaN; % for backwards compatibility
    percentilePWSPerDay=NaN; % for backwards compatibility
    load (fileNameAggregated);
end

if checkAbortFromGui() 
    return;
end
    

%% show desired aggregated measures
prLog("Show desired aggregated measures.\n", fncName);
[measures] = collectDesiredMeasures(params, aggMeasureNames, aggregateInfo);
if exist('aggregateInfoPerDay', 'var')
    nDays = size(aggregateInfoPerDay,1);
    measuresPerDay(nDays+1,1) = measures; % init struct 1:n with empty fields
    measuresPerDay(nDays+1)   = [];       % delete last struct
    for i=1:nDays
        str = sprintf ("Show desired aggregated measures for day %d.\n", i);
        prLog(str, fncName);
        if checkAbortFromGui()
            return;
        end
        if ~isnan(aggregateInfoPerDay(i,1,1))
            measuresPerDay(i) = collectDesiredMeasures(params, aggMeasureNames, squeeze(aggregateInfoPerDay(i,:,:)));
        else
            prLog("Not enough locomotion data available for this day.\n", fncName);
        end
    end
else
    nDays = 0;
    measuresPerDay=[];
end
bmf  = isfield(params, 'calcBimodalFitWalkingSpeed') && params.calcBimodalFitWalkingSpeed;
ppws = isfield(params, 'calcPercentilePWS') && params.calcPercentilePWS && ~isnan(percentilePWS);

if checkAbortFromGui()
    return;
end


%% save desired aggregated measures
prLog("Save desired measures.\n", fncName);
if isempty(measures) && ~bmf && ~ppws
    str = sprintf(idOut, 'No measures specified in %s.\n', parametersFile);
    fprintf(idOut, str);
    prLog(str, fncName);
    if isa(idOut, 'main_App')   
        fprintf(idOut, 'See "Tools | Show example parameters"\n');
    else
        % TODO: include option to show all available measures; 
        %       N.B. already done in graphical app, so no prio
        fprintf(idOut, 'Use "Walking Speed = yes" and so on.\n');
    end
else    
    % save to .mat
    prLog("Save desired measures to MATLAB file.\n", fncName);
    if ~isempty(measures)
        save(fileNameResults, 'measures');
        if ~isempty(measuresPerDay)
           save(fileNameResults, 'measuresPerDay', '-append');
        end
        if (bmf)
            save(fileNameResults, 'bimodalFitWalkingSpeed', 'bimodalFitWalkingSpeedPerDay', '-append');
        end
        if (ppws)
            save(fileNameResults, 'percentilePWS', 'percentilePWSPerDay', '-append');
        end
    else
        if (bmf && ppws)
            save(fileNameResults, 'bimodalFitWalkingSpeed', 'percentilePWS', 'bimodalFitWalkingSpeedPerDay', 'percentilePWSPerDay');
        elseif bmf
            save(fileNameResults, 'bimodalFitWalkingSpeed', 'bimodalFitWalkingSpeedPerDay');   
        elseif (ppws)
            save(fileNameResults, 'percentilePWS', 'percentilePWSPerDay');
        end
    end
        
    % save to .txt and write to console
    prLog("Save desired measures to text file.\n", fncName);
    fid = fopen(fileNameResultsTxt,'w');
    fn = fieldnames(measures);
    if ~isempty(measures)
        fprintf(idOut, '\nGeneral measures:\n');
        for i=1:numel(fn)
            str = sprintf('%25s: % .3f % .3f % .3f\n', char(fn(i)), measures.(fn{i})(1), measures.(fn{i})(2), measures.(fn{i})(3));
            fprintf(fid, str);
            fprintf(idOut, ['   ' str]);
        end
    end
    
    if bmf
        fprintf(idOut,'\nBimodal Fit Walking Speed:\n');
        fprintf(fid, '\n');
        str = sprintf('%25s: % .3f\n', 'Ashman_D', bimodalFitWalkingSpeed.Ashman_D);
        fprintf(fid, str);
        fprintf(idOut, ['   ' str]);
        str = sprintf('%25s: % .3f % .3f\n', 'PeakDensity', bimodalFitWalkingSpeed.peakDensity(1), bimodalFitWalkingSpeed.peakDensity(2));
        fprintf(fid, str);
        fprintf(idOut, ['   ' str]);
        str = sprintf('%25s: % .3f % .3f\n', 'PeakSpeed', bimodalFitWalkingSpeed.peakSpeed(1), bimodalFitWalkingSpeed.peakSpeed(2));
        fprintf(fid, str);
        fprintf(idOut, ['   ' str]);
    end
    
    if ppws
        str = sprintf('\nPercentile of Preferred Walking Speed: %.2f\n', percentilePWS);
        fprintf(idOut, str);
        str = sprintf('\n%25s: % .2f\n', 'PercentilePWS', percentilePWS);
        fprintf(fid, str);
    end
    
    % also save results for individual test days to the .txt file
    for n=1:nDays
        fprintf(fid, "\nDay %d: ", n);
        if isempty(measuresPerDay(n)) || isempty(measuresPerDay(n).WalkingSpeed)
            fprintf(fid, "not a valid day (too few locomotion epochs)\n");
        else
            fprintf(fid, '\n');
            for i=1:numel(fn)
                str = sprintf('%25s: % .3f % .3f % .3f\n', char(fn(i)),...
                    measuresPerDay(n).(fn{i})(1),...
                    measuresPerDay(n).(fn{i})(2),...
                    measuresPerDay(n).(fn{i})(3));
                fprintf(fid, ['   ' str]);
            end
            
            if bmf
                fprintf(fid, '\n');
                str = sprintf('%25s: % .3f\n', 'Ashman_D', bimodalFitWalkingSpeedPerDay(n).Ashman_D);
                fprintf(fid, str);
                str = sprintf('%25s: % .3f % .3f\n', 'PeakDensity',...
                    bimodalFitWalkingSpeedPerDay(n).peakDensity(1), ...
                    bimodalFitWalkingSpeedPerDay(n).peakDensity(2));
                fprintf(fid, str);
                str = sprintf('%25s: % .3f % .3f\n', 'PeakSpeed', ...
                    bimodalFitWalkingSpeedPerDay(n).peakSpeed(1), ...
                    bimodalFitWalkingSpeedPerDay(n).peakSpeed(2));
                fprintf(fid, str);
            end
            
            if ppws
                str = sprintf('\n%25s: % .2f\n', 'PercentilePWS', percentilePWSPerDay(n));
                fprintf(fid, ['    ' str]);
            end
        end
    end % for
    
    fclose(fid);
      
    % save to json
    if params.saveToJSON
       prLog("Save desired measures to json file(s).\n", fncName);
       fileNameResultsJSON = [filepath '/' name '_GA_Results' '.json'];
       toJSON(fileNameResultsJSON, measures, legLength, bimodalFitWalkingSpeed, percentiles, percentilePWS, bmf, ppws);
       for n=1:nDays
          nStr = sprintf ('%02d', n);
          fileNameResultsJSON = [filepath '/' name '_GA_Results_Day' nStr '.json'];
          if ~isempty(measuresPerDay(n)) && ~isempty(measuresPerDay(n).WalkingSpeed)
              toJSON(fileNameResultsJSON, measuresPerDay(n), legLength, ...
                     bimodalFitWalkingSpeedPerDay(n), percentiles, percentilePWSPerDay(n), bmf, ppws);
          else 
              toJSON(fileNameResultsJSON, [], legLength, [], percentiles, [], bmf, ppws);
          end
       end
    end
  
    % save to SPSS
    if params.saveToSPSS
       prLog("Save desired measures to spss file(s).\n", fncName); 
       fileNameResultsSPSS = [filepath '/' name '_GA_Results' '.csv'];
       toSPSS(fileNameResultsSPSS, measures, bimodalFitWalkingSpeed,...
              percentiles, percentilePWS, bmf, ppws);
       for n=1:nDays
          nStr = sprintf ('%02d', n);
          fileNameResultsSPSS = [filepath '/' name '_GA_Results_Day' nStr '.csv'];
          if ~isempty(measuresPerDay(n)) && ~isempty(measuresPerDay(n).WalkingSpeed)
              toSPSS(fileNameResultsSPSS, measuresPerDay(n), ...
                     bimodalFitWalkingSpeedPerDay(n), percentiles, ...
                     percentilePWSPerDay(n), bmf, ppws);
          end
       end
    end
    
    if (verbosityLevel > 0)
        fprintf(idOut,'\nDetailed results can be found in %s.\n', fileNameResultsTxt);
    end
end

if (verbosityLevel > 0)
    fprintf(idOut, '\nAll done!\n\n');
end

prLog("Done analyzing.\n\n", fncName);
prLog(); %% close file

end % function



%% sub functions
function abortAnalysis(isGUI, idOut, fncName)
    if isGUI
        idOut.gaitError = true;
    end
    prLog("Abort analyzing.\n\n", fncName);
    prLog(); %% close log file
end


function emptyJSON(filepath, filename, params)
    fileNameResultsJSON = [filepath '/' filename '_GA_Results' '.json'];
    bmf  = isfield(params, 'calcBimodalFitWalkingSpeed') && params.calcBimodalFitWalkingSpeed;
    ppws = isfield(params, 'calcPercentilePWS') && params.calcPercentilePWS;
    toJSON(fileNameResultsJSON, [], params.legLength, [], params.percentiles, [], bmf, ppws);
end


function str = bool2str(b)
    if b
        str = 'yes';
    else    
        str = 'no';
    end
end % end function bool2str



function printActivities (activityStruct, fd, daily)

fprintf (fd, "\nTotal wear time: %.2f out of %.2f hours\n", str2double(string(sum(activityStruct.sensorsWorn))), str2double(string(sum(activityStruct.sensorsTotal))));
fprintf (fd, "Valid days: %s out of %s\n\n", string(activityStruct.numberOfValidDays),string(activityStruct.numberOfTestDays));

fprintf (fd, "Mean activities per day:\n");
fprintf (fd, "%25s:  %s\n", "Number of strides", string(activityStruct.stridesAvg));
fprintf (fd, "%25s:%10s (n=%d)\n", "Walking duration", toTimeStr(activityStruct.walkingDurationAvg), round(activityStruct.walkingEpisodesAvg));
fprintf (fd, "%25s:%10s (n=%d)\n", "Standing duration", toTimeStr(activityStruct.standingDurationAvg), round(activityStruct.standingEpisodesAvg));
fprintf (fd, "%25s:%10s (n=%d)\n", "Sitting duration", toTimeStr(activityStruct.sittingDurationAvg), round(activityStruct.sittingEpisodesAvg));
fprintf (fd, "%25s:%10s (n=%d)\n", "Lying duration",  toTimeStr(activityStruct.lyingDurationAvg), round(activityStruct.lyingEpisodesAvg));
fprintf (fd, "%25s:%10s (n=%d)\n", "Cycling duration", toTimeStr(activityStruct.cyclingDurationAvg), round(activityStruct.cyclingEpisodesAvg));
fprintf (fd, "%25s:%10s (n=%d)\n", "Stair walking duration", toTimeStr(activityStruct.stairwalkingDurationAvg), round(activityStruct.stairwalkingEpisodesAvg));
fprintf (fd, "%25s:%10s (n=%d)\n", "Unclassified duration", toTimeStr(activityStruct.unclassifiedDurationAvg), round(activityStruct.unclassifiedEpisodesAvg));

fprintf (fd, "\nMean transitions per day (total = %s):\n", string(activityStruct.numberOfTransitionsAvg));

printTransitionTable(fd, activityStruct.transitionsAvg);

if daily
    for i = 1 : size(activityStruct.transitions,1)
        s = sprintf ("\nDay %d (wear time: %.2f out of %.2f hours):", i, str2double(string(activityStruct.sensorsWorn(i))), str2double(string(activityStruct.sensorsTotal(i))));
        if activityStruct.valid(i)
            s = s + newline();
            fprintf (fd, s);
            fprintf (fd, "%25s:  %s\n", "Number of strides", string(activityStruct.strides(i)));
            fprintf (fd, "%25s:%10s (n=%d)\n", "Walking duration", toTimeStr(activityStruct.walkingDuration(i)), activityStruct.walkingEpisodes(i));
            fprintf (fd, "%25s:%10s (n=%d)\n", "Standing duration", toTimeStr(activityStruct.standingDuration(i)), activityStruct.standingEpisodes(i));
            fprintf (fd, "%25s:%10s (n=%d)\n", "Sitting duration", toTimeStr(activityStruct.sittingDuration(i)), activityStruct.sittingEpisodes(i));
            fprintf (fd, "%25s:%10s (n=%d)\n", "Lying duration",  toTimeStr(activityStruct.lyingDuration(i)), activityStruct.lyingEpisodes(i));
            fprintf (fd, "%25s:%10s (n=%d)\n", "Cycling duration", toTimeStr(activityStruct.cyclingDuration(i)), activityStruct.cyclingEpisodes(i));
            fprintf (fd, "%25s:%10s (n=%d)\n", "Stair walking duration", toTimeStr(activityStruct.stairwalkingDuration(i)), activityStruct.stairwalkingEpisodes(i));
            fprintf (fd, "%25s:%10s (n=%d)\n", "Unclassified duration", toTimeStr(activityStruct.unclassifiedDuration(i)), activityStruct.unclassifiedEpisodes(i));
            
            fprintf (fd, "\n    Transitions (total = %s):\n", string(activityStruct.numberOfTransitions(i)));
            printTransitionTable(fd, squeeze(activityStruct.transitions(i,:,:)));
        else
            s = s + sprintf (" not a valid day (wear time too short).\n");
            fprintf (fd, s);
        end
    end
end

end % function printActivities



function printTransitionTable(fd, transitionTable)
t = transitionTable;
n = length(t);
t{1,1} = "to";
len=zeros(n-1,1);
str = "";
for i=1:n
    s = sprintf ("%16s", string(t{i,1}));
    str = str + s;
    for j=2:n
        len(j-1) = length(char(t{1,j}))+2;
        s = sprintf ("%*s", len(j-1), string(t{i,j}));
        str = str + s;
    end
    s = newline;
    str = str + s;
    if (i==1)
        s = sprintf ("          from    ");
        str = str + s;
        for stripe=1:sum(len)-2
            s = sprintf ("-");
            str = str + s;
        end
        s = newline;
        str = str + s;
    end    
end
fprintf (fd, str);

end % subfunction printTransitions


function timeStr = toTimeStr(nHours)
   timeStr = string(hours(nHours), 'hh:mm:ss');
end % subfunction timeStr



function ok = checkInputFile(file, type, fp, fncName)
   ok = true;
   
   if exist (file, 'file') ~= 2
       str = sprintf("Input file '%s' not found.\n", file);
       fprintf (fp, str);
       prLog (str, fncName);
       ok = false;
       return;
   end
   
   switch type
       case 'acc'           
           if ~isAccFile(file)
               str = sprintf("File '%s' is not a valid meausurement file.\n", file);
               if isClassFile(file)
                   str = str + "It looks like a classification file though...\n";
               end
               fprintf (fp, str);
               prLog (str, fncName);
               ok = false;
               return;
           end    
       case 'class'
           if ~isClassFile(file)
               str = sprintf("File '%s' is not a valid classification file.\n", file);
                if isAccFile(file)
                   str = str + "It looks like a raw measurement file though...\n";
               end
               fprintf (fp, str);
               prLog (str, fncName);
               ok = false;
               return;
           end          
       case default
           return
   end       
end



function bool = isAccFile(file)
    fid = fopen (file);
    str = fread (fid, 80, 'uint8=>char')';
    fclose(fid);
    bool = ((contains(str,'DP7') || contains(str,'MM')) && ...
            contains(str,'T0') && contains(str, 'T1'));
end



function bool = isClassFile(file)
    fid = fopen (file);
    str = fread (fid, 80, 'uint8=>char')';
    fclose(fid);
    bool = (contains(str, 'start') && contains(str, 'duration'));
end

