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
%                              results in JSON-format (default)
%                       false  do not write JSON files
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
%           ignored.
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
% Last updated: April 2022, kaass@fbw.vu.nl

%% process input arguments
global guiApp abortPrinted


validOverrideLevel = @(x) isnumeric(x) && isscalar(x) && (x >= 0) && (x<=3);
validVerbosityLevel= @(x) isnumeric(x) && isscalar(x) && (x >= 0) && (x<=2);
p = inputParser;
addParameter(p, 'overwriteEpisodes',         false, @islogical);
addParameter(p, 'overwriteMeasures',         false, @islogical);
addParameter(p, 'overwriteAggregatedValues', false, @islogical);
addParameter(p, 'overwriteFiles',            0,     validOverrideLevel);
addParameter(p, 'verbosityLevel',            1,     validVerbosityLevel);
addParameter(p, 'analyzeTime',               false, @islogical);
addParameter(p, 'saveToJSON',                true,  @islogical);
addParameter(p, 'class',                     0,     @isobject);
parse(p,varargin{:});

app = p.Results.class;
overwriteFiles = p.Results.overwriteFiles;
verbosityLevel = p.Results.verbosityLevel;
analyzeTime = p.Results.analyzeTime;
saveToJSON = p.Results.saveToJSON;

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
            fprintf(idOut, "Warning: Option 'overwriteFiles' overrules all other overwrite options!\n"); 
        end
    end
else
    if (p.Results.overwriteEpisodes) 
        overwriteFiles = 3;
        if (verbosityLevel > 1)
            if (~ismember('overwriteMeasures', p.UsingDefaults) && ~p.Results.overwriteMeasures)
                fprintf(idOut, "Warning: Option 'overwriteEpisodes' implies 'overwriteMeasures'!\n");
            end
            if (~ismember('overwriteAggregatedValues', p.UsingDefaults) && ~p.Results.overwriteAggregatedValues)
                fprintf(idOut, "Warning: Option 'overwriteEpisodes' implies 'overwriteAggregatedValues'!\n");
            end
        end
    elseif (p.Results.overwriteMeasures)
        overwriteFiles = 2;
        if (verbosityLevel > 1)
            if (~ismember('overwriteMeasures', p.UsingDefaults) && ~p.Results.overwriteAggregatedValues)
                fprintf(idOut, "Warning: Option 'overwriteMeasures' implies 'overwriteAggregatedValues'!\n");
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
           return;
       end
       parametersFile=[];
   else
       parametersFile = [dir file];
   end
end


%% read the parameter file
if ~isempty(parametersFile)
   [params, error] = readGaitParms (parametersFile);
else
    params = []; 
end

if error 
    if isGUI
        idOut.gaitError = true;
    end
    return;
end


%% get missing paramaters
[params, error]  = getMissingGaitParms (params);

if error 
    if isGUI
        idOut.gaitError = true;
    end
    return;
end

