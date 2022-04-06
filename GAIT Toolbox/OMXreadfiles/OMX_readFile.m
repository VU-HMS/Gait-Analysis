%
%   NOTES:
%   * This version defaults to reading just the accelerometer values.
%   * The gyroscope/magnetometer data can be read when given the options:  'modality', [1, 1, 1]
%   * Stepped data can be read given the options:  'step', 100
%   * The accelerometer values are currently always scaled 1/4096 (the default range conversion to 'g')
%   * Metadata, light, pressure, temperature and battery levels are not yet supported
%   * For speed, the Matlab importer doesn't check the sector checksum.
%
%
%   DATA = OMX_readFile(FILENAME, [OPTIONS])
%
%   Reads in an OMX binary file.
%   Returns a struct filled with data.
%
%       Input arguments:
%           FILENAME            Path to OMX file
%
%       OPTIONS:
%
%           'info'              If set to 1, just reads information
%                               from file. Such as start time of
%                               measurement, device serialnumber, etc. 
%                               (see example below)
%
%           'packetInfo'        A Nx3 matrix containing pre-read
%                               packet locations, timestamps and
%                               timestamp offsets (produced by
%                               info-mode).
%
%           'startTime'         Use this combined with 'stopTime' for
%                               sliced reading. i.e. read all samples
%                               from startTime to stopTime. Has to be
%                               given in Matlab-time format (see
%                               example below)
%
%           'stopTime'          See above.
%
%           'modality'          A three element vector [1, 1, 1] that
%                               indicates which sensor modalities to
%                               extract. Order is ACC, GYR, MAG.
%                               e.g. [1, 0, 0]
%
%           'verbose'           Print out debug messages about
%                               progress.
%
%           'useC'              Attempt to speed up parsing of samples and
%                               timestamps by relying on external
%                               c-code (parseDate.c). Requires compilation
%                               using mex-interface or pre-compiled
%                               binaries (.mexXXX files).
%
%           'step'              Skip samples (1 = no skipping),
%                               inefficient for small numbers that are not 1.
%
%
%       EXAMPLES:
%
%       Reading file information:
%           >> fileinfo = OMX_readFile('foobar.omx', 'info', 1)
%               fileinfo =
%                   packetInfo: [991997x5 double]
%                        start: [1x1 struct]
%                         stop: [1x1 struct]
%                   deviceType: 19789
%                     deviceId: 12345
%                  rawMetadata: [1x192 char] 
%           >> fileinfo.start
%               ans =
%                   mtime: 7.3492e+05
%                     str: '17-Feb-2012 12:56:25'
%
%       subsequent read of slice using pre-read packet info:
%           >> data = OMX_readFile('foobar.omx', ...
%               'packetInfo', fileinfo.packetInfo, ...
%               'startTime', datenum('19-Feb-2012 00:00:00'), ...
%               'stopTime', datenum('20-Feb-2012 00:00:00'));
%
%           >> data =
%                 packetInfo: [73059x5 double]
%                        ACC: [8766736x4 double]
%                        GYR: [8766736x4 double]
%                        MAG: [8766736x4 double]
%
%   v0.1
%       Dan Jackson, 2014
%       derived from CWA importer by Nils Hammerla, 2012 <nils.hammerla@ncl.ac.uk>
%
% Copyright (c) 2012-2014, Newcastle University, UK.
% All rights reserved.
%
% Redistribution and use in source and binary forms, with or without
% modification, are permitted provided that the following conditions are met:
% 1. Redistributions of source code must retain the above copyright notice,
%    this list of conditions and the following disclaimer.
% 2. Redistributions in binary form must reproduce the above copyright notice,
%    this list of conditions and the following disclaimer in the documentation
%    and/or other materials provided with the distribution.
%
% THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
% AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
% IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
% ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
% LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
% CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
% SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
% INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
% CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
% ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
% POSSIBILITY OF SUCH DAMAGE.
%
