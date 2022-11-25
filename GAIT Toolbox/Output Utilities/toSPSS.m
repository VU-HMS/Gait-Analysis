function toSPSS(fileName, measures, bimodalFitWalkingSpeed, percentiles, percentilePWS, bmf, ppws)
%% function toSPSS(fileName, measures, bimodalFitWalkingSpeed, percentiles, percentilePWS, bmf, ppws)
% Save the results contained in the structures 'measures' (always)
% 'bimodalFitWalkingSpeed' (only if bmf == true) and the variable 
% 'percentilePWS' (only if ppws == true) to a .csv file and a companion 
% .sps command file. The first column of the .csv file will contain the
% values given in 'percentiles'.
%
% Note: Run the .sps file to import the results in SPSS.

%% 2022, kaass@fbw.vu.nl
% Last updated: Nov 2022, kaass@fbw.vu.nl

%% general measures
fn = {'Percentiles'};
if ~isempty(measures)
    fn = [fn fieldnames(measures)'];
end

data = zeros(3, length(fn));
data(:,1) = percentiles;
for i=2:length(fn)
   data(:,i) = measures.(fn{i});
end

if bmf
    bmfws = bimodalFitWalkingSpeed;
    if isfield(bmfws, 'gmfit')
        bmfws = rmfield(bmfws, 'gmfit');
    end     
    fnbmfws = fieldnames(bmfws);
    fn = [fn fnbmfws'];
    for i=1:length(fnbmfws)
        d = bmfws.(fnbmfws{i});
        for n = 1 : 3-length(d) 
            d = [d NaN];
        end
        data = [data d'];
    end
end

if ppws
    fn   = [fn {'PercentilePWS'}];
    data = [data [percentilePWS NaN NaN]'];
end

[filepath, name, ~] = fileparts(fileName);

fid = fopen(fileName, 'w');

% write variable names
for i = 1:size(fn,2)
    fprintf(fid, '%s', fn{i});
    if i == size(fn,2)
        fprintf(fid,'\n');
    else
        fprintf(fid,'\t');
    end
end

% write data
len1 = size(data,1);
len2 = size(data,2); 
for i = 1:len1
    % loop through variables
    for j = 1:len2
        fprintf (fid, '%.6f', data(i,j));
        if j == len2
            if i < len1
                fprintf(fid,'\n');
            end
        else
            fprintf(fid,'\t');
        end
    end  
end

fclose(fid);


%% write  syntax file
fid = fopen([filepath '/' name '.sps'],'w');

fprintf (fid, 'GET DATA\n');
fprintf (fid, '  /TYPE=TXT\n');
fprintf (fid, '  /FILE=''%s''\n', fileName);
fprintf (fid, '  /DELCASE=LINE\n');
fprintf (fid, '  /DELIMITERS="\\t"\n');
fprintf (fid, '  /ARRANGEMENT=DELIMITED\n');
fprintf (fid, '  /FIRSTCASE=2\n');
fprintf (fid, '  /IMPORTCASE=ALL\n');
fprintf (fid, '  /VARIABLES=\n');

for  i = 1:size(fn,2)
    fprintf (fid, ['  ' fn{i} ' F12.6' '\n']);
end

spssOutputFileName = "" + filepath + name + ".sav";
fprintf (fid, '.\n\nSAVE OUTFILE=''%s''\n', spssOutputFileName);
fprintf (fid, '/COMPRESSED');

fclose(fid);


end