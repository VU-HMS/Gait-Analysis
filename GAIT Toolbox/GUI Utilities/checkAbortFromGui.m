function [abort] = checkAbortFromGui(printMessage)
%% function [abort] = checkAbortFromGui()
%  call this function periodically during long operations and return
%  control if true is returned, e.g., "if checkAbortFromGui() return; end"

%% 2021, kaass@fbw.vu.nl 
% Last updated: Dec 2021, kaass@fbw.vu.nl

global guiApp

if nargin < 1
    printMessage = true;
end

if exist('guiApp', 'var') && ~isempty(guiApp) && ~isnumeric(guiApp) && guiApp.abort
    if printMessage
        fprintf(guiApp, 'Aborted by user.\n\n');
    end
    abort = true;
else
    abort = false;
end
