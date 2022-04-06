parameterFiles = {'Data/GaitParams.txt' ...
                  'Data/GaitParams2.txt' ...
                  'Data2/GaitParams.txt'};

t = tic;
n = length(parameterFiles);
for i = 1 : n
    fprintf ('\nProcessing file %d of %d (%s)\n', i, n, parameterFiles{i});
    gaitAnalyse(parameterFiles{i}, 'overwriteEpisodes', true);
end
fprintf ('Total running time: %.1f seconds.\n', toc(t));
