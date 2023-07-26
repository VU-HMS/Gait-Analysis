%% function [signal, dynaportInfo] = ac3_readFile(fileName, readData);
%
% INPUT:
% fileName:     full path of a *.ac3 or *.3ac
% readData:     whether to read only dynaportInfo (0) or also the data (1)
%
% OUTPUT: 
% signal:       measurment data
% dynaportInfo: structure with meta data, containing the 
%               struct fields 'mmInfo', 'mmUserInfo', and "measurements'
