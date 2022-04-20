function activityStruct = getActivity(classificationFile, varargin)
%% function activityStruct = getActivity(classificationFile, [OPTIONS])
% Get physical activity, inclding the main transitions between activities,
% based on the classification file from McRoberts.
%
% INPUT 
%   classificationFile: full path to McRoberts' classification (*.csv) file
%
% OPTIONS
%
%   'minSensorWearTime'       hours  (defaults to 18; consider 12
%                                     if sensors are not worn at night)
%   'minValidDaysActivities'  days   (defaults to 2)
%   'minValidDaysLying        days   (defaults to 3)
%
%
% OUTPUT
%  activityStruct: structure containing all relevant information
%                    stridesPerDay        
%                    walkingDurationPerDay    
%                    standingDurationPerDay     
%                    sittingDurationPerDay     
%                    cyclingDurationPerDay
%                    stairwalkingDurationPerDay
%                    lyingDurationPerDay
%                    unclassifiedDurationPerDay 
%                    walkingEpisodesPerDay
%                    standingEpisodesPerDay
%                    sittingEpisodesPerDay
%                    stairwalkingEpisodesPerDay
%                    cyclingEpisodesPerDay
%                    lyingEpisodesPerDay
%                    unclassifiedEpisodesPerDay
%                    numberOfTransitionsPerDay
%                    numberOfValidDays
%                    numberOfTestDays
%                    sensorsNotWorn 
%                    sensorsWorn
%                    sensorsTotal
%                    transitions
%
%
%% 2022, kaass@fbw.vu.nl
% Last updated: April 2022, kaass@fbw.vu.nl


%% init / settings
activityStruct=[];

showTotalActivityDuration = false; % just for testing; should be false

if (nargin < 1)    
    [file,dir] = uigetfile('.csv', 'Select classification file');
    if ~file
        fprintf (2, '\n*** Error: No classification file (*.csv) selected. ***\n');
        return;
    end
    classificationFile = [dir file];
end

% default values
minSensorWearTime      = 18; % minimum hours of sensor wear time to include 
                             % a testday as a valid day; if instructed to 
                             % wear the accelerometer at night, consider 18
                             % hours, otherwise 12 hours
minValidDaysActivities = 2;
minValidDaysLying      = 3;

% parse optional parameters
validHoursLevel = @(x) isnumeric(x) && isscalar(x) && (x >= 0) && (x<=24);
validDaysLevel  = @(x) isnumeric(x) && isscalar(x) && (x >= 1);
p = inputParser;
addParameter(p, 'minSensorWearTime',      minSensorWearTime, validHoursLevel);
addParameter(p, 'minValidDaysActivities', minValidDaysActivities, validDaysLevel);
addParameter(p, 'minValidDaysLying',      minValidDaysLying, validDaysLevel);
parse(p,varargin{:});

minSensorWearTime      = p.Results.minSensorWearTime;
minValidDaysActivities = p.Results.minValidDaysActivities;
minValidDaysLying      = p.Results.minValidDaysLying;

if minValidDaysLying < minValidDaysActivities
    fprintf(idOut, 'Minimal valid lying days (%f) should not subseed that of the activities (%f).\n', minValidDaysLying, minValidDaysActivities);
    fprintf(idOut, 'New value of %f will be used instead.\n', minValidDaysActivities);
    minValidDaysLying = minValidDaysActivities;
end

%% read classification list
data = fileread(classificationFile);
if contains(data, ',')
   data = strrep(data, ',', '.');
   newFile = [classificationFile '_tmp.csv'];
   fid = fopen(newFile, 'w+');
   fwrite(fid, data, 'char');
   fclose(fid);
   table = readtable(newFile, 'delimiter', ';', 'TreatAsEmpty',{'.','NA','N/A'});
   delete(newFile);
else
   table = readtable(classificationFile,'delimiter', ';', 'TreatAsEmpty',{'.','NA','N/A'});
end
clear data

