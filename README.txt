GAIT Toolbox (DOI: https://zenodo.org/record/8187922)


The GAIT toolbox is a collection of MATLAB routines to estimate gait measures
from raw acceleration data. Many people (and articles) have contributed to the
GAIT Toolbox; at the bottom of this file you will find an overview.


INSTRUCTIONS

Include the "GAIT Toolbox" folder incl. its sub folders to your MATLAB path
("Set Path" can be found in MATLAB's ENVIRONMENT tool menu). If you plan to 
use gaitAnalysis.m (see below), also add the root folder (the one in which
gaitAnalysis.m and the "GAIT Toolbox" folder reside, defaultly named 
"Gait-Analysis") to the MATLAB-path (without subfolders).

If the path is set, you can run gaitAnalysis.m (graphical tool, see PDF-manual 
in the doc folder), or process a single input file from the command line 
through gaitAnalyse.m (see below). gaitAnalyseMany.m is a simple example how 
to run gaitAnalyse.m mulitiple times with different input files (in the
graphical tool you can create a 'batch" for this). 


CONTENTS

Folder "GAIT Toolbox/Frondend utilities" contains utilities used by gaitAnalyse
to parse input files, read the measurement data (using McRoberts code), and
calculate and present the gait estimates (using the algorithms in the below two
folders).

Folder "GAIT Toolbox/Gait Quality Estimates/" contains most of the algorithms.

Folder "GAIT Toolbox/Get Aggregate Values/" contains utilities to collect the
calculated values.

Folder "GAIT Toolbox/Output Utilities/" contains some utilities for the 
main function gaitAnalyse() to save the results in different output formats.

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
%                              results in JSON-format 
%                       false  do not write JSON files (default)
%
%   'saveToSPSS'        true   in addtion to MATLAB- and textformat, write 
%                              results in SPSS-format 
%                       false  do not write SPSS files (default
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
%           ignored
%         - saveToJSON and saveToSPSS, if specified, overrule the 
%           settings in paramatersFile


EXAMPLES

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

To suppress writing JSON files, use:
   gaitAnalyse("DATA/GaitParams.txt", 'saveToJSON', false)
(or specify "Save to SPSS = no" in the parameter file; see below)

EXAMPLE OF A PARAMETER FILE
                
% Parameter settings:
    Classification file  = ?.csv                % mandatory
    Raw measurement file = ?.OMX                % mandatory
    Leg length** = 0.925                        % mandatory
    Epoch length*** = 10                        % defaults to 10
    Cutoff frequency** = 0.5                    % defaults to 0.5 (used in Butterworth
                                                % filter to counteract integration drift)
    Hours to skip at start of measurement* = 6  % defaults to 0; hours may be
                                                % replaced by seconds or minutes
    Percentiles* = [10 50 90]                   % defaults to [20 50 80]
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
    Stride Regularity*           = yes
    Sample Entropy*              = yes
    RMS*                         = yes
    Index Harmonicity*           = yes
    Power At Step Freq*          = yes
    Gait Quality Composite Score = yes
    Bimodal Fit Walking Speed    = yes  % does not always converge to the exact
                                        % same solution
    Preferred Walking Speed      = 0.96 % corresponding percentile will be
                                        % reported 
    % *Add VT, ML, or AP to request individual directions, e.g., RMS VT.
 
% Output format of the above measures (in addition to text and MATLAB)
   Save to JSON                  = yes  % default = yes
   Save to SPSS                  = yes  % default = no


REFERENCES

Several articles are referred to in the MATLAB codes. Below you will find a full
reference, including a web link.

1) A. Wolf, J.B. Swift, H.L. Swinney, and J.A. Vastano (1985). 
Determining Lyapunov exponents from a time series. 
Physica D: Nonlinear Phenomena 16(3): 285-317.
https://doi.org/10.1016/0167-2789(85)90011-9

2) J.S. Richman, and J.R. Moorman (2000).
Physiological time-series analysis using approximate entropy and sample entropy.
American Journal of Physiology - Heart and Circulatory Physiology, 278(6): H2039-2049.
https://doi.org/10.1152/ajpheart.2000.278.6.H2039

3) W. Zijlstra & L. Hof (2003). 
Assessment of spatio-temporal gait parameters from trunk accelerations during human
walking.
Gait & Posture, 18(2): 1-10.
https://doi.org/10.1016/S0966-6362(02)00190-X

4) R. Moe-Nilssen and J.L. Helbostad (2004).
Estimation of gait cycle characteristics by trunk accelerometry. 
Journal of Biomechanics,  37(1): 121-126.
https://doi.org/10.1016/S0021-9290(03)00233-1

5) D. Kugiumtzis and A. Tsimpiris (2010).
Measures of analysis of time series (MATS): a Matlab toolkit for computation of multiple
measures on time series data bases.
Journal of Statistical Software, 33(5); 1-30.
https://www.jstatsoft.org/article/view/v033i05

6) A. Weiss, M. Brozgol, M. Dorfman, T. Herman, S. Shema, N. Giladi, and 
J.M. Hausdorff (2013).
Does the evaluation of gait quality during daily life provide insight into fall risk? A
novel approach using 3-day accelerometer recordings.
Neurorehabilitation and Neural Repair, 27(8): 742-752.
https://doi.org/10.1177/1545968313491004

7) S.M. Rispens, K.S. van Schooten, M. Pijnappels, A. Daffertshofer, P.J. Beek,
and J.H. van Dieën (2014).
Identification of fall risk predictors in daily life measurements: gait characteristics’
reliability and association with self-reported fall history.
Neurorehabilitation and Neural Repair, 29(1): 54-61.
https://doi.org/10.1177/1545968314532031

8) K.S. van Schooten, M. Pijnappels, S.M. Rispens, P.J.M. Elders, P. Lips,
and J.H. van Dieën (2015).
Ambulatory fall-risk assessment: amount and quality of daily-life gait predict falls in
older adults.
Journals of Gerontology, Series A:Biological Sciences & Medical Sciences, 70(5): 608-615.
https://doi.org/10.1093/gerona/glu225


CONTRIBUTORS

Many people have contributed to the GAIT toolbox, including programmers, 
PhD students and scientific staff members. Among others, these include (in
alphabetical order): Peter Beek, Sjoerd Bruijn, Richard Casius, 
Andreas Daffertshofer, Jaap van Dieën, Pieter van Doorn, Mirjam Pijnappels, 
Markus Rieger, Sietse Rispens, Kim van Schooten, Roel Weijer and Yuge Zhang.