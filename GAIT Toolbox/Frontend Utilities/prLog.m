function prLog(message, func, addTime, newFile, fileName)
%% function prLog(message, func, addTime, newFile, fileName)
%
% DESCRIPTION
%
%  Print log messages. If newFile is true, a new log file is opended for
%  appending messages, otherwise messages are appended to the currently 
%  open log file. If newFile is true and a fileName is given, the latter 
%  one is the file to open, otherwise it defaults to "log.txt" in the   
%  current folder. To close the currenlty opene log file, simply call this  
%  function without parameters.
%
% INPUT
%
%  message   The log message.
%  func      The name of the calling funcion. 
%  addTime   If true (default), the current time is added to the message.
%  newFile   If true, a new log file is opened.
%  fileName  If newFile is true, fileName is the name of the file where the
%            messages should go; if omitted, it defaults to the file
%            "log.txt" in the current folder.
%
% EXAMPLE
%
%  % open the file log.txt in the current folder, and print the message
%  % along with the name of the calling function and the current time.
%  prLog("Start.\n", "init", true, true); 
%  % add another message
%  prLog("Compute x.\n", "computeParameter");
%  % print a simple message without a function name and the current time
%  prLog("Just a message", "", false);
%  % close file  
%  prLog();
%  % open a new file and print a message
%  prLog("First message in new file.\n","analyze",true,true,"c:\log.txt");
%  % add a message
%  prLog("Done", "deinit");
%  % close second file
%  prLog();


%% 2022, kaass@fbw.vu.nl
% Last updated: July 2022, kaass@fbw.vu.nl

%% process input arguments
persistent logFID

if (nargin < 1)
   if exist('logFID', 'var') && ~isempty(logFID)
       fclose (logFID);
       logFID = [];
   end
   return;
end

if nargin < 2
    func = "";
elseif (ischar(func) || isstring(func)) && strlength(func) > 0 
    func = ['[' func '] '];
else
    func = "";
end

if nargin < 3
    addTime = true;
end

if (nargin > 3)
    if newFile
        logFID = [];
    end
end

%% (re)open file
if ~exist('logFID', 'var') || isempty(logFID)
    if (nargin > 4)
        logFile = fileName;
    else
        if (isdeployed)
            if ispc
                currentFolder = getenv('USERPROFILE');
            else
                currentFolder = getenv('HOME');
            end               
        else
            currentFolder = pwd;
        end
        currentFolder = strrep(currentFolder, '\', '/');
        logFile = [currentFolder '/' 'log.txt'];
    end
    % printf ("Log file = %s.\n", logFile);
    logFID = fopen(logFile, 'a');
end

%% print messsage
message = sprintf(message); %% to get '\n' printed to file
if ~endsWith(message, newline)
    message = [message newline];
end

if (logFID > 0)
    if (addTime)
        fprintf (logFID, "%s %s%s", datetime('now'), func, message);
    else
        fprintf (logFID, "%s%s", func, message);
    end
end

end