activities = {'walking', 'standing', 'sitting', 'lying', 'cycling', 'stair_walking', 'shuffling'};
nAct = length(activities);


%% show total activity duration (i.e., summed over all days); for testing only
if showTotalActivityDuration
    duration = zeros(n, 0);
    for act = 1 : nAct
        idx = strcmp(table{:,4}, activities{act}) == 1;
        % only use episodes that are at least as long as minEpisodeLength
        % idx = idx %% & table.duration >= minEpisodeLength;
        duration(act) = sum(table.duration(idx));
        d = string(seconds(duration(act)), 'hh:mm:ss');
        switch activities{act}
            case 'walking'
                fprintf ('Walking:       %s\n', d);
            case 'shuffling'
                fprintf ('Shuffling:     %s\n', d);
            case 'standing'
                fprintf ('Standing:      %s\n', d);
            case 'sitting'
                fprintf ('Sitting:       %s\n', d);
            case 'stair_walking'
                fprintf ('Stair walking: %s\n', d);
            case 'cycling'
                fprintf ('Cycling:       %s\n', d);
            case 'lying'
                fprintf ('Lying:         %s\n', d);
            otherwise
                fprintf ('Unknown\n');
        end
    end
end

%% prepare for transitions
[table, aborted] = getTransitions(table);
if (aborted)
    return;
end
% find the order of the activities (e.g. WALKING is set to 1 if
% 'walking' happens to be the first entry in activities)
% this is used to fill the transitions matrix further on
for act = 1 : nAct
    switch activities{act}
        case 'walking'
            WALKING = act;
        case 'shuffling'
            SHUFFLING = act;
        case 'standing'
            STANDING = act;
        case 'sitting'
            SITTING = act;
        case 'cycling'
            CYCLING = act;
        case 'stair_walking'
            STAIRS = act;
        case 'lying'
            LYING = act;
        otherwise
            % do nothing
    end
end


%% calculate measures
n = length(table.start);
days = NaT;
idxDays = NaN;
j = 1;
for i = 1 : n
    date = table.start(i);
    day = datetime([date.Year, date.Month, date.Day] ,'InputFormat','yyyy-MM-dd');
    if i==1 
        days(1,1) = day;
        idxDays(1,1)  = 1;
    elseif day ~= days(j,1)
        idxDays(j,2) = i-1;
        j=j+1;
        days(j,1) = day;
        idxDays(j,1) = i;       
    end
    if (i==n)
        idxDays(j,2) = i;
    end
    if mod(i, 500) == 0
        if checkAbortFromGui() 
            return;
        end
    end
end

if isempty(days)
    numberOfValidDays          = NaN;
    testDays                   = NaN;
    valid                      = NaN;
    strides                    = NaN;
    walkingDuration            = NaN;
    shufflingDuration          = NaN;
    standingDuration           = NaN;
    sittingDuration            = NaN;
    stairwalkingDuration       = NaN;
    cyclingDuration            = NaN;
    lyingDuration              = NaN;
    walkingEpisodes            = NaN;
    shufflingEpisodes          = NaN;
    standingEpisodes           = NaN;
    sittingEpisodes            = NaN;
    stairwalkingEpisodes       = NaN;
    cyclingEpisodes            = NaN;
    lyingEpisodes              = NaN;
    numberOfTransitions        = NaN;
    stridesAvg                 = NaN;
    walkingDurationAvg         = NaN;
    shufflingDurationAvg       = NaN;
    standingDurationAvg        = NaN;
    sittingDurationAvg         = NaN;
    stairwalkingDurationAvg    = NaN;
    cyclingDurationAvg         = NaN;
    lyingDurationAvg           = NaN;
    walkingEpisodesAvg         = NaN;
    shufflingEpisodesAvg       = NaN;
    standingEpisodesAvg        = NaN;
    sittingEpisodesAvg         = NaN;
    stairwalkingEpisodesAvg    = NaN;
    cyclingEpisodesAvg         = NaN;
    lyingEpisodesAvg           = NaN;
    numberOfTransitionsAvg     = NaN;
    sensorsNotWorn             = NaN;
    sensorsWorn                = NaN;
    sensorsTotal               = NaN;
    transitions                = NaN(length(activities));
