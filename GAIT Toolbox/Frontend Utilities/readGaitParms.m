function [params, error] = readGaitParms(file, silent, app)
%% function function [params, error] = readGaitParms(file, silent)
%  help utility for gaitAnalyse and gaitAnalysis (undocumented)

%% 2021, kaass@fbw.vu.nl 
% Last updated: May 2022, kaass@fbw.vu.nl

global guiApp

st = dbstack;
fcnName = st.name;
str = sprintf ("Enter %s().\n", fcnName);
prLog(str, fcnName);

error = false;
params=[];
filename = strrep(file, '\', '/');

getActivity = ~isdeployed; % showing physical activity info is the default 
                           % within the MATLAB-environment

if nargin > 2 && ~isnumeric(app)
    idOut = app;
elseif exist('guiApp', 'var') && ~isempty(guiApp) && ~isnumeric(guiApp)
    idOut = guiApp;
    getActivity = true; % in the GUI-exe, showing activity info is 
                        % also the default
else 
    idOut = 2; % refers to standard error
end
    
if (nargin < 2)
    silent = false;
end
 
defaultEpochLength = 10;

params.minEpochLength                = 5;
params.epochLength                   = defaultEpochLength;
params.skipStartSeconds              = 0;
params.percentiles                   = [20 50 80];
params.calcWalkingSpeed              = false;
params.calcStrideLength              = false;
params.calcStrideRegularityVT        = false;
params.calcStrideRegularityML        = false;
params.calcStrideRegularityAP        = false;
params.calcSampleEntropyVT           = false;
params.calcSampleEntropyML           = false;
params.calcSampleEntropyAP           = false;
params.calcRMSVT                     = false;
params.calcRMSML                     = false;
params.calcRMSAP                     = false;
params.calcIndexHarmonicityVT        = false;
params.calcIndexHarmonicityML        = false;
params.calcIndexHarmonicityAP        = false;
params.calcPowerAtStepFreqVT         = false;
params.calcPowerAtStepFreqML         = false;
params.calcPowerAtStepFreqAP         = false;
params.calcGaitQualityCompositeScore = false;
params.calcBimodalFitWalkingSpeed    = false;
params.calcPercentilePWS             = false;

params.getPhysicalActivityFromClassification = getActivity;
params.minSensorWearTime             = 18; % in hours
params.minValidDaysActivities        =  2;
params.minValidDaysLying             =  3;


if ~nargin 
   [f, d] = uigetfile('.txt', 'Select parameter file');
   if ~file
       str = sprintf('No parameter file selected.');
       prLog(str, fcnName);
       fprintf(idOut, str); 
       return;
   end
   file = [d f];
end


str = fileread(file);
pat = {'[\r\n]+'};
NameValuePairs = strtrim(regexp(str, pat, 'split'));

pat = {'='};
len = size(NameValuePairs{1}, 2);
pair = cell(len, 1);
n=0;
for i=1:len
    if ~isempty(NameValuePairs{1}{i})
        c = NameValuePairs{1}{i}(1);
        if (isstrprop(c, 'alpha') || isstrprop(c, 'digit'))
            n=n+1;
            pair{n} = regexp(NameValuePairs{1}{i}, pat, 'split');
        end    
    end
end


for i=1:n
   try
       name = strtrim(pair{i}{1}(1));
       value = strtrim(pair{i}{1}(2));
   catch
       continue
   end
   bool = Contains(char(value), 'y');
   if Contains(name, 'Seconds') && Contains(name, 'Episode') 
       str = sprintf ('Parameter "%s" in %s is obsolete and no longer used.\n', toString(name), filename);
       prLog (str, fcnName);
       if ~silent
          fprintf(idOut, str);
       end
   elseif Contains(name, 'Epoch') && Contains(name, 'Length')
       params.epochLength = str2double(value);
   elseif Contains(name, 'Skip') && Contains(name, 'Start')
       if Contains (name, 'Sec')    
           params.skipStartSeconds = str2double(value);
       elseif Contains (name, 'Min')
           params.skipStartSeconds = 60*str2double(value);
       elseif Contains(name, 'Hour')
           params.skipStartSeconds = 60*60*str2double(value);
       end 
   elseif Contains(name, 'Classification') && ~Contains(name, 'phys') && ~Contains(name, 'get')
       params.classFile = char(value);
   elseif Contains(name, 'Raw Measure')  
       params.accFile = char(value);
   elseif Contains(name, 'Leg')
       params.legLength = str2double(value);
   elseif Contains(name, 'PWS') || (Contains (name, 'Pref') && Contains (name, 'Speed'))
       params.preferredWalkingSpeed = str2double(value);
       params.calcPercentilePWS = true;
   elseif Contains(name, 'Percentiles')
       params.percentiles = eval(value{1});    
   elseif Contains(name, 'Speed') && ~Contains(name, 'Bimodal')
       params.calcWalkingSpeed = bool;
   elseif Contains(name, 'Stride') && Contains(name, 'Len')
       params.calcStrideLength = bool;
   elseif Contains(name, 'Stride') && Contains(name, 'Reg') && Contains(name, 'VT')
       params.calcStrideRegularityVT = bool;
   elseif Contains(name, 'Stride') && Contains(name, 'Reg') && Contains(name, 'ML')
       params.calcStrideRegularityML = bool;
   elseif Contains(name, 'Stride') && Contains(name, 'Reg') && Contains(name, 'AP')
       params.calcStrideRegularityAP = bool;
   elseif Contains(name, 'Stride') && Contains(name, 'Reg')
       params.calcStrideRegularityVT = bool;
       params.calcStrideRegularityML = bool;
       params.calcStrideRegularityAP = bool;
   elseif Contains(name, 'Entropy') && Contains(name, 'VT')
       params.calcSampleEntropyVT = bool;
   elseif Contains(name, 'Entropy') && Contains(name, 'ML')
       params.calcSampleEntropyML = bool;
   elseif Contains(name, 'Entropy') && Contains(name, 'AP')
       params.calcSampleEntropyAP = bool;
   elseif Contains(name, 'Entropy')
       params.calcSampleEntropyVT = bool;
       params.calcSampleEntropyML = bool;
       params.calcSampleEntropyAP = bool; 
   elseif Contains(name, 'RMS') && Contains(name, 'VT')
       params.calcRMSVT = bool;
   elseif Contains(name, 'RMS') && Contains(name, 'ML')
       params.calcRMSML = bool;
   elseif Contains(name, 'RMS') && Contains(name, 'AP')
       params.calcRMSAP = bool;
   elseif Contains(name, 'RMS')
       params.calcRMSVT = bool;
       params.calcRMSML = bool;
       params.calcRMSAP = bool;
   elseif Contains(name, 'Harmon') && Contains(name, 'VT')
       params.calcIndexHarmonicityVT = bool;
   elseif Contains(name, 'Harmon') && Contains(name, 'ML')
       params.calcIndexHarmonicityML = bool;
   elseif Contains(name, 'Harmon') && Contains(name, 'AP')
       params.calcIndexHarmonicityAP = bool;
   elseif Contains(name, 'Harmon')
       params.calcIndexHarmonicityVT = bool;
       params.calcIndexHarmonicityML = bool;
       params.calcIndexHarmonicityAP = bool;
   elseif ((Contains(name, 'Power') && Contains(name, 'Freq')) || (Contains(name,'Weiss') && Contains(name,'Amp'))) && Contains(name, 'VT') 
       params.calcPowerAtStepFreqVT = bool;
   elseif ((Contains(name, 'Power') && Contains(name, 'Freq')) || (Contains(name,'Weiss') && Contains(name,'Amp'))) && Contains(name, 'ML')
       params.calcPowerAtStepFreqML = bool;
   elseif ((Contains(name, 'Power') && Contains(name, 'Freq')) || (Contains(name,'Weiss') && Contains(name,'Amp'))) && Contains(name, 'AP')
       params.calcPowerAtStepFreqAP = bool;
   elseif ((Contains(name, 'Power') && Contains(name, 'Freq')) || (Contains(name,'Weiss') && Contains(name,'Amp')))
       params.calcPowerAtStepFreqVT = bool;
       params.calcPowerAtStepFreqML = bool;
       params.calcPowerAtStepFreqAP = bool;
   elseif Contains(name, 'Quality') || Contains(name, 'Composite')
       params.calcGaitQualityCompositeScore = bool;
   elseif Contains(name, 'Bimodal') 
       params.calcBimodalFitWalkingSpeed = bool;
   elseif (Contains(name, 'phys') || Contains(name, 'get')) && Contains(name, 'activit') 
       params.getPhysicalActivityFromClassification = bool; 
   elseif Contains(name, 'wear')
       params.minSensorWearTime = str2double(value);
   elseif Contains(name, 'valid')
       if Contains(name, 'ly')
           params.minValidDaysLying = str2double(value);
       else
           params.minValidDaysActivities = str2double(value);
       end
   else
       if ~silent
          if ~isnumeric(idOut)    
              idOut.pError = true;
          end
          str = sprintf ('Unknown parameter "%s" in %s.\n', toString(name), filename);
          fprintf(idOut, str);
          prLog (str, fcnName);
       end
       error = true;
   end
end % for


if params.epochLength < params.minEpochLength
    str1 = sprintf('Invalid epoch length in %s (should be at least %ds);', filename, params.minEpochLength);
    str2 = sprintf('default value of %ds will be used instead.\n', defaultEpochLength);
    params.epochLength = defaultEpochLength;
    fprintf(idOut, [str1, '\n', str2]);
    prLog([str1, ' ', str2], fcnName);

end

if params.minValidDaysLying < params.minValidDaysActivities
    str1 = sprintf('Minimal valid lying days (%d) should not subseed that of the activities (%d).\n', params.minValidDaysLying, params.minValidDaysActivities);
    str2 = sprintf('New value of %d will be used instead.\n', params.minValidDaysActivities);
    params.minValidDaysLying = params.minValidDaysActivities;
    fprintf(idOut, str1);
    fprintf(idOut, str2); 
    prLog(str1, fcnName);
    prLog(str2, fcnName);
end

str = sprintf ("Leave %s().\n", fcnName);
prLog(str, fcnName);

end % function

%% sun functions
function strout = toString(strin)

if iscell(strin)
    strout = strin{1};
else
    strout = strin;
end

end


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

end