%% construct file names and show the gait paramters that will be used
params.classFile = strrep(params.classFile, '\', '/');
params.accFile   = strrep(params.accFile,   '\', '/');
[filepath, name, ~] = fileparts(params.accFile);
fileNameEpisodes    = [filepath '/' name '_GA_Episodes' '.mat'];
fileNameMeasures    = [filepath '/' name '_GA_Measures' '.mat'];
fileNameAggregated  = [filepath '/' name '_GA_Aggregated' '.mat'];
fileNameResults     = [filepath '/' name '_GA_Results' '.mat'];
fileNameResultsTxt  = [filepath '/' name '_GA_Results' '.txt'];
fileNameActivityTxt = [filepath '/' name '_GA_Activity' '.txt'];

params.use_acc = 1;
params.use_gyr = 0;
params.use_mag = 0;

if (verbosityLevel > 0)
    fprintf(idOut, '\nParameters that will be used:\n');
    fprintf(idOut, '  Classification file: %s\n', params.classFile);
    fprintf(idOut, '  Raw measurement file: %s\n', params.accFile);
    fprintf(idOut, '  Leg length: %.3f\n', params.legLength);
    fprintf(idOut, '  Epoch length: %d\n', params.epochLength);
    fprintf(idOut, '  Seconds to skip from start of measurement: %d\n', params.skipStartSeconds);
    fprintf(idOut, '  Percentiles: [%d %d %d]\n', params.percentiles(1),params.percentiles(2),params.percentiles(3));
    fprintf(idOut, '  Output file locomotion episodes: %s\n', fileNameEpisodes);
    fprintf(idOut, '  Output file locomotion measures: %s\n', fileNameMeasures);
    fprintf(idOut, '  Output file aggregated values:   %s\n', fileNameAggregated);
    fprintf(idOut, '  Output file requested results:   %s\n', fileNameResults);
    fprintf(idOut, '  Output file physical activities: %s\n', fileNameActivityTxt);
    fprintf(idOut, '  Get physical activity from classification: %s\n', bool2str(params.getPhysicalActivityFromClassification));
    if (params.getPhysicalActivityFromClassification)
        fprintf(idOut, '  Minimal sensor wear time: %d hours per day\n', params.minSensorWearTime);
        fprintf(idOut, '  Minimum number of valid days for activities: %d\n', params.minValidDaysActivities);
        fprintf(idOut, '  Minimum number of valid days for lying: %d\n', params.minValidDaysLying);
    end
end 

%% show physical activities from classification
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

%% load or extract the gait episodes
if ~exist(fileNameEpisodes, 'file') || (overwriteFiles >=3)
    if (verbosityLevel > 0)
        fprintf(idOut, '\nExtracting locomotion episodes (may take a while)...\n');
    end
    t = tic;
    [locomotionEpisodes, fileInfo] = ... 
       extractGaitEpisodes(params.classFile, params.accFile, params.epochLength,...
                           params.use_acc, params.use_gyr, params.use_mag, verbosityLevel);
    if checkAbortFromGui() 
        return;
    end

    fprintf(idOut, 'Time to extract locomotion episodes = %.2f seconds.\n', toc(t));
    epochLength = params.epochLength;
    save (fileNameEpisodes, 'locomotionEpisodes', 'fileInfo', 'epochLength');
    overwriteFiles = 2; % if episodes have been extracted, everything else needs to be recalculated
else
    if (verbosityLevel > 0)
        fprintf(idOut, '\nLoading gait episodes.\n');
    end
    load (fileNameEpisodes, 'locomotionEpisodes', 'fileInfo', 'epochLength');
end

if checkAbortFromGui() 
    return;
end

%% load or calculate measures for all epochs
if ~exist(fileNameMeasures, 'file') || (overwriteFiles >= 2)
    if (verbosityLevel > 0)
       fprintf(idOut, 'Calculating locomotion measures (may take a while)...\n');
    end
    t = tic;
    legLength = params.legLength;
    [locomotionMeasures] = getMeasures(locomotionEpisodes, epochLength, legLength, verbosityLevel, analyzeTime);
    if checkAbortFromGui() 
        return;
    end
    startTime = locomotionEpisodes(1).absoluteStartTime;
    startDay = datetime(startTime,'ConvertFrom','datenum','Format','yyyy-MM-dd HH:mm:ss');
    j=0;
    for i=1:length(locomotionMeasures)
        startEpisode = startDay + days(locomotionMeasures(i).relativeStartTime);
        if (i>1) && (locomotionMeasures(i).relativeStartTime == locomotionMeasures(i-1).relativeStartTime)
            j=j+1;
        else
            j=0;
        end
        locomotionMeasures(i).absoluteStartTimeEpoch = datenum(startEpisode + seconds(j*epochLength));
    end
    fprintf(idOut, 'Time to calculate locomotion measures = %.2f seconds.\n', toc(t));
    save (fileNameMeasures, 'locomotionMeasures', 'fileInfo', 'epochLength', 'legLength');
    overwriteFiles = 1; % if measures have been recalculated, aggregated values need to be recollected also
else
    if (verbosityLevel > 0)
       fprintf(idOut, 'Loading locomotion measures.\n');
    end
    load (fileNameMeasures, 'locomotionMeasures', 'legLength');
end

%% load or calculate the aggregated values
if length(locomotionMeasures) < 50
    str = sprintf('Only %d epochs of at least %d seconds found (cannot reliably calculate the aggregated measures).\n', length(locomotionMeasures), params.epochLength);
    fprintf(idOut, str);
    fprintf(idOut, "");
    if isGUI
       idOut.gaitError = true;
    end
    return;
end

if checkAbortFromGui() 
    return;
end

if ~exist(fileNameAggregated, 'file') || (overwriteFiles >= 1)
    if (verbosityLevel > 0)
        fprintf(idOut, 'Collect aggregated values...\n');
    end
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
    if (verbosityLevel > 0)
        fprintf(idOut, 'Loading aggregated values.\n');
    end
    percentilePWS=NaN; % for backwards compatibility
    measuresPerDay=NaN; % for backwards compatibility
    bimodalFitWalkingSpeedPerDay=NaN; % for backwards compatibility
    percentilePWSPerDay=NaN; % for backwards compatibility
    load (fileNameAggregated);
end

if checkAbortFromGui() 
    return;
end
    

%% show desired aggregated measures
[measures] = collectDesiredMeasures(params, aggMeasureNames, aggregateInfo);
if exist('aggregateInfoPerDay', 'var')
    nDays = size(aggregateInfoPerDay,1);
    measuresPerDay(nDays+1,1) = measures; % init struct 1:n with empty fields
    measuresPerDay(nDays+1)   = [];       % delete last struct
    for i=1:nDays
        if checkAbortFromGui()
            return;
        end
        if ~isnan(aggregateInfoPerDay(i,1,1))
            measuresPerDay(i) = collectDesiredMeasures(params, aggMeasureNames, squeeze(aggregateInfoPerDay(i,:,:)));
        else
            measuresPerDay(i) = [];
        end
    end
else
    nDays = 0;
end
bmf  = isfield(params, 'calcBimodalFitWalkingSpeed') && params.calcBimodalFitWalkingSpeed;
ppws = isfield(params, 'calcPercentilePWS') && params.calcPercentilePWS && ~isnan(percentilePWS);

if checkAbortFromGui()
    return;
end

if isempty(measures) && ~bmf && ~ppws
    fprintf(idOut, 'No measures specified in %s.\n', parametersFile);
    if isa(idOut, 'main_App')   
        fprintf(idOut, 'See "Tools | Show example parameters"\n');
    else
        % TODO: include option to show all available measures; 
        %       N.B. already done in graphical app, so no prio
        fprintf(idOut, 'Use "Walking Speed = yes" and so on.\n');
    end
else    
    % save to .mat
    if ~isempty(measures)
        save(fileNameResults, 'measures', 'measuresPerDay');
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
    
    % also save rsults for individual test days to the .txt file
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
    end
    
    fclose(fid);
      
    % save to json
    if saveToJSON
       fileNameResultsJSON = [filepath '/' name '_GA_Results' '.json'];
       toJSON(fileNameResultsJSON, measures, legLength, bimodalFitWalkingSpeed, percentiles, percentilePWS, bmf, ppws);
       for n=1:nDays
          nStr = sprintf ('%02d', n);
          if ~isempty(measuresPerDay(n)) && ~isempty(measuresPerDay(n).WalkingSpeed)
              fileNameResultsJSON = [filepath '/' name '_GA_Results_Day' nStr '.json'];
              toJSON(fileNameResultsJSON, measuresPerDay(n), legLength, ...
                     bimodalFitWalkingSpeedPerDay(n), percentiles, percentilePWSPerDay(n), bmf, ppws);
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

end % function


%% sub functions
function toJSON(fileName, measures, legLength, bimodalFitWalkingSpeed, percentiles, percentilePWS, bmf, ppws)

%% start json
fp = fopen(fileName, 'w');
fprintf(fp, '{\n');

%% parameters
fprintf(fp, '\t"description": "Spatio temporal parameters",\n');
fprintf(fp, '\t"metadata": [\n');
fprintf(fp, '\t\t{"label": "Percentiles", "unit": "None", "values": {"1st": %d, "2nd": %d, "3rd": %d}},\n',...
             percentiles(1), percentiles(2), percentiles(3));
fprintf(fp, '\t\t{"label": "LegLength", "unit": "m", "values": %.3f}\n',...
             legLength);
fprintf(fp, '\t],\n');

%% general measures
if ~isempty(measures)
    fn = fieldnames(measures);
    fprintf(fp, '\t"GeneralMeasures": [\n');
    for i=1:numel(fn)  
        if Contains(fn{i}, "speed")
            unit = "m/s";
        elseif Contains(fn{i}, "length")
            unit = "m";
        else
            unit = "None";
        end
        fprintf(fp, '\t\t{"label": "%s", "unit": "%s", "values": {"%s": %.3f, "%s": %.3f, "%s": %.3f}}',...
                char(fn(i)), unit,...
                "PCTL1", measures.(fn{i})(1),...
                "PCTL2", measures.(fn{i})(2),...
                "PCTL3", measures.(fn{i})(3));
        if i<numel(fn)
            fprintf (fp, ',');
        end
        fprintf(fp, '\n');
    end 
    fprintf(fp, '\t],');
%     if bmf || ppws
%         fprintf(fp, ',');
%     end
    fprintf(fp, '\n');
end

%% bimodal fit
if bmf
    fprintf(fp, '\t"BimodalFitWalkingSpeed": [\n');
    fprintf(fp, '\t\t{"label": "Ashman_D", "unit": "None", "values": %.3f},\n',...
                bimodalFitWalkingSpeed.Ashman_D);
    fprintf(fp, '\t\t{"label": "PeakDensity", "unit": "None", "values": {"1st": %.3f, "2nd": %.3f}},\n',...
                bimodalFitWalkingSpeed.peakDensity(1), bimodalFitWalkingSpeed.peakDensity(2));            
    fprintf(fp, '\t\t{"label": "PeakSpeed", "unit": "m/s", "values": {"1st": %.3f, "2nd": %.3f}}\n',...
                bimodalFitWalkingSpeed.peakSpeed(1), bimodalFitWalkingSpeed.peakSpeed(2));        
    fprintf(fp, '\t],');
%     if ppws
%         fprintf(fp, ',');
%     end
    fprintf(fp, '\n');
end

%% percentile of preferred walking speed
if ppws
    fprintf(fp, '\t"PercentilePreferredWalkingSpeed": [\n');
    fprintf(fp, '\t\t{"label": "PercentilePWS", "unit": "None", "values": %.2f}\n',...
                percentilePWS);
    fprintf(fp, '\t]\n');
end

%% end json
fprintf(fp, "}");
fclose (fp);

end % main function


function bool = Contains (str, pattern)

if exist('contains', 'builtin')
    bool = contains(str, pattern, 'IgnoreCase', true);
else
    if iscell(str)
        bool = ~isempty(strfind(upper(str{1}), upper(pattern)));  
    else
        bool = ~isempty(strfind(upper(str), upper(pattern)));   
    end
end

end % function Contains


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