else
    numberOfValidDays          = 0;
    testDays                   = length(days);
    valid                      = false(testDays, 1);
    strides                    = zeros(testDays, 1);
    walkingDuration            = zeros(testDays, 1);
    shufflingDuration          = zeros(testDays, 1);
    standingDuration           = zeros(testDays, 1);
    sittingDuration            = zeros(testDays, 1);
    stairwalkingDuration       = zeros(testDays, 1);
    cyclingDuration            = zeros(testDays, 1);
    lyingDuration              = zeros(testDays, 1);
    walkingEpisodes            = zeros(testDays, 1);
    shufflingEpisodes          = zeros(testDays, 1);
    standingEpisodes           = zeros(testDays, 1);
    sittingEpisodes            = zeros(testDays, 1);
    stairwalkingEpisodes       = zeros(testDays, 1);
    cyclingEpisodes            = zeros(testDays, 1);
    lyingEpisodes              = zeros(testDays, 1);
    numberOfTransitions        = zeros(testDays, 1);
    stridesAvg                 = 0;
    walkingDurationAvg         = 0;
    shufflingDurationAvg       = 0;
    standingDurationAvg        = 0;
    sittingDurationAvg         = 0;
    stairwalkingDurationAvg    = 0;
    cyclingDurationAvg         = 0;
    lyingDurationAvg           = 0;
    walkingEpisodesAvg         = 0;
    shufflingEpisodesAvg       = 0;
    standingEpisodesAvg        = 0;
    sittingEpisodesAvg         = 0;
    stairwalkingEpisodesAvg    = 0;
    cyclingEpisodesAvg         = 0;
    lyingEpisodesAvg           = 0;
    numberOfTransitionsAvg     = 0;
    sensorsNotWorn             = zeros(testDays, 1);
    sensorsWorn                = zeros(testDays, 1);
    sensorsTotal               = zeros(testDays, 1);
    transitions                = zeros(testDays, length(activities));
    transitionsAvg             = zeros(length(activities));

               
    for i = 1:testDays        
        if checkAbortFromGui()
            return;
        end
        idxWorn           = idxDays(i,1)-1 + find(table.class(idxDays(i,1) : idxDays(i,2)) ~= "not_worn");
        idxNotWorn        = idxDays(i,1)-1 + find(table.class(idxDays(i,1) : idxDays(i,2)) == "not_worn");
        wornTime          = sum(table.duration(idxWorn))   /3600; % in hours
        notWornTime       = sum(table.duration(idxNotWorn))/3600; % in hours
        sensorsWorn(i)    = wornTime;
        sensorsNotWorn(i) = notWornTime;
        sensorsTotal(i)   = wornTime + notWornTime;
        if wornTime >= minSensorWearTime
            valid(i) = true;
            strides(i) = floor(sum(table.steps(idxWorn)) / 2);
            idxAct = idxWorn(table.class(idxWorn) == "walking");
            if (~isempty(idxAct))
                walkingDuration(i) = sum(table.duration(idxAct))/3600;   
                % note: sum(diff(idxAct)~=1) takes care that consecutive 
                %       episodes are counted as a single episode   
                walkingEpisodes(i) = sum(diff(idxAct)~=1); 
            end
            idxAct = idxWorn(table.class(idxWorn) == "shuffling");
            if (~isempty(idxAct))
                shufflingDuration(i) = sum(table.duration(idxAct))/3600;
                shufflingEpisodes(i) = sum(diff(idxAct)~=1);
            end
            idxAct = idxWorn(table.class(idxWorn) == "standing");
            if (~isempty(idxAct))
                standingDuration(i) = sum(table.duration(idxAct))/3600;
                standingEpisodes(i) = sum(diff(idxAct)~=1);
            end
            idxAct = idxWorn(table.class(idxWorn) == "sitting");
            if (~isempty(idxAct))
                sittingDuration(i) = sum(table.duration(idxAct))/3600;
                sittingEpisodes(i) = sum(diff(idxAct)~=1);
            end
            idxAct = idxWorn(table.class(idxWorn) == "stair_walking");
            if (~isempty(idxAct))
                stairwalkingDuration(i) = sum(table.duration(idxAct))/3600;
                stairwalkingEpisodes(i) = sum(diff(idxAct)~=1);
            end
            idxAct = idxWorn(table.class(idxWorn) == "cycling");
            if (~isempty(idxAct))
                cyclingDuration(i) = sum(table.duration(idxAct))/3600;
                cyclingEpisodes(i) = sum(diff(idxAct)~=1);
            end
            idxAct = idxWorn(table.class(idxWorn) == "lying");
            if (~isempty(idxAct))
                lyingDuration(i) = sum(table.duration(idxAct))/3600;
                lyingEpisodes(i) = sum(diff(idxAct)~=1);
            end
          
            numberOfTransitions(i) = length(find(table.transition_label(idxWorn)~=0));
            
            transitions(i, WALKING,   SHUFFLING) = length(find(strcmp(table.transition(idxWorn), 'walk2shuffle')));
            transitions(i, WALKING,   STANDING)  = length(find(strcmp(table.transition(idxWorn), 'walk2stand')));
            transitions(i, WALKING,   SITTING)   = length(find(strcmp(table.transition(idxWorn), 'walk2sit')));
            transitions(i, WALKING,   CYCLING)   = length(find(strcmp(table.transition(idxWorn), 'walk2cycle')));
            transitions(i, WALKING,   STAIRS)    = length(find(strcmp(table.transition(idxWorn), 'walk2stairs')));
            transitions(i, WALKING,   LYING)     = length(find(strcmp(table.transition(idxWorn), 'walk2lie')));
            
            transitions(i, SHUFFLING, WALKING)   = length(find(strcmp(table.transition(idxWorn), 'shuffle2walk')));
            transitions(i, SHUFFLING, STANDING)  = length(find(strcmp(table.transition(idxWorn), 'shuffle2stand')));
            transitions(i, SHUFFLING, SITTING)   = length(find(strcmp(table.transition(idxWorn), 'shuffle2sit')));
            transitions(i, SHUFFLING, CYCLING)   = length(find(strcmp(table.transition(idxWorn),'shuffle2cycle')));
            transitions(i, SHUFFLING, STAIRS)    = length(find(strcmp(table.transition(idxWorn), 'shuffle2stairs')));
            transitions(i, SHUFFLING, LYING)     = length(find(strcmp(table.transition(idxWorn), 'shuffle2lie')));
            
            transitions(i, STANDING,  WALKING)   = length(find(strcmp(table.transition(idxWorn), 'stand2walk')));
            transitions(i, STANDING,  SHUFFLING) = length(find(strcmp(table.transition(idxWorn), 'stand2shuffle')));
            transitions(i, STANDING,  SITTING)   = length(find(strcmp(table.transition(idxWorn), 'stand2sit')));
            transitions(i, STANDING,  CYCLING)   = length(find(strcmp(table.transition(idxWorn), 'stand2cycle')));
            transitions(i, STANDING,  STAIRS)    = length(find(strcmp(table.transition(idxWorn), 'stand2stairs')));
            transitions(i, STANDING,  LYING)     = length(find(strcmp(table.transition(idxWorn), 'stand2lie')));
            
            transitions(i, SITTING,   WALKING)   = length(find(strcmp(table.transition(idxWorn), 'sit2walk')));
            transitions(i, SITTING,   SHUFFLING) = length(find(strcmp(table.transition(idxWorn), 'sit2shuffle')));
            transitions(i, SITTING,   STANDING)  = length(find(strcmp(table.transition(idxWorn), 'sit2stand')));
            transitions(i, SITTING,   CYCLING)   = length(find(strcmp(table.transition(idxWorn), 'sit2cycle')));
            transitions(i, SITTING,   STAIRS)    = length(find(strcmp(table.transition(idxWorn), 'sit2stairs')));
            transitions(i, SITTING,   LYING)     = length(find(strcmp(table.transition(idxWorn), 'sit2lie')));
            
            transitions(i, CYCLING,   WALKING)   = length(find(strcmp(table.transition(idxWorn), 'cycle2walk')));
            transitions(i, CYCLING,   SHUFFLING) = length(find(strcmp(table.transition(idxWorn), 'cycle2shuffle')));
            transitions(i, CYCLING,   STANDING)  = length(find(strcmp(table.transition(idxWorn), 'cycle2stand')));
            transitions(i, CYCLING,   SITTING)   = length(find(strcmp(table.transition(idxWorn), 'cycle2sit')));
            transitions(i, CYCLING,   STAIRS)    = length(find(strcmp(table.transition(idxWorn), 'cycle2stairs')));
            transitions(i, CYCLING,   LYING)     = length(find(strcmp(table.transition(idxWorn), 'cycle2lie')));
            
            transitions(i, STAIRS,    WALKING)   = length(find(strcmp(table.transition(idxWorn), 'stairs2walk')));
            transitions(i, STAIRS,    SHUFFLING) = length(find(strcmp(table.transition(idxWorn), 'stairs2shuffle')));
            transitions(i, STAIRS,    STANDING)  = length(find(strcmp(table.transition(idxWorn), 'stairs2stand')));
            transitions(i, STAIRS,    SITTING)   = length(find(strcmp(table.transition(idxWorn), 'stairs2sit')));
            transitions(i, STAIRS,    CYCLING)   = length(find(strcmp(table.transition(idxWorn), 'stairs2cycle')));
            transitions(i, STAIRS,    LYING)     = length(find(strcmp(table.transition(idxWorn), 'stairs2lie')));
            
            transitions(i, LYING,     WALKING)   = length(find(strcmp(table.transition(idxWorn), 'lie2walk')));
            transitions(i, LYING,     SHUFFLING) = length(find(strcmp(table.transition(idxWorn), 'lie2shuffle')));
            transitions(i, LYING,     STANDING)  = length(find(strcmp(table.transition(idxWorn), 'lie2stand')));
            transitions(i, LYING,     SITTING)   = length(find(strcmp(table.transition(idxWorn), 'lie2sit')));
            transitions(i, LYING,     CYCLING)   = length(find(strcmp(table.transition(idxWorn), 'lie2cycle')));
            transitions(i, LYING,     STAIRS)     = length(find(strcmp(table.transition(idxWorn), 'lie2stairs')));
            numberOfValidDays = numberOfValidDays + 1;
        end
    end
    
    if numberOfValidDays >= minValidDaysActivities
        stridesAvg              = sum(strides,              'omitnan') / numberOfValidDays;
        walkingDurationAvg      = sum(walkingDuration,      'omitnan') / numberOfValidDays;
        shufflingDurationAvg    = sum(shufflingDuration,    'omitnan') / numberOfValidDays;
        standingDurationAvg     = sum(standingDuration,     'omitnan') / numberOfValidDays;
        sittingDurationAvg      = sum(sittingDuration,      'omitnan') / numberOfValidDays;
        stairwalkingDurationAvg = sum(stairwalkingDuration, 'omitnan') / numberOfValidDays; 
        cyclingDurationAvg      = sum(cyclingDuration,      'omitnan') / numberOfValidDays;
        walkingEpisodesAvg      = sum(walkingEpisodes,      'omitnan') / numberOfValidDays;
        shufflingEpisodesAvg    = sum(shufflingEpisodes,    'omitnan') / numberOfValidDays;
        standingEpisodesAvg     = sum(standingEpisodes,     'omitnan') / numberOfValidDays;
        sittingEpisodesAvg      = sum(sittingEpisodes,      'omitnan') / numberOfValidDays;
        cyclingEpisodesAvg      = sum(cyclingEpisodes,      'omitnan') / numberOfValidDays;
        stairwalkingEpisodesAvg = sum(stairwalkingEpisodes, 'omitnan') / numberOfValidDays; 
        numberOfTransitionsAvg  = sum(numberOfTransitions,  'omitnan') / numberOfValidDays;
        transitionsAvg          = squeeze(sum(transitions,  'omitnan') ./ numberOfValidDays);

        if numberOfValidDays >= minValidDaysLying
            lyingDurationAvg = sum(lyingDuration(~isnan(lyingDuration))) / numberOfValidDays;
            lyingEpisodesAvg = sum(lyingEpisodes(~isnan(lyingEpisodes))) / numberOfValidDays;
        else
            lyingDurationAvg = NaN;
            lyingEpisodesAvg = NaN;
        end
    end
