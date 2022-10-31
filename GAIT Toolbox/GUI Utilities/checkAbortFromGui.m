function [abort] = checkAbortFromGui(printMessage)
%% function [abort] = checkAbortFromGui()
%  call this function periodically during long operations and return
%  control if true is returned, e.g., "if checkAbortFromGui() return; end"

%% 2021, kaass@fbw.vu.nl 
% Last updated: Oct 2022, kaass@fbw.vu.nl

global guiApp abortPrinted

if nargin < 1
    printMessage = isempty(abortPrinted) || ~abortPrinted;
end

if exist('guiApp', 'var') && ~isempty(guiApp) && ~isnumeric(guiApp) && guiApp.abort
    if printMessage
        fprintf(guiApp, 'Aborted by user.\n\n');
        prLog(); %% close log file, assuming control is returned to GUI
        abortPrinted = true;
    end
    abort = true;
else
    abort = false;
end
