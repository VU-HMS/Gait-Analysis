function eprintf(varargin)
%% function [abort] = printf(varargin)
%  call this function instead of fprintf to redirect error messages to 
%  either the GUI App or the MATLAB console window (standard error)

%% 2021, kaass@fbw.vu.nl 
% Last updated: Dec 2021, kaass@fbw.vu.nl
global guiApp; 

if exist('guiApp', 'var') && ~isempty(guiApp) && ~isnumeric(guiApp)
   guiApp.pError = true;
   fprintf (guiApp, varargin{:});
else   
   fprintf (2, varargin{:});
end


end

