function [params, error] = getMissingGaitParms(old_params)
%% function [params, error] = getMissingGaitParms(old_params)
%  help utility for gaitAnalyse (undocumented)

%% 2021, kaass@fbw.vu.nl 
% Last updated: Dec 2021, kaass@fbw.vu.nl

global guiApp

if exist('guiApp', 'var') && ~isempty(guiApp) && ~isnumeric(guiApp)
    idOut = guiApp;
    idOut.pError = true;  % will be reset if end of file is reached without problems
    ask1  = true; 
    ask2  = false; % does not work for GUI App yet
else    
    idOut = 2; % refers to standard error
    ask1 = true;
    ask2 = true;
end

params = old_params;
error  = true; % will be set to false if of end of file is reached without problems


%% some parameters require a proper value from the user
if ~isfield(params, 'classFile')
    if ask1
        [file,dir] = uigetfile('.csv', 'Select classification file');
        if ~file
            fprintf (idOut, '\n*** Error: No classification file (*.csv) selected. ***\n');
            return;
        end
    else
        fprintf (idOut, '\n*** Error: No classification file (*.csv) specified. ***\n');
        return;
    end
    params.classFile = [dir file];
end


if ~isfield(params, 'accFile')
    if ask1
        [file, dir] = uigetfile('*.3ac;*.omx', 'Select raw measurement file');
        if ~file
            fprintf (idOut, '\n*** Error: No raw measurement file (*.3ac or *.omx) selected. ***\n');
            return;
        end
    else    
        fprintf (idOut, '\n*** Error: No raw measurement file (*.3ac or *.omx) specified. ***\n');
        return;
    end
    params.accFile = [dir file];
end


if ~isfield(params, 'legLength')
    if ask2
        params.legLength = input('Leg length (in meters)? ');
    end
    if ~isfield(params, 'legLength') || isempty(params.legLength)
        fprintf(idOut, '\n*** Error: No leg length given! ***\n');
        return;
    end
end


%% optional parameters just get a default value
if ~isfield(params, 'epochLength')
    params.epochLength = 10;
end

if ~isfield(params, 'skipStartSeconds')
    params.skipStartSeconds = 0;
end

if isfield(params, 'percentiles')
    if size(params.percentiles) ~= 3
        fprintf(idOut, '\n*** Error: Percentiles should be an array of length 3! ***\n');
        return;
    end   
else
    params.percentiles = [10 50 90];
end

if ~isfield(params, 'getPhysicalActivityFromClassification')
    params.getPhysicalActivityFromClassification = false;
end    
if ~isfield(params, 'minSensorWearTime')
    params.minSensorWearTime = 18;
end    
if ~isfield(params, 'minValidDaysActivities')
    params.minValidDaysActivities = 2;
end    
if ~isfield(params, 'minValidDaysLying')
    params.minValidDaysLying = 3;
end      
    
error = false;
if ~isnumeric(idOut)
    idOut.pError = false;
end


end

