function toJSON(fileName, measures, legLength, bimodalFitWalkingSpeed, percentiles, percentilePWS, bmf, ppws)
%% function toJSON(fileName, measures, legLength, bimodalFitWalkingSpeed, percentiles, percentilePWS, bmf, ppws)
% Save the results contained in the structures 'measures' (always) and
% 'bimodalFitWalkingSpeed' (only if bmf == true), and the variables 
% 'legLength' (always), 'percentiles' (always) and  
% 'percentilePWS' (only if ppws == true) to JSON format.
% Note: 'bimodalFitWalkingSpeed' MUST contain the fields 'Ashman_D',
% 'peakDensity' and 'peakSpeed'.

%% 2022, kaass@fbw.vu.nl
% Last updated: Nov 2022, kaass@fbw.vu.nl

%% start json
fp = fopen(fileName, 'w');
fprintf(fp, '{\n');
none="null";

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
else
    fn = {'WalkingSpeed', 'StrideLength', 'SampleEntropy_VT',...
          'SampleEntropy_ML', 'SampleEntropy_AP', 'StrideRegularity_VT',...
          'RMS_ML', 'IndexHarmonicity_ML', 'PowerAtStepFreq_AP',...
          'GaitQualityCompositeScore'};
end

fprintf(fp, '\t"GeneralMeasures": [\n');
for i=1:numel(fn)
    if Contains(fn{i}, "speed")
        unit = "m/s";
    elseif Contains(fn{i}, "length")
        unit = "m";
    else
        unit = "None";
    end
    if ~isempty(measures)
        fprintf(fp, '\t\t{"label": "%s", "unit": "%s", "values": {"%s": %.3f, "%s": %.3f, "%s": %.3f}}',...
                char(fn(i)), unit,...
                "PCTL1", measures.(fn{i})(1),...
                "PCTL2", measures.(fn{i})(2),...
                "PCTL3", measures.(fn{i})(3));
    else
        fprintf(fp, '\t\t{"label": "%s", "unit": "%s", "values": {"%s": %s, "%s": %s, "%s": %s}}',...
                char(fn(i)), unit,...
                "PCTL1", none, "PCTL2", none, "PCTL3", none);
    end
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


%% bimodal fit
if bmf
    if ~isempty(bimodalFitWalkingSpeed)
        fprintf(fp, '\t"BimodalFitWalkingSpeed": [\n');
        fprintf(fp, '\t\t{"label": "Ashman_D", "unit": "None", "values": %.3f},\n',...
                bimodalFitWalkingSpeed.Ashman_D);
        fprintf(fp, '\t\t{"label": "PeakDensity", "unit": "None", "values": {"1st": %.3f, "2nd": %.3f}},\n',...
                bimodalFitWalkingSpeed.peakDensity(1), bimodalFitWalkingSpeed.peakDensity(2));
        fprintf(fp, '\t\t{"label": "PeakSpeed", "unit": "m/s", "values": {"1st": %.3f, "2nd": %.3f}}\n',...
                bimodalFitWalkingSpeed.peakSpeed(1), bimodalFitWalkingSpeed.peakSpeed(2));
        fprintf(fp, '\t],');
    else
        fprintf(fp, '\t"BimodalFitWalkingSpeed": [\n');
        fprintf(fp, '\t\t{"label": "Ashman_D", "unit": "None", "values": %s},\n', none);
        fprintf(fp, '\t\t{"label": "PeakDensity", "unit": "None", "values": {"1st": %s, "2nd": %s}},\n',...
                    none, none);
        fprintf(fp, '\t\t{"label": "PeakSpeed", "unit": "m/s", "values": {"1st": %s, "2nd": %s}}\n',...
                    none, none);
        fprintf(fp, '\t],');
    end
%     if ppws
%         fprintf(fp, ',');
%     end
    fprintf(fp, '\n');
end

%% percentile of preferred walking speed
if ppws
    fprintf(fp, '\t"PercentilePreferredWalkingSpeed": [\n');
    if ~isempty(percentilePWS)
        fprintf(fp, '\t\t{"label": "PercentilePWS", "unit": "None", "values": %.2f}\n',...
                percentilePWS);
    else
        fprintf(fp, '\t\t{"label": "PercentilePWS", "unit": "None", "values": %s}\n', none);
    end
    fprintf(fp, '\t]\n');
end

%% end json
fprintf(fp, "}");
fclose (fp);

end % toJSON



%% sub functions
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


