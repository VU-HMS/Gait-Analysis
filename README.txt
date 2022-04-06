GAIT Toolbox

The GAIT toolbox is a collection of MATLAB routines to estimate gait measures
from raw acceleration data.


Instructions

Include the "GAIT Toolbox" folder incl. its sub folders to your MATLAB path
("Set Path" can be found in MATLAB's ENVIRONMENT tool menu).

If the path is set, you can run gaitAnalysis (graphical tool, see PDF-manual in
the doc folder), or process a single input file from the command line through 
gaitAnalyse (see below). gaitAnalyseMany is a simple example how to run 
gaitAnalyse mulitiple times with different input files.


Contents

Folder "GAIT Toolbox/Frondend utilities" contains utilities used by gaitAnalyse
to parse input files, read the measurement data (using McRoberts code), and
calculate and present the gait estimates (using the algorithms in the below two
folders).

Folder "GAIT Toolbox/Gait Quality Estimates/" contains most of the algorithms.

Folder "GAIT Toolbox/Get Aggregate Values/" contains utilities to collect the
calculated values.

Folder "GAIT Toolbox/GUI utilities" contains utilities used by the graphical
tool as well as some utilities to redirect console output to the grahical tool
(warning: editing these files can easily break the graphical tool).

Folder "GAIT Toolbox/OMXreadfiles/" contains the McRobert's utilities to read
the raw measurment files.

Folder "exe" contains files to install executable versions of gaitAnalysis
(graphical tool) and gaitAnalyse (console program; run gaitAnalyse -help
from the command prompt to see how to use). They will download and install the
appropriate MATLAB runtime system if needed.


Main function

function gaitAnalyse (parametersFile, [OPTIONS])

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
%         - if 'overwriteFiles' is specified, above three options are
%           ignored.


Examples

If called with no input parameters, a popup will appear to choose a 
parameter file (or individual input files if no parameter file is chosen):
   gaitAnalyse

To process 'DATA/GaitParams.txt' and recalculate everything, use either:
   gaitAnalyse("DATA/GaitParams.txt", 'overwriteFiles', 3) or
   gaitAnalyse("DATA/GaitParams.txt", 'overwriteEpisodes', true);
 
If valid episodes have already been extracted, use either:
   gaitAnalyse("DATA/GaitParams.txt", 'overwriteFiles', 2) or
   gaitAnalyse("DATA/GaitParams.txt", 'overwriteMeasures', true)

If calculated measures are still valid, but aggregated values need to be
recalcuted (e.g., because the percentiles as specified in the parameter
file have been changed), use either:
   gaitAnalyse("DATA/GaitParams.txt", 'overwriteFiles', 1) or
   gaitAnalyse("DATA/GaitParams.txt", 'overwriteAggregatedValues', true)

If less output is desired, use:
   gaitAnalyse("DATA/GaitParams.txt", 'verbosityLevel', 0)

To omit writing JSON files, use:
   gaitAnalyse("DATA/GaitParams.txt", 'saveToJSON', false)


EXAMPLE OF A PARAMETER FILE
                
% Parameter settings:
    Classification file  = ?.csv               % mandatory!
    Raw measurement file = ?.OMX               % mandatory!
    Leg length = 0.925                         % mandatory!**
    Epoch length = 10                          % defaults to 10***
    Hours to skip at start of measurement = 6  % defaults to 0; hours may be
                                               % replaced by seconds or minutes
    Percentiles = [10 50 90]                   % defaults to [20 50 80]*
    % ***changing requires recalculation of locomotion episodes, locomotion
    %    measures, and aggregated values
    %  **changing requires recalculation of locomotion measures and aggregated
    %    values
    %   *changing requires recalculation of aggregated values

% To include physical activity information from the classification file:
   Get physical activity from classification = yes   
   Minimum sensor wear time per day = 18
   Minimum number of valid days for activities = 2
   Minimum number of valid days for lying = 3

% Measures that can be requested through the parameter file:
    Walking Speed                = yes
    Stride Length                = yes
    Stride Regularity            = yes  % or use Stride Regularity X*
    Sample Entropy               = yes  % or use Sample Entropy X*
    RMS                          = yes  % or use RMS X*
    Index Harmonicity            = yes  % or use Index Harmonicity X*
    Power At Step Freq           = yes  % or use Power At Step Freq X*
    Gait Quality Composite Score = yes
    Bimodal Fit Walking Speed    = yes  % does not always converge to the exact
                                        % same solution
    Preferred Walking Speed      = 0.96 % corresponding percentile will be
                                        % reported 
    % *For X use VT, ML, or AP to request individual directions, e.g., Stride
    %  Regularity VT.
  