end


%% save output

% add row and column names to transitionAvg table
if ~isnan(sum(sum(transitionsAvg)))
    a = cellstr(' '); 
    for i=1:nAct
        if strcmp(activities(i), 'shuffling') == 1
            a = [a; {'unclassified'}];
        else
            a = [a; cellstr(activities(i))];
        end
    end   
    trans = vertcat(a', [a(2:end) num2cell(round(transitionsAvg))]);
else
    trans = NaN;
end
transitionsAvg = trans;


% add row and column names to transitions table
if numberOfValidDays > 0
    nt = size(transitions, 1);
    na = length(activities);
    trans = cell(nt, na+1, na+1);
    for n = 1:nt
        transition = squeeze(transitions(n,:,:));
        if ~isnan(sum(sum(transition)))
            a = cellstr(' ');
            for i=1:nAct
                if strcmp(activities(i), 'shuffling') == 1
                    a = [a; {'unclassified'}];
                else
                    a = [a; cellstr(activities(i))];
                end
            end
            trans(n,:,:) = vertcat(a', [a(2:end) num2cell(transition)]);
        end
    end
else
    trans = [];
end
transitions = trans;

activityStruct.numberOfValidDays       = numberOfValidDays;
activityStruct.numberOfTestDays        = testDays;
activityStruct.sensorsNotWorn          = sensorsNotWorn;
activityStruct.sensorsWorn             = sensorsWorn;
activityStruct.sensorsTotal            = sensorsTotal;

activityStruct.valid                   = valid;
activityStruct.stridesAvg              = round(stridesAvg);
activityStruct.walkingDurationAvg      = walkingDurationAvg;
activityStruct.standingDurationAvg     = standingDurationAvg;
activityStruct.sittingDurationAvg      = sittingDurationAvg;
activityStruct.cyclingDurationAvg      = cyclingDurationAvg;
activityStruct.stairwalkingDurationAvg = stairwalkingDurationAvg;
activityStruct.lyingDurationAvg        = lyingDurationAvg;
activityStruct.unclassifiedDurationAvg = shufflingDurationAvg;
activityStruct.walkingEpisodesAvg      = round(walkingEpisodesAvg);
activityStruct.standingEpisodesAvg     = round(standingEpisodesAvg);
activityStruct.sittingEpisodesAvg      = round(sittingEpisodesAvg);
activityStruct.stairwalkingEpisodesAvg = round(stairwalkingEpisodesAvg);
activityStruct.cyclingEpisodesAvg      = round(cyclingEpisodesAvg);
activityStruct.lyingEpisodesAvg        = round(lyingEpisodesAvg);
activityStruct.unclassifiedEpisodesAvg = round(shufflingEpisodesAvg);

activityStruct.strides                 = strides;
activityStruct.walkingDuration         = walkingDuration;
activityStruct.standingDuration        = standingDuration;
activityStruct.sittingDuration         = sittingDuration;
activityStruct.cyclingDuration         = cyclingDuration;
activityStruct.stairwalkingDuration    = stairwalkingDuration;
activityStruct.lyingDuration           = lyingDuration;
activityStruct.unclassifiedDuration    = shufflingDuration;
activityStruct.walkingEpisodes         = walkingEpisodes;
activityStruct.standingEpisodes        = standingEpisodes;
activityStruct.sittingEpisodes         = sittingEpisodes;
activityStruct.stairwalkingEpisodes    = stairwalkingEpisodes;
activityStruct.cyclingEpisodes         = cyclingEpisodes;
activityStruct.lyingEpisodes           = lyingEpisodes;
activityStruct.unclassifiedEpisodes    = shufflingEpisodes;

activityStruct.numberOfTransitions     = numberOfTransitions;
activityStruct.numberOfTransitionsAvg  = round(numberOfTransitionsAvg);
activityStruct.transitions             = transitions;
activityStruct.transitionsAvg          = transitionsAvg;


end % function


function [activityTable, aborted] = getTransitions(activityTable)
%% activityTable = getTransitions(activityTable)
% count the number of transitions
% input:  activity table without transition info
% output: activity table with transtion info added
% author: YGZ/Kaass

aborted = false;
for row = 1 : size(activityTable, 1)    
    
    if mod(row, 500) == 0
        if checkAbortFromGui() 
            aborted = true;
            return;
        end
    end
    if strcmp(activityTable.class(row),'walking')
        activityTable.class_label(row,1)= 1;        
    elseif strcmp(activityTable.class(row),'sitting')
        activityTable.class_label(row,1)= 2;        
    elseif strcmp(activityTable.class(row),'standing')
        activityTable.class_label(row,1)= 4;        
    elseif strcmp(activityTable.class(row),'shuffling')
        activityTable.class_label(row,1)= 8;
    elseif strcmp(activityTable.class(row),'cycling')
        activityTable.class_label(row,1)= 16;
    elseif strcmp(activityTable.class(row),'stair_walking')
        activityTable.class_label(row,1)= 32;
    elseif strcmp(activityTable.class(row),'lying')
        activityTable.class_label(row,1)= 64;
    else
        activityTable.class_label(row,1)= nan(1);
    end
end

activityTable.transition_label = zeros(size(activityTable,1),1);
activityTable.transition_label(1,1)     = 0;
activityTable.transition_label(2:end,1) = diff(activityTable.class_label);
activityTable.transition_label(isnan(activityTable.transition_label)) = 0;

for row = 1:size(activityTable.transition_label,1)
    
    if mod(row, 500) == 0
        if checkAbortFromGui() 
            aborted = true;
            return;
        end
    end
    
    if activityTable.transition_label(row,1) == 1
        activityTable.transition(row,1) = cellstr('walk2sit');
    elseif activityTable.transition_label(row,1)== -1
        activityTable.transition(row,1) = cellstr('sit2walk');
    elseif activityTable.transition_label(row,1)== 2
        activityTable.transition(row,1) = cellstr('sit2stand');
    elseif activityTable.transition_label(row,1)== -2
        activityTable.transition(row,1) = cellstr('stand2sit');
    elseif activityTable.transition_label(row,1) == 3
        activityTable.transition(row,1) = cellstr('walk2stand');
    elseif activityTable.transition_label(row,1)== -3
        activityTable.transition(row,1) = cellstr('stand2walk');
    elseif activityTable.transition_label(row,1)== 4
        activityTable.transition(row,1) = cellstr('stand2shuffle');
    elseif activityTable.transition_label(row,1)== -4
        activityTable.transition(row,1) = cellstr('shuffle2stand');
    elseif activityTable.transition_label(row,1)== 6
        activityTable.transition(row,1) = cellstr('sit2shuffle');
    elseif activityTable.transition_label(row,1)== -6
        activityTable.transition(row,1) = cellstr('shuffle2sit');
    elseif activityTable.transition_label(row,1)== 7
        activityTable.transition(row,1) = cellstr('walk2shuffle');
    elseif activityTable.transition_label(row,1)== -7
        activityTable.transition(row,1) = cellstr('shuffle2walk');
    elseif activityTable.transition_label(row,1)== 8
        activityTable.transition(row,1) = cellstr('cycle2shuffle');
    elseif activityTable.transition_label(row,1)== -8
        activityTable.transition(row,1) = cellstr('shuffle2cycle');
    elseif activityTable.transition_label(row,1)== 12
        activityTable.transition(row,1) = cellstr('cycle2stand');
    elseif activityTable.transition_label(row,1)== -12
        activityTable.transition(row,1) = cellstr('stand2cycle');
    elseif activityTable.transition_label(row,1)== 14
        activityTable.transition(row,1) = cellstr('cycle2sit');
    elseif activityTable.transition_label(row,1)== -14
        activityTable.transition(row,1) = cellstr('sit2cycle');
    elseif activityTable.transition_label(row,1)== 15
        activityTable.transition(row,1) = cellstr('cycle2walk');
    elseif activityTable.transition_label(row,1)== -15
        activityTable.transition(row,1) = cellstr('walk2cycle');
    elseif activityTable.transition_label(row,1)== 16
        activityTable.transition(row,1) = cellstr('stairs2cycle');
    elseif activityTable.transition_label(row,1)== -16
        activityTable.transition(row,1) = cellstr('cycle2stairs');
    elseif activityTable.transition_label(row,1)== 24
        activityTable.transition(row,1) = cellstr('stairs2shuffle');
    elseif activityTable.transition_label(row,1)== -24
        activityTable.transition(row,1) = cellstr('shuffle2stairs');
    elseif activityTable.transition_label(row,1)== 28
        activityTable.transition(row,1) = cellstr('stairs2stand');
    elseif activityTable.transition_label(row,1)== -28
        activityTable.transition(row,1) = cellstr('stand2stairs');
    elseif activityTable.transition_label(row,1)== 30
        activityTable.transition(row,1) = cellstr('stairs2sit');
    elseif activityTable.transition_label(row,1)== -30
        activityTable.transition(row,1) = cellstr('sit2stairs');
    elseif activityTable.transition_label(row,1)== 31
        activityTable.transition(row,1) = cellstr('stairs2walk');
    elseif activityTable.transition_label(row,1)== -31
        activityTable.transition(row,1) = cellstr('walk2stairs');
    elseif activityTable.transition_label(row,1)== 32
        activityTable.transition(row,1) = cellstr('lie2stairs');
    elseif activityTable.transition_label(row,1)== -32
        activityTable.transition(row,1) = cellstr('stairs2lie');
    elseif activityTable.transition_label(row,1)== 48
        activityTable.transition(row,1) = cellstr('lie2cycle');
    elseif activityTable.transition_label(row,1)== -48
        activityTable.transition(row,1) = cellstr('cycle2lie');
    elseif activityTable.transition_label(row,1)== 56
        activityTable.transition(row,1) = cellstr('lie2shuffle');
    elseif activityTable.transition_label(row,1)== -56
        activityTable.transition(row,1) = cellstr('shuffle2lie');
    elseif activityTable.transition_label(row,1)== 60
        activityTable.transition(row,1) = cellstr('lie2stand');
    elseif activityTable.transition_label(row,1)== -60
        activityTable.transition(row,1) = cellstr('stand2lie');
    elseif activityTable.transition_label(row,1)== 62
        activityTable.transition(row,1) = cellstr('lie2sit');
    elseif activityTable.transition_label(row,1)== -62
        activityTable.transition(row,1) = cellstr('sit2lie');
    elseif activityTable.transition_label(row,1)== 63
        activityTable.transition(row,1) = cellstr('lie2walk');
    elseif activityTable.transition_label(row,1)== -63
        activityTable.transition(row,1) = cellstr('walk2lie');    
    end
    
end

end % function












