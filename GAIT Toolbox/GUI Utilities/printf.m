function printf(varargin)
%% function [abort] = printf(varargin)
%  call this function instead of fprintf to redirect output to either the 
%  GUI App or the MATLAB console window (standard output)

%% 2021, kaass@fbw.vu.nl 
% Last updated: Dec 2021, kaass@fbw.vu.nl
global guiApp; 


if exist('guiApp', 'var') && isvalid(guiApp) && ~isempty(guiApp) && ~isnumeric(guiApp)   
   fprintf (guiApp, varargin{:});
else
   fprintf (1, varargin{:});
end

end


