classdef gaitAnalysis < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        figure1                       matlab.ui.Figure
        BatchMenu                     matlab.ui.container.Menu
        Add                           matlab.ui.container.Menu
        Update                        matlab.ui.container.Menu
        Verify                        matlab.ui.container.Menu
        Execute                       matlab.ui.container.Menu
        Load                          matlab.ui.container.Menu
        Save                          matlab.ui.container.Menu
        GraphMenu                     matlab.ui.container.Menu
        CumulativeDistance            matlab.ui.container.Menu
        WalkingSpeed                  matlab.ui.container.Menu
        StrideDuration                matlab.ui.container.Menu
        StrideLength                  matlab.ui.container.Menu
        DistributionOfWalkingSpeed    matlab.ui.container.Menu
        WalkingSpeedHistogram         matlab.ui.container.Menu
        WalkingSpeedDensity           matlab.ui.container.Menu
        HelpMenu                      matlab.ui.container.Menu
        ShowExampleParameters         matlab.ui.container.Menu
        About                         matlab.ui.container.Menu
        txt_paramsFile                matlab.ui.control.Label
        cmd_getPath                   matlab.ui.control.Button
        txt_Title                     matlab.ui.control.Label
        cmd_Run                       matlab.ui.control.Button
        cmd_editFile                  matlab.ui.control.Button
        checkbox_overwriteEpisodes    matlab.ui.control.CheckBox
        checkbox_overwriteMeasures    matlab.ui.control.CheckBox
        checkbox_overwriteAggValues   matlab.ui.control.CheckBox
        TabGroupp                     matlab.ui.container.TabGroup
        tab_console                   matlab.ui.container.Tab
        ConsoleTextAreaLabel          matlab.ui.control.Label
        txt_Console                   matlab.ui.control.TextArea
        tab_batch                     matlab.ui.container.Tab
        table_batch                   matlab.ui.control.Table
        tab_graph                     matlab.ui.container.Tab
        UIAxes                        matlab.ui.control.UIAxes
        ViewModeButtonGroup           matlab.ui.container.ButtonGroup
        AllButton                     matlab.ui.control.ToggleButton
        PerDayButton                  matlab.ui.control.ToggleButton
        PerHourButton                 matlab.ui.control.ToggleButton
        NextButton                    matlab.ui.control.Button
        PrevButton                    matlab.ui.control.Button
        IntervalGroup                 matlab.ui.container.ButtonGroup
        Auto                          matlab.ui.control.ToggleButton
        d02                           matlab.ui.control.ToggleButton
        d05                           matlab.ui.control.ToggleButton
        d1                            matlab.ui.control.ToggleButton
        ShowPreferredSpeedCheckBox    matlab.ui.control.CheckBox
        ShowNumberOfEpisodesCheckBox  matlab.ui.control.CheckBox
        tab_help                      matlab.ui.container.Tab
        ConsoleTextAreaLabel_2        matlab.ui.control.Label
        txt_Help                      matlab.ui.control.TextArea
        cmd_Clear                     matlab.ui.control.Button
        LampLabel                     matlab.ui.control.Label
        Lamp                          matlab.ui.control.Lamp
        cmd_Cancel                    matlab.ui.control.Button
        cmd_Execute                   matlab.ui.control.Button
        ContextMenuBatchTable         matlab.ui.container.ContextMenu
        DeleteSelectedItemsMenu       matlab.ui.container.Menu
    end

        
    properties (Access = private)
        versionTxt = 'Gait Analysis 3.2 - Interface to the VU-HMS Gait Toolbox';
        batchFile = 'GaitBatch.mat';
        timeStamp = 0;
        parmsError = false;
        tableIndices = [];
        maxBatches = 1000;
        oldValEnable = [];
        oldValEnableBatchTable = '';
        cancel = false;
        fileNameLocomotionMeasures = '';
        fileNameAggregatedValues = '';
        currentHour=1;
        prefSpeed=0;
    end
    
    
    properties (Access = public)
        pError    = false; % set to true before each call to fprintf to mark text as error; not yet funnctional  
        pAlert    = false; % set to true before each call to fprintf to mark text as important; not yet funnctional
        pReplace  = false; % set to true if last message should be replaced by new message
        gaitError = false; % set to true if something went wrong during Gait Analysis
        abort     = false; % abort==true if the user has indicated that the current analysis should be aborted
    end
    
    methods (Access = private)
        
        function disableAll(app)
            app.oldValEnable(1)  = app.BatchMenu.Enable;
            app.oldValEnable(2)  = app.HelpMenu.Enable;
            app.oldValEnable(3)  = app.cmd_getPath.Enable;
            app.oldValEnable(4)  = app.cmd_editFile.Enable;
            app.oldValEnable(5)  = app.cmd_Clear.Enable;
            app.oldValEnable(6)  = app.cmd_Run.Enable;
            app.oldValEnable(7)  = app.cmd_Execute.Enable;
            app.oldValEnable(8)  = app.checkbox_overwriteEpisodes.Enable;
            app.oldValEnable(9)  = app.checkbox_overwriteMeasures.Enable;
            app.oldValEnable(10) = app.checkbox_overwriteAggValues.Enable;         

            app.BatchMenu.Enable                   = false;
            app.HelpMenu.Enable                    = false;
            app.cmd_getPath.Enable                 = false;
            app.cmd_editFile.Enable                = false;
            app.cmd_Clear.Enable                   = false;
            app.cmd_Run.Enable                     = false;
            app.cmd_Execute.Enable                 = false;
            app.checkbox_overwriteEpisodes.Enable  = false;
            app.checkbox_overwriteMeasures.Enable  = false;
            app.checkbox_overwriteAggValues.Enable = false;
            
            app.oldValEnableBatchTable = app.table_batch.Enable;
            app.table_batch.Enable = 'off';
            
            unMarkTab (app, app.tab_console);
            unMarkTab (app, app.tab_help);
            unMarkTab (app, app.tab_batch);
        end
        
        function enableAll(app)
            app.BatchMenu.Enable    = app.oldValEnable(1);
            app.HelpMenu.Enable     = app.oldValEnable(2);
            app.cmd_getPath.Enable  = app.oldValEnable(3);
            app.cmd_editFile.Enable = app.oldValEnable(4);
            app.cmd_Clear.Enable    = app.oldValEnable(5);
            app.cmd_Run.Enable      = app.oldValEnable(6);
            app.cmd_Execute.Enable  = app.oldValEnable(7);
            app.checkbox_overwriteEpisodes.Enable  = app.oldValEnable(8);
            app.checkbox_overwriteMeasures.Enable  = app.oldValEnable(9);
            app.checkbox_overwriteAggValues.Enable = app.oldValEnable(10);

            app.table_batch.Enable = app.oldValEnableBatchTable;
            
            app.cmd_Cancel.Visible = false;
            app.cancel = false;
            app.abort = false;

            checkBatchMenu(app);
            app.Lamp.Color = [0 0.3 0];
        end
        
        function changeTab (app, event, tab)
            if app.TabGroupp.SelectedTab ~= tab
                app.TabGroupp.SelectedTab = tab;
            end
            TabGrouppSelectionChanged (app, event); % this also makes run/execute button visible
        end
        
        function markTab (app, tab, color)
            if app.TabGroupp.SelectedTab ~= tab                
                if nargin < 4
                    color = 'green';
                end
                fg = [0, 0.45, 0.70];
                if strcmpi(color,'green')
                    app.Lamp.Color = [0 1 0];
                elseif strcmpi(color,'red')
                    app.Lamp.Color = [1 0 0];
                else
                    app.Lamp.Color = [0 0.3 0];
                end
                if (tab == app.tab_console)
                    app.tab_console.ForegroundColor = fg;
                elseif (tab == app.tab_help)
                    app.tab_help.ForegroundColor = fg;
                elseif (tab == app.tab_batch)
                    app.tab_batch.ForegroundColor = fg;
                end
            end
        end
                
        function unMarkTab (app, tab)
             app.Lamp.Color = [0 0.3 0];
             if (tab == app.tab_console)
                 app.tab_console.ForegroundColor = [0 0 0];
             elseif (tab == app.tab_help)
                 app.tab_help.ForegroundColor = [0 0 0];
             elseif (tab == app.tab_batch)
                 app.tab_batch.ForegroundColor = [0 0 0];
             elseif (tab == app.tab_graph)
                 app.tab_batch.ForegroundColor = [0 0 0];
             end
        end
       
        
        function unMarkGraphs(app)
            app.WalkingSpeed.Checked = false;
            app.StrideLength.Checked = false;
            app.StrideDuration.Checked = false;
            app.CumulativeDistance.Checked = false;
            app.DistributionOfWalkingSpeed.Checked = false;
            app.WalkingSpeedDensity.Checked = false;
            app.WalkingSpeedHistogram.Checked = false;
        end
        
        
        
        function drawGraph(app)

            if (app.fileNameLocomotionMeasures == "")
                cla(app.UIAxes, 'reset');
                app.UIAxes.Title.String = "No valid data";
                drawnow();
                return;
            end
            app.UIAxes.Title.String = "Processing data...";
            drawnow();
               
            result = graphAnal(app.fileNameLocomotionMeasures, app.fileNameAggregatedValues);

            if app.CumulativeDistance.Checked
                app.ViewModeButtonGroup.Visible = 'Off';
                app.IntervalGroup.Visible = 'Off';
                app.NextButton.Visible = 'Off';
                app.PrevButton.Visible = 'Off';
                app.ShowPreferredSpeedCheckBox.Visible = 'Off';
                app.ShowNumberOfEpisodesCheckBox.Visible = 'Off';
                drawnow();
                app.UIAxes.Title.String  = "Cumulative Distance";
                app.UIAxes.XLabel.String = "Time (hours)";
                app.UIAxes.YLabel.String = "Distance (m)";
                app.UIAxes.XLim = [-inf inf];
                app.UIAxes.YLim = [-inf 1.05*max(result.distance)];
                app.UIAxes.XTickMode = 'auto';
                app.UIAxes.YTickMode = 'auto';
                plot(app.UIAxes, result.time, result.distance,'blue');
            elseif app.DistributionOfWalkingSpeed.Checked || app.WalkingSpeedDensity.Checked || app.WalkingSpeedHistogram.Checked  
                app.ViewModeButtonGroup.Visible = 'Off';
                app.IntervalGroup.Visible = 'On';
                app.NextButton.Visible = 'Off';
                app.PrevButton.Visible = 'Off';
                app.ShowNumberOfEpisodesCheckBox.Visible = 'On';
                if app.prefSpeed > 0
                    app.ShowPreferredSpeedCheckBox.Visible = 'On';
                else
                    app.ShowPreferredSpeedCheckBox.Visible = 'Off';
                end
                drawnow();
                epochs = length(result.speed);
                if app.DistributionOfWalkingSpeed.Checked 
                    app.UIAxes.Title.String  = "Distribution of Daily Life Walking Speed";
                    app.UIAxes.YLabel.String = "Density";
                elseif app.WalkingSpeedDensity.Checked
                    app.UIAxes.Title.String  = "Probability Density Function Walking Speed";
                    app.UIAxes.YLabel.String = "Density";
                elseif app.WalkingSpeedHistogram.Checked
                    app.UIAxes.Title.String  = "Histogram Walking Speed";
                    app.UIAxes.YLabel.String = "Normalized Count (%)";
                end
                app.UIAxes.XLabel.String = "Walking Speed (m/s)";      
                if app.IntervalGroup.SelectedObject == app.Auto
                    if (epochs > 400)
                        d = 0.02;
                    elseif (epochs > 200)
                        d = 0.05;
                    else
                        d = 0.1;
                    end
                elseif app.IntervalGroup.SelectedObject == app.d02
                    d=0.02;
                elseif app.IntervalGroup.SelectedObject == app.d05
                    d=0.05;
                elseif app.IntervalGroup.SelectedObject == app.d1
                    d=0.1;
                end
                minSpeed=min(result.speed);
                start=minSpeed-mod(minSpeed, d);
                edges = start:d:max(result.speed)+d;
                [y, x] = histcounts(result.speed, edges);
                x = x(1:end-1);
                y=100*y/length(result.speed);
                app.UIAxes.XLim = [x(1)-0.1 x(end)+0.1];
                app.UIAxes.XTick     =  0:0.1:max(x)+0.1;
                app.UIAxes.XTickMode = 'manual';
                app.UIAxes.YTickMode = 'auto';
                if app.DistributionOfWalkingSpeed.Checked || app.WalkingSpeedDensity.Checked
                    if isfield(result, "gmfit")
                        x2 = app.UIAxes.XLim(1):0.001:app.UIAxes.XLim(2);
                        y2 = pdf(result.gmfit, x2');
                    end
                end
                if app.WalkingSpeedHistogram.Checked 
                    app.UIAxes.YLim = [0 1.05*max(y)];
                    bar(app.UIAxes, x+d/2, y, 1);
                elseif app.DistributionOfWalkingSpeed.Checked
                    if isfield(result, "gmfit")
                        scale = max(y2)/max(y);
                        app.UIAxes.YLim = [0 1.05*max(y2)];
                        bar(app.UIAxes, x+d/2, scale*y, 1);
                        hold (app.UIAxes, "on");
                        plot(app.UIAxes, x2, y2, 'k-', 'linewidth', 2);
                        hold(app.UIAxes, "off");
                    else
                        cla(app.UIAxes, 'reset');
                        app.UIAxes.Title.String = "No biomodal fit of the data found";
                        app.ShowNumberOfEpisodesCheckBox.Visible = 'Off';
                        app.IntervalGroup.Visible = 'Off';
                        app.ShowPreferredSpeedCheckBox.Visible = 'Off';
                        drawnow();
                        return;
                    end
                elseif app.WalkingSpeedDensity.Checked 
                    if isfield(result, "gmfit")
                        app.UIAxes.YLim = [0 1.05*max(y2)];
                        plot(app.UIAxes, x2, y2, 'k-', 'linewidth', 2);
                    else
                        cla(app.UIAxes, 'reset');
                        app.UIAxes.Title.String = "No biomodal fit of the data found";
                        app.ShowNumberOfEpisodesCheckBox.Visible = 'Off';
                        app.IntervalGroup.Visible = 'Off';
                        app.ShowPreferredSpeedCheckBox.Visible = 'Off';
                        drawnow();
                        return;
                    end
                end
                if (app.prefSpeed > 0) && app.ShowPreferredSpeedCheckBox.Value 
                    hold (app.UIAxes, "on");                  
                    plot(app.UIAxes, [app.prefSpeed app.prefSpeed+0.001], [0 0.95 * app.UIAxes.YLim(2)], 'r:', 'linewidth', 3);
                    hold(app.UIAxes, "off");
                end
                if app.ShowNumberOfEpisodesCheckBox.Value
                    str = sprintf("n=%d", length(result.speed));
                    text(app.UIAxes, app.UIAxes.XLim(1)+0.05, 0.95*app.UIAxes.YLim(2), str);
                end
            elseif app.WalkingSpeed.Checked || app.StrideLength.Checked || app.StrideDuration.Checked
                app.ViewModeButtonGroup.Visible = 'On';
                app.IntervalGroup.Visible       = 'Off';
                app.ShowPreferredSpeedCheckBox.Visible = 'Off';
                app.ShowNumberOfEpisodesCheckBox.Visible = 'Off';
                if app.ViewModeButtonGroup.SelectedObject == app.AllButton
                    app.NextButton.Visible = 'Off';
                    app.PrevButton.Visible = 'Off';
                else
                    app.NextButton.Visible = 'On';
                    app.PrevButton.Visible = 'On';
                end
                if app.WalkingSpeed.Checked
                    app.UIAxes.Title.String  = "Walking Speed";
                    app.UIAxes.XLabel.String = "Time (hours)";
                    app.UIAxes.YLabel.String = "Speed (m/s)";
                    y = result.speed;
                elseif app.StrideLength.Checked
                    app.UIAxes.Title.String  = "Stride Length";
                    app.UIAxes.XLabel.String = "Time (hours)";
                    app.UIAxes.YLabel.String = "Length (m)";
                    y = result.strideLength;
                else
                    app.UIAxes.Title.String  = "Stride Duration";
                    app.UIAxes.XLabel.String = "Time (hours)";
                    app.UIAxes.YLabel.String = "Duration (s)";
                    y = result.strideDuration;
                end
                app.UIAxes.YLim = [0 1.05*max(y)];
                app.UIAxes.YTickMode = 'auto';
                if app.ViewModeButtonGroup.SelectedObject == app.AllButton
                    app.UIAxes.XLim      = [0, result.time(end)];
                    app.UIAxes.XTickMode = 'auto';
                    bar(app.UIAxes, result.time, y, 6, 'black');
                elseif app.ViewModeButtonGroup.SelectedObject == app.PerDayButton
                    app.currentHour = floor (min(app.currentHour, result.time(end)-0.001));
                    if mod(app.currentHour, 24) ~= 0
                        app.currentHour = app.currentHour - mod(app.currentHour, 24);
                    end
                    i = app.currentHour+24;
                    index = find((result.time <= i) & (result.time >= i-24));
                    app.UIAxes.XLim      = [i-24 i];
                    app.UIAxes.XTick     = i-24:1:i;
                    app.UIAxes.XTickMode = 'manual';
                    bar(app.UIAxes, result.time(index), y(index), 0.1, 'black'); 
                else
                    app.currentHour = floor (min(app.currentHour, result.time(end)-0.001));
                    i = app.currentHour+1;
                    if (i==1)
                        index = find(result.time <= i);
                    else
                        index = find((result.time <= i) & (result.time >= i-1));
                    end
                    app.UIAxes.XLim      = [i-1 i];
                    app.UIAxes.XTick     = i-1:1/10:i;
                    app.UIAxes.XTickMode = 'manual';
                    bar(app.UIAxes, result.time(index), y(index), 10/3600, 'black'); 
                end
            end
            drawnow();
        end
        
        
        function bool = isEqual(~, v1, v2)
             if length(v1) ~= length (v2)
                bool = false;
            else
                bool = sum(v1 ~= v2) == 0;
            end
        end
        
                  
        function updateBatch(app, element)
            filename = cell2mat(element(1));
            if isempty(app.table_batch.Data) 
                str = sprintf ('Adding %s to current batch.',  filename);
                app.table_batch.Data = element;
            else
                idx = ismember(app.table_batch.Data(:,1), filename);
                if sum(idx)
                    str = sprintf ('Updating %s in current batch.', filename);
                    app.table_batch.Data(idx,:) = element;
                 else
                    str = sprintf ('Adding %s to current batch.',  filename);
                    app.table_batch.Data = [app.table_batch.Data; element];
 
                end
            end
            toConsole(app, str);
        end
        
        
        function checkBatchMenu (app)
             [hObject, ~, handles] = convertToGUIDECallbackArguments(app);
             property = 'Enable';
%              if exist (app.batchFile, 'file')
%                  set(handles.batch_load, property,'On');
%              else
%                  set(handles.batch_load, property,'Off');
%              end
             if isempty(app.table_batch.Data) 
                 set(handles.batch_execute, property,'Off');
                 set(handles.batch_save, property,'Off');
                 set(handles.batch_verify, property,'Off');
             else         
                 set(handles.batch_save, property,'On');    
                 set(handles.batch_verify, property,'On');
                 if (sum(cell2mat(app.table_batch.Data(:,2))))
                     set(handles.batch_execute, property,'On'); % at least one verified
                 else
                     set(handles.batch_execute, property,'Off');
                 end
             end    
             filename = get(handles.txt_paramsFile, 'String');
             if isempty(filename)
                 set(handles.batch_add, property,'Off'); 
                 set(handles.batch_update, property,'Off'); 
             elseif isempty(app.table_batch.Data) 
                 set(handles.batch_add, property,'On');   
                 set(handles.batch_update, property,'Off');     
             elseif sum(ismember(app.table_batch.Data(:,1), filename))
                 set(handles.batch_add, property,'Off'); 
                 set(handles.batch_update, property,'On');
             else
                 set(handles.batch_add, property,'On'); 
                 set(handles.batch_update, property,'Off');
             end
             app.cmd_Execute.Enable = app.Execute.Enable;
             guidata(hObject, handles);
        end
        
        
        
        function [error, messages] = verifyBatchTable(app, silent, fix)
            error = false;
            messages = false;
            if isempty(app.table_batch.Data)
                return;
            end
            if ~silent
                toConsole(app, "Verifying batch items...");
            end
            data = app.table_batch.Data;
            for i=1:size(data, 1)
                 inputfile = cell2mat(data(i,1));
                 if ~exist (inputfile, 'file')
                     if fix
                         app.table_batch.Data(i,2) = {false};
                         str = sprintf ("Warning: '%s' updated in the batch table, because it does not exist.", inputfile);
                     else
                         str = sprintf ("Warning: '%s' does not exist anymore.", inputfile);
                     end
                     toConsole (app, str);
                     error = true;
                 else
                     params = readGaitParms (inputfile, true, app);
                     [err, overwrite] = checkParameters(app, params, true);
                     new = {inputfile ~err overwrite(1) overwrite(2) overwrite(3)};
                     if (~cell2mat(new(2)) &&  cell2mat(data(i,2))) || ...
                             ( cell2mat(new(3)) && ~cell2mat(data(i,3))) || ...
                             ( cell2mat(new(4)) && ~cell2mat(data(i,4))) || ...
                             ( cell2mat(new(5)) && ~cell2mat(data(i,5)))
                         if fix
                             if (~cell2mat(new(2)) && cell2mat(data(i,2)))
                                 app.table_batch.Data(i,2) = new(2);
                             end
                             for j=3:size(new,2)
                                 if (cell2mat(new(j)) && ~cell2mat(data(i,j)))
                                     app.table_batch.Data(i,j) = new(j);
                                 end
                             end
                             str = sprintf ("Warning: '%s' updated in the batch table to match the current settings/situation.", inputfile);
                             toConsole (app, str);
                             toConsole (app, "Reload this parameter file to see what's wrong.");
                         else
                             str = sprintf ("Warning: Parameter file '%s' does not match the current settings/situation.", inputfile);
                             toConsole (app, str);
                         end
                         error = true;
                     end
                     if (cell2mat(new(2)) && ~cell2mat(data(i,2)))
                         if ~silent
                             str = sprintf ("Parameter file '%s' not verified in current batch table, but seems okay!", inputfile);
                             toConsole (app, str);
                             toConsole (app, "You may tick the check box in the batch table if desired.");
                             messages = true;
                         end
                     end
                     if cell2mat(data(i,2)) && ...
                             ((~cell2mat(new(3)) && cell2mat(data(i,3)))  || ...
                             (~cell2mat(new(4)) && cell2mat(data(i,4)))  || ...
                             (~cell2mat(new(5)) && cell2mat(data(i,5))))
                         if ~silent
                             str = sprintf ("For parameter file '%s', some files do not need to be overwritten!", inputfile);
                             toConsole (app, str);
                             toConsole (app, "You may reload this parameter file and update the batch table if desired.");
                             messages = true;
                         end
                     end
                 end
            end
            if ~silent
                toConsole(app, "Done verifying!");
                toConsole(app, "");
            end
        end
        
        
        
        function [err, recalc_needed] = checkParameters (app, params, silent)
                           
            prevWarningState = warning ('query', 'MATLAB:load:variableNotFound');
            warning ('off', 'MATLAB:load:variableNotFound');
            
            skip = false;
            err  = false;
            recalc_needed = [false false false];
            app.fileNameLocomotionMeasures = "";
            app.fileNameAggregatedValues = "";
             
            if ~isfield(params, 'classFile')
                if ~silent
                    fprintf (app, 'No classification file (*.csv) specified in parameter file.\n');
                end
                err = true;
            elseif ~isfield(params, 'accFile')
                if ~silent
                    fprintf (app, 'No raw measurement file (*.3ac or *.omx) specified in parameter file.\n');
                end
                err = true;
            elseif exist (params.classFile, 'file') ~= 2
                if ~silent
                    fprintf (app, 'Classification file (%s) as specified in parameter file does not exist.\n', params.classFile);
                end
                err = true;
            elseif exist (params.accFile, 'file') ~= 2
                if ~silent
                    fprintf (app, 'Raw measurement file (%s) as specified in parameter file does not exist.\n', params.accFile);
                end
                err = true;
            end
     
            if err
                recalc_needed(1) = true;
                recalc_needed(2) = true;
                recalc_needed(3) = true;
            else
                params.classFile = strrep(params.classFile, '\', '/');
                params.accFile   = strrep(params.accFile,   '\', '/');
                [filepath,  name,  ~] = fileparts(params.accFile);    
                FileNameLocEps        = [filepath '/' name '_GA_Episodes' '.mat'];
                if exist (FileNameLocEps, 'file') ~= 2
                    recalc_needed(1) = true;
                    recalc_needed(2) = true;
                    recalc_needed(3) = true;
                    if ~silent
                        fprintf (app, '(Some) output files do not yet exist; (re)calculation required!\n');
                    end
                    skip = true;
                else
                    load (FileNameLocEps, 'epochLength');
                    if (~exist('epochLength', 'var') || isempty(epochLength) || ...
                        ~isfield(params, 'epochLength') || ~isEqual (app, params.epochLength, epochLength))
                        if ~silent
                            fprintf (app, "Parameter setting 'Epoch length' not compatible with existing output files; (re)calculation required.\n");
                        end
                        recalc_needed(1) = true;
                        recalc_needed(2) = true;
                        recalc_needed(3) = true;
                        skip = true;
                    end
                end
                if (~skip)
                    FileNameLocEpsMeas  = [filepath '/' name '_GA_Measures' '.mat'];
                    if exist (FileNameLocEpsMeas, 'file') ~= 2
                        recalc_needed(2) = true;
                        recalc_needed(3) = true;
                        if ~silent
                            fprintf (app, "(Some) output files do not yet exist; (re)calculation required!\n");
                        end
                        skip = true;
                    else
                        load (FileNameLocEpsMeas, 'legLength', 'locomotionMeasures');
                        if (~exist('legLength', 'var') || isempty(legLength) || ...
                            ~isfield(params, 'legLength') || ~isEqual (app, params.legLength, legLength))
                            if ~isfield(params, 'legLength')
                                 if ~silent
                                     fprintf(app, '*** Error: No leg length given! ***\n');
                                 end
                                 err = true;
                            else
                                if ~silent
                                    fprintf (app, "Parameter setting 'Leg length' not compatible with existing output files; (re)calculation required.\n");
                                end
                                recalc_needed(2) = true;
                                recalc_needed(3) = true;
                            end
                            skip = true;
                        elseif ~exist('locomotionMeasures', 'var') || length(locomotionMeasures) < 50
                            str = sprintf('Only %d episodes of at least %d seconds found (cannot reliably calculate measures).\n', length(locomotionMeasures), epochLength);
                            fprintf(app, str);
                            err  = 2;
                            skip = true;
                        else
                            app.fileNameLocomotionMeasures = FileNameLocEpsMeas;
                        end
                    end
                end    
                if (~skip)
                    FileNameAggregated = [filepath '/' name '_GA_Aggregated' '.mat'];
                    if exist (FileNameAggregated, 'file') ~= 2
                        recalc_needed(3) = true;
                        if ~silent
                            fprintf (app, "(Some) output files do not yet exist; (re)calculation required!\n");
                        end
                    else
                        load (FileNameAggregated, 'skipStartSeconds', 'percentiles', 'preferredWalkingSpeed');
                        if (~exist('skipStartSeconds', 'var') || isempty(skipStartSeconds) || ...
                            ~isfield(params, 'skipStartSeconds') || ~isEqual (app, params.skipStartSeconds, skipStartSeconds))
                            if ~silent
                               fprintf (app, "Parameter setting 'Seconds to skip at start of meaurement' not compatible with existing output files; (re)calculation required.\n");
                            end
                            recalc_needed(3) = true;
                        end       
                        if (~exist('percentiles', 'var') || isempty(percentiles) || ...
                            ~isfield(params, 'percentiles') || ~isEqual(app, params.percentiles, percentiles))
                            if ~silent
                                fprintf (app, "Parameter setting 'Percentiles' not compatible with existing output files; (re)calculation required.\n");
                            end
                            recalc_needed(3) = true;
                        end
                        if (~exist('preferredWalkingSpeed', 'var') && isfield(params, 'preferredWalkingSpeed')) || ...
                           ( exist('preferredWalkingSpeed', 'var') && isfield(params, 'preferredWalkingSpeed') && ~isEqual(app, params.preferredWalkingSpeed, preferredWalkingSpeed))
                            if ~silent
                                fprintf (app, "Parameter setting 'Preferred Walking Speed' not compatible with existing output files; (re)calculation required.\n");
                            end
                            recalc_needed(3) = true;
                        end
                        app.fileNameAggregatedValues = FileNameAggregated;
                    end
                end    
            end
            warning (prevWarningState.state, prevWarningState.identifier);
        end
        
   
        
        function check(app, ~, event)           
            [hObject, ~, handles] = convertToGUIDECallbackArguments(app);                
   
            checkBatchMenu(app);      
            drawnow();
            inputfile = get(handles.txt_paramsFile, 'String');
            FileInfo = dir(inputfile);
            TimeStamp = FileInfo.datenum;
            if app.timeStamp == TimeStamp
                return;
            end
            silent = (app.timeStamp == 1);
            app.timeStamp = TimeStamp;            
    
            if ~silent
                 fprintf (app, "%s Checking %s...", datestr(now(), 13), inputfile);
            end
            app.parmsError = false;
            params = readGaitParms (inputfile, false, app);
            [err, recalc_needed] = checkParameters(app, params, false);
            
            if err
                app.parmsError = true;
                if (err == 2) % too few valid episodes
                    set(handles.cmd_Run, 'Enable', 'On'); % allow re-run in case datafile has been changed
                else
                    set(handles.cmd_Run, 'Enable', 'Off');
                end
                app.GraphMenu.Enable = false;
                app.fileNameLocomotionMeasures = "";
                app.fileNameAggregatedValues = "";
                recalc_needed(1) = true;
                recalc_needed(2) = true;
                recalc_needed(3) = true;
            else
                set(handles.cmd_Run, 'Enable', 'On');
                app.GraphMenu.Enable = true;
                if isfield(params, 'preferredWalkingSpeed')
                    app.prefSpeed = params.preferredWalkingSpeed;
                else
                    app.prefSpeed = 0;
                end
                app.currentHour = 0;
                if app.TabGroupp.SelectedTab == app.tab_graph
                    changeTab(app, event, app.tab_graph); % force a redraw
                end
            end    
            
            if (recalc_needed(1))
                set(handles.checkbox_overwriteEpisodes, 'Value',  true);
                set(handles.checkbox_overwriteEpisodes, 'Enable', 'Off');
            else
                set(handles.checkbox_overwriteEpisodes, 'Enable', 'On');
            end
            if (recalc_needed(2))
                set(handles.checkbox_overwriteMeasures, 'Value',  true);
                set(handles.checkbox_overwriteMeasures, 'Enable', 'Off');
            else
                if ~get(handles.checkbox_overwriteEpisodes, 'Value')
                    set(handles.checkbox_overwriteMeasures, 'Enable', 'On');
                end
            end
            if (recalc_needed(3))
                set(handles.checkbox_overwriteAggValues, 'Value',  true);
                set(handles.checkbox_overwriteAggValues, 'Enable', 'Off');
            else
                if ~get(handles.checkbox_overwriteMeasures, 'Value')
                    set(handles.checkbox_overwriteAggValues, 'Enable', 'On');
                end
            end
            
            if (recalc_needed(3))                
                changeTab(app, event, app.tab_console);
            end
            if ~silent
                toConsole(app, "Done!");
                toConsole(app, "");
            end
            guidata(hObject, handles);
        end
        
        
        function stopTimer (app, obj, ~)
            ud = get(obj, 'UserData');
            debug = ud{1};
            if (debug)
                toConsole (app, 'Timer stopped');
            end
        end
        
        
        function t = checkParams(app, debug)
            if (nargin < 3)
                debug = false;
            end
            app.timeStamp = 0;
            t = timer;
            t.Period = 1;
            t.TasksToExecute = inf;
            t.ExecutionMode = 'fixedRate';
            t.TimerFcn = @app.check;
            t.StopFcn = @app.stopTimer;
            t.UserData = {debug};
            start(t);
            if (debug)
                toConsole (app, 'Timer started');
            end
        end
        
        function toConsole(app, str)
            [hObject, ~, handles] = convertToGUIDECallbackArguments(app);
            string = get (handles.txt_Console, 'String');
            if isempty(string)
                string = {str};
            else
                %string = flip(string);
                if app.pReplace
                    string{end} = str;
                else
                    string{end+1} = str;
                end
            end
            set (handles.txt_Console, 'String', string);
            % app.list_Batch.Items{end+1} = str;
            guidata(hObject, handles);
            app.pReplace = false;
            drawnow();
        end
        
        function toHelp(app, str)
            [hObject, ~, handles] = convertToGUIDECallbackArguments(app);
            string = get (handles.txt_Help, 'String');
            if isempty(string)
                string = {str};
            else
                string{end+1} = str;
            end
            set (handles.txt_Help, 'String', string);
            guidata(hObject, handles);
            drawnow();
        end
    end
    
        
    methods (Access = public)
        function fprintf(app, varargin)
            str = sprintf(varargin{:});
            str = strrep(str, newline, '\n');
            if isstring(str)
                str = char(str);
            end
            str2 = '';
%             if app.pError
%                 str2 = '<HTML><FONT color="red">'; 
%             end
            escape = false;
            len = strlength(str);
            for i=1:len
                if (str(i) == '\')
                    escape = true;
                elseif (escape)
                    escape = false;
                    if ((i<=len) && (str(i) == 'n'))
%                         if (i==len) && app.pError
%                             str2 = [str2 '</FONT></HTML>'];
%                         end
                        toConsole(app, str2);
                        str2='';
                    elseif (i<=len)
                        str2=[str2 str(i-1) str(i)];
                    else
                        str2=[str2 str(i-1)];
                    end
                else
                    str2=[str2 str(i)];
                end
            end
            if ~isempty(str2)
%                 if app.pError 
%                     str2 = [str2 '</FONT></font></HTML>'];
%                 end
                toConsole(app, str2);
            end
            app.pError = false;
        end
    end
    


    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function main_OpeningFcn(app, varargin)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app); %#ok<ASGLU>
            
            % This function has no output args, see OutputFcn.
            % hObject    handle to figure
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            % varargin   command line arguments to main (see VARARGIN)
            
            % Choose default command line output for main
            handles.output = hObject;
            
            if (ismac) 
                app.txt_Console.FontName = "PT Mono";
                app.txt_Help.FontName = "PT Mono";
            else
                app.txt_Console.FontName = "Consolas";
                app.txt_Help.FontName = "Consolas";
            end
            
            % Update handles structure
            %delete(app.tab_batch);
            delete(timerfindall);
            clc;
            set (handles.txt_Console, 'String', "");
            toConsole (app, app.versionTxt);
            toConsole (app, '');
            guidata(hObject, handles);
        end

        % Value changed function: checkbox_overwriteAggValues
        function checkbox_overwriteAggValues_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to checkbox_overwriteMeasures (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            % Hint: get(hObject,'Value') returns toggle state of checkbox_overwriteMeasures
            if (get(handles.checkbox_overwriteEpisodes, 'Value') || get(handles.checkbox_overwriteMeasures, 'Value'))
                set(handles.checkbox_overwriteAggValues, 'Value', true);
            end
            guidata(hObject,handles);
        end

        % Value changed function: checkbox_overwriteEpisodes
        function checkbox_overwriteEpisodes_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to checkbox_overwriteEpisodes (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            overwrite_episodes = get(hObject,'Value');
            if (overwrite_episodes)
                set(handles.checkbox_overwriteMeasures,  'Value',  true);
                set(handles.checkbox_overwriteMeasures,  'Enable', 'Off');
                set(handles.checkbox_overwriteAggValues, 'Value',  true);
                set(handles.checkbox_overwriteAggValues, 'Enable', 'Off');
            else
                set(handles.checkbox_overwriteMeasures, 'Enable', 'On');
                if ~get(handles.checkbox_overwriteMeasures, 'Value')
                   set(handles.checkbox_overwriteAggValues, 'Enable', 'On');
                end
                app.timeStamp = 1; % force silen recheck of parameter settings
             end
            guidata(hObject,handles);
        end

        % Value changed function: checkbox_overwriteMeasures
        function checkbox_overwriteMeasures_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to checkbox_overwriteMeasures (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            % Hint: get(hObject,'Value') returns toggle state of checkbox_overwriteMeasures
            if (get(handles.checkbox_overwriteEpisodes, 'Value'))
                set(handles.checkbox_overwriteMeasures, 'Value', true);
            end
            if (get(handles.checkbox_overwriteMeasures, 'Value'))
                set(handles.checkbox_overwriteAggValues, 'Value',  true);
                set(handles.checkbox_overwriteAggValues, 'Enable', 'Off');
            else
                set(handles.checkbox_overwriteAggValues, 'Enable', 'On');
                app.timeStamp = 1; % force silen recheck of parameter settings
            end
            guidata(hObject,handles);
        end

        % Button pushed function: cmd_Run
        function cmd_Run_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to cmd_Run (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            if get(handles.checkbox_overwriteEpisodes, 'Value')
                overwrite_files = 3;
            elseif get(handles.checkbox_overwriteMeasures, 'Value')
                overwrite_files = 2;
            elseif get(handles.checkbox_overwriteAggValues, 'Value')
                overwrite_files = 1;
            else
                overwrite_files = 0;
            end
            obj = get(handles.txt_paramsFile);
            disableAll(app);
            app.cmd_Cancel.Visible = true;
            changeTab(app, event, app.tab_console);
            app.gaitError = false;
            str = sprintf ("%s Running %s...", datestr(now(), 13), obj.String);
            toConsole (app, str);               
            gaitAnalyse(obj.String, 'class', app, 'overwriteFiles', overwrite_files);
            enableAll(app);
            if (~app.gaitError )
                set(handles.checkbox_overwriteEpisodes,  'Enable', 'On');
                set(handles.checkbox_overwriteMeasures,  'Enable', 'On');
                set(handles.checkbox_overwriteAggValues, 'Enable', 'On');
                set(handles.checkbox_overwriteEpisodes,  'Value', false);
                set(handles.checkbox_overwriteMeasures,  'Value', false);
                set(handles.checkbox_overwriteAggValues, 'Value', false);
                if (isfield(handles, 'tim') && isvalid(handles.tim))
                    app.timeStamp = 1; % force silent recheck of parameter settings
                else
                    % periodically check if params have been changed
                    handles.tim = checkParams(app);
                end
            end
            guidata(hObject,handles);
        end

        % Button pushed function: cmd_editFile
        function cmd_editFile_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to cmd_editFile (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            obj = get(handles.txt_paramsFile);
            if (exist(obj.String, 'file')) 
                if (exist('edit', 'file'))
                    edit(obj.String);
                elseif ispc
                    cmd = ['notepad ' obj.String ' &'];
                    system(cmd);
                elseif ismac
                    cmd = ['open -t "' obj.String '"'];
                    system(cmd);
                end
            end
        end

        % Button pushed function: cmd_getPath
        function cmd_getPath_Callback(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to cmd_getPath (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            [file, dir] = uigetfile('*par*.txt', 'Select parameter file');
            path = [dir file];
            if ~isequal(file, 0)
                 if exist(path, 'file')
                    set(handles.txt_paramsFile, 'String', path);
                    set(handles.cmd_editFile, 'Enable', 'On');
                    set(handles.cmd_Run, 'Enable', 'On');
                    set(handles.checkbox_overwriteEpisodes,  'Enable', 'On');
                    set(handles.checkbox_overwriteMeasures,  'Enable', 'On');
                    set(handles.checkbox_overwriteAggValues, 'Enable', 'On');
                    set(handles.checkbox_overwriteEpisodes,  'Value',  false);
                    set(handles.checkbox_overwriteMeasures,  'Value',  false);
                    set(handles.checkbox_overwriteAggValues, 'Value',  false);
                    % periodically check if params have been changed
                    if (isfield(handles, 'tim') && isvalid(handles.tim))
                        app.timeStamp = 0; % force recheck of parameter settings
                    else
                        handles.tim = checkParams(app, path);
                    end
                else
                    set(handles.checkbox_overwriteEpisodes,  'Enable', 'Off');
                    set(handles.checkbox_overwriteMeasures,  'Enable', 'Off');
                    set(handles.checkbox_overwriteAggValues, 'Enable', 'Off');
                    set(handles.cmd_Run, 'Enable', 'Off');
                    set(handles.cmd_editFile, 'Enable', 'Off');
                    set(handles.txt_paramsFile, 'String', '');
                end
                guidata(hObject,handles);
                drawnow();
            end
        end

        % Close request function: figure1
        function figure1_CloseRequestFcn(app, event)
            % Create GUIDE-style callback args - Added by Migration Tool
            [hObject, eventdata, handles] = convertToGUIDECallbackArguments(app, event); %#ok<ASGLU>
            
            % hObject    handle to figure1 (see GCBO)
            % eventdata  reserved - to be defined in a future version of MATLAB
            % handles    structure with handles and user data (see GUIDATA)
            
            % Hint: delete(hObject) closes the figure
            if (isfield(handles, 'tim') && isvalid(handles.tim))
                stop(handles.tim);
                delete(handles.tim);
            end
            delete(hObject);
        end

        % Menu selected function: ShowExampleParameters
        function ShowExampleParametersSelected(app, event)
            toHelp(app, '% Parameter settings:');
            toHelp(app, '    Classification file  = ?.csv                % mandatory!');
            toHelp(app, '    Raw measurement file = ?.OMX                % mandatory!');
            toHelp(app, '    Leg length** = 0.925                        % mandatory!'); 
            toHelp(app, '    Epoch length*** = 10                        % defaults to 10');                      
            toHelp(app, '    Hours to skip at start of measurement* = 6  % defaults to 0; hours may be replaced by seconds or minutes');  
            toHelp(app, '    Percentiles = [10 50 90]*                   % defaults to [20 50 80]');
            toHelp(app, '    % ***changing requires recalculation of locomotion episodes, locomotion measures, and aggregated values');                         
            toHelp(app, '    %  **changing requires recalculation of locomotion measures and aggregated values');                         
            toHelp(app, '    %   *changing requires recalculation of aggregated values');                         
            toHelp(app, '');
            toHelp(app, '    Get physical activity from classification   = yes % defaults to yes');
            toHelp(app, '    Minimum sensor wear time per day            = 18  % consider 12 hours if sensors are not worn at night');
            toHelp(app, '    Minimum number of valid days for activities = 2   % minimum number of days required with sufficient wear time');
            toHelp(app, '    Minimum number of valid days for lying      = 3   % idem for showing "lying" information');
            toHelp(app, '');
            toHelp(app, '% Measures that can be requested through the parameter file:');
            toHelp(app, '    Walking Speed                = yes'); 
            toHelp(app, '    Stride Length                = yes');
            toHelp(app, '    Stride Regularity*           = yes'); 
            toHelp(app, '    Sample Entropy*              = yes'); 
            toHelp(app, '    RMS*                         = yes');
            toHelp(app, '    Index Harmonicity*           = yes'); 
            toHelp(app, '    Power At Step Freq*          = yes'); 
            toHelp(app, '    Gait Quality Composite Score = yes'); 
            toHelp(app, '    Bimodal Fit Walking Speed**  = yes'); 
            toHelp(app, '    Preferred Walking Speed      = 0.96 % corresponding percentile will be reported');
            toHelp(app, '    % *Add VT, ML, or AP to request individual directions.');   
            toHelp(app, '    % **Does not always converge to the exact same solution.');
            toHelp(app, '');          
            changeTab(app, event, app.tab_help);
        end

        % Button pushed function: cmd_Clear
        function cmd_ClearPushed(app, event)
             [hObject, ~, handles] = convertToGUIDECallbackArguments(app, event);
             if (app.TabGroupp.SelectedTab == app.tab_console)
                 set (handles.txt_Console, 'String', "");
                 toConsole (app, app.versionTxt);
                 toConsole(app, "");
             elseif (app.TabGroupp.SelectedTab == app.tab_help)
                 set (handles.txt_Help, 'String', "");
             elseif (app.TabGroupp.SelectedTab == app.tab_batch)
                 if ~isempty(app.table_batch.Data)
                     opts.Interpreter ='tex';
                     opts.Default = 'No';
                     answer = questdlg('\fontsize{10}This will clear the entire batch table. Are you sure?', 'Clear batch table?', 'Yes', 'No', opts);
                     if answer == "Yes"
                         app.table_batch.Data=[];
                         checkBatchMenu(app);
                     end
                 end
             elseif (app.TabGroupp.SelectedTab == app.tab_graph)
                 app.ViewModeButtonGroup.SelectedObject = app.AllButton;
                 app.IntervalGroup.SelectedObject = app.Auto;
                 app.currentHour = 0;     
                 cla(app.UIAxes, 'reset');
                 drawGraph(app);
             end
             guidata(hObject,handles);
             drawnow();
        end

        % Menu selected function: About
        function AboutMenuSelected(app, event)
%             toHelp(app, app.versionTxt);
%             toHelp(app, 'Richard Casius (kaass@fbw.vu.nl)');
%             toHelp(app, 'Faculty of Behaviour and Movement Sciences')
%             toHelp(app, 'Vrije Universiteit Amsterdam');
%             changeTab (app, event, app.tab_help);

%            fig = uifigure;
            message = sprintf('\\fontsize{10}%s\nRichard Casius (kaass@fbw.vu.nl)\nFaculty of Behaviour and Movement Sciences\nVrije Universiteit Amsterdam', app.versionTxt);
            opts.Interpreter ='tex';
            opts.WindowStyle = 'modal';
            msgbox(message,'About',opts);
        end

        % Menu selected function: Add
        function AddMenuSelected(app, event)
            [~, ~, handles] = convertToGUIDECallbackArguments(app, event);
            if ~get(handles.batch_add, 'Enable') 
                return;
            end
            filename = get(handles.txt_paramsFile, 'String');
            if ~isempty(app.table_batch.Data) && sum(ismember(app.table_batch.Data(:,1), filename))
                toConsole (app, 'File already present in batch list (cannot add).');
                markTab (app, app.tab_console, 'green');
                return;
            end
            overwrite(1) = get(handles.checkbox_overwriteEpisodes,  'Value') > 0;
            overwrite(2) = get(handles.checkbox_overwriteMeasures,  'Value') > 0;
            overwrite(3) = get(handles.checkbox_overwriteAggValues, 'Value') > 0;
            if isempty(app.table_batch.Data)
                app.table_batch.Data = {filename ~app.parmsError overwrite(1) overwrite(2) overwrite(3)};
            else
                app.table_batch.Data = [app.table_batch.Data; {filename ~app.parmsError overwrite(1) overwrite(2) overwrite(3)}];
            end
            changeTab (app, event, app.tab_batch);
        end

        % Menu selected function: Update
        function UpdateMenuSelected(app, event)
            [~, ~, handles] = convertToGUIDECallbackArguments(app, event);
            if ~get(handles.batch_update, 'Enable') 
                return;
            end
            filename = get(handles.txt_paramsFile, 'String');
            if isempty(app.table_batch.Data) || ~sum(ismember(app.table_batch.Data(:,1), filename))
                toConsole (app, 'File not present in batch list (cannot update).');
                markTab (app, app.tab_console, 'green');
                return;
            end
            overwrite(1) = get(handles.checkbox_overwriteEpisodes,  'Value') > 0;
            overwrite(2) = get(handles.checkbox_overwriteMeasures,  'Value') > 0;
            overwrite(3) = get(handles.checkbox_overwriteAggValues, 'Value') > 0;
            app.table_batch.Data(ismember(app.table_batch.Data(:,1), filename),:) = {filename ~app.parmsError overwrite(1) overwrite(2) overwrite(3)};
            changeTab (app, event, app.tab_batch); 
        end

        % Callback function: Execute, cmd_Execute
        function ExecuteMenuSelected(app, event)
            [~, ~, handles] = convertToGUIDECallbackArguments(app, event);
            if ~get(handles.batch_execute, 'Enable') 
                return;
            end
            if isempty(app.table_batch.Data)
                toConsole (app, "Nothing to do (batch list is empty).");
                markTab (app, app.tab_console, 'green');
            else
                [error, ~] = verifyBatchTable(app, true, false);
                if error
                    changeTab(app, event, app.tab_console);
                    toConsole(app, "Batch contains error; run 'Batch | Verify' first.");
                    toConsole(app, "");
                    return;
                end
                n=0;
                len = size(app.table_batch.Data);
                for i=1:len(1)
                    if cell2mat(app.table_batch.Data(i,2))
                        n=n+1;
                    end
                end
                if n==0
                    str = "No verified files to process.";
                    toConsole(app, str);
                end
                changeTab(app, event, app.tab_console);
                % TODO Disbale all buttons
                if (n>0)
                    disableAll(app);
                    app.cmd_Cancel.Visible = true;
                    app.cmd_Run.Visible = false;
                    set(handles.cmd_Run, 'Enable', 'Off');
                    data = app.table_batch.Data;
                    for i=1:len(1)
                        if ~app.cancel
                            if cell2mat(data(i,2))
                                if cell2mat(data(i,3))
                                    overwrite_files = 3;
                                elseif cell2mat(data(i,4))
                                    overwrite_files = 2;
                                elseif cell2mat(data(i,5))
                                    overwrite_files = 1;
                                else
                                    overwrite_files = 0;
                                end
                                filename = cell2mat(data(i,1));
                                str = sprintf ("%s Processing %s (%d/%d)...", datestr(now(), 13), filename, i, n);
                                changeTab (app, event, app.tab_console);
                                toConsole(app, str);
                                gaitAnalyse(filename, 'class', app, 'overwriteFiles', overwrite_files);
                            end
                        end
                    end
                    app.cancel = false;
                    enableAll(app);
                end
                toConsole(app, "");
            end
        end

        % Menu selected function: BatchMenu
        function BatchMenuSelected(app, event)
            checkBatchMenu (app);
        end

        % Cell selection callback: table_batch
        function table_batchCellSelection(app, event)
            app.tableIndices = event.Indices(:,1);
        end

        % Menu selected function: DeleteSelectedItemsMenu
        function DeleteSelectedItemsMenuSelected(app, event)
             if ~isempty (app.tableIndices)
                 app.table_batch.Data(app.tableIndices, :) = [];
                 checkBatchMenu(app);
             end
        end

        % Selection change function: TabGroupp
        function TabGrouppSelectionChanged(app, event)
            selectedTab = app.TabGroupp.SelectedTab;
            if selectedTab == app.tab_batch
                app.cmd_Run.Visible = 'Off';
                app.cmd_Execute.Visible = 'On';
                app.cmd_Execute.Enable = app.Execute.Enable;
                app.ViewModeButtonGroup.Visible = 'Off'; 
                app.IntervalGroup.Visible = 'Off';
                app.ShowPreferredSpeedCheckBox.Visible = 'Off';
                app.ShowNumberOfEpisodesCheckBox.Visible = 'Off';
                app.NextButton.Visible = 'Off';
                app.PrevButton.Visible = 'Off';
            elseif selectedTab == app.tab_console
                app.cmd_Run.Visible = 'On';
                app.cmd_Execute.Visible = 'Off';  
                app.ViewModeButtonGroup.Visible = 'Off';
                app.IntervalGroup.Visible = 'Off';
                app.ShowPreferredSpeedCheckBox.Visible = 'Off';
                app.ShowNumberOfEpisodesCheckBox.Visible = 'Off';
                app.NextButton.Visible = 'Off';
                app.PrevButton.Visible = 'Off';
            elseif selectedTab == app.tab_help
                app.cmd_Run.Visible = 'Off';
                app.cmd_Execute.Visible = 'Off';
                app.ViewModeButtonGroup.Visible = 'Off';
                app.IntervalGroup.Visible = 'Off';
                app.ShowPreferredSpeedCheckBox.Visible = 'Off';
                app.ShowNumberOfEpisodesCheckBox.Visible = 'Off';
                app.NextButton.Visible = 'Off';
                app.PrevButton.Visible = 'Off';
            else
                app.cmd_Run.Visible = 'Off';
                app.cmd_Execute.Visible = 'Off';
            end
            if (selectedTab == app.tab_graph)
                app.cmd_Clear.Text = 'Redraw';
            else
                app.cmd_Clear.Text = 'Clear';
            end
            unMarkTab (app, selectedTab);
            drawnow();
            if selectedTab == app.tab_graph
                drawGraph(app);
            end
        end

        % Menu selected function: Save
        function SaveMenuSelected(app, event)
            select = true;
            % file = 0;
            if (select)
                sel = ['GaitBatch' '*.mat'];
                [file, dir] = uiputfile(sel, 'Select batch file (current batch will be added)');
                path = [dir file];
            else
                path = app.batchFile;
            end
            if ~select || ~isequal(file, 0)
                prevWarningState = warning ('query', 'MATLAB:load:variableNotFound');
                warning ('off', 'MATLAB:load:variableNotFound');
                % tag = "Auto saved";
                opts.Interpreter = 'tex';
                opts.WindowStyle = 'modal';
                opts.Resize = 'Off';
                message = sprintf('\\fontsize{10}Which name would you like to give this batch?');
                str = inputdlg (message, 'Batch name?', 1, "", opts);
                tag = cell2mat(str);
                if (~isempty(tag))
                    id = [tag ' (' datestr(now()) ')'];
                    if exist (path, 'file')
                        load (path, "data", "ID");
                        if ~exist('data', 'var') || isempty(data)
                            data = {app.table_batch.Data};
                        else
                            data = [data; {app.table_batch.Data}];
                        end
                        if ~exist ('ID', 'var') || isempty(ID)
                            ID = {id};
                        else
                            ID = [ID; {id}];
                        end
                    else
                        data = {app.table_batch.Data};
                        ID   = id;
                    end
                    if (size(data, 1) > app.maxBatches)
                        data = data(end-app.maxBatches+1:end);
                    end
                    if (size(ID, 1) > app.maxBatches)
                        ID = ID(end-app.maxBatches+1:end);
                    end
                    save (path, "data", "ID");
                    if ~strcmp (tag, 'Auto saved')
                        str = sprintf ("%s Batch file saved as '%s'.", datestr(now(), 13), id);
                        toConsole (app, str)
                        toConsole(app, "");
                    end
                end
                warning (prevWarningState.state, prevWarningState.identifier);
            end
        end

        % Menu selected function: Load
        function LoadMenuSelected(app, event)
            select = true;
            %file   = 0;
            if (select)
                sel = ['GaitBatch' '*.mat'];
                [file, dir] = uigetfile(sel, 'Select file to load batch from...');
                path = [dir file];
            else
                path = app.batchFile;
            end
            if ~select || ~isequal(file, 0)                
                prevWarningState = warning ('query', 'MATLAB:load:variableNotFound');
                warning ('off', 'MATLAB:load:variableNotFound');
                if exist (path, 'file')
                    load (path, "data", "ID");
                    if exist('data', 'var') && exist ('ID', 'var')
                        if ~isempty(data) && ~isempty(ID) && (size(data,1) == size(ID,1))
                            n   = size(data,1);
                            id  = strings(n,1);
                            len = 0;
                            for i=1:n
                                id(i) = ID(i,:);
                                li = strlength(id(i));
                                if li > len
                                    len = li;
                                end
                            end
                            listSize = [min(300, 2+len*6), min(200, 1+n*17)];
                            idx = listdlg('PromptString', 'Select a batch...', 'SelectionMode','single','ListString', id, 'ListSize', listSize);
                            if ~isempty(idx) && (idx > 0) && (idx <= n)
                                d = data(idx,:);
                                merge = false;
                                if ~isempty(app.table_batch.Data)
                                    opts.Interpreter ='tex';
                                    opts.Default = 'Replace';
                                    answer = questdlg('\fontsize{10}Replace the current batch or merge?', 'Replace or merge?', 'Replace','Merge', opts);
                                    if answer == "Merge"
                                        merge = true;
                                    end
                                end
                                str = sprintf ("%s Batch '%s' loaded.", datestr(now(), 13), id(idx));
                                toConsole (app, str);
                                d = d{1};
                                if (merge)
                                    for j=1:size(d,1)
                                        updateBatch(app, d(j,:));
                                    end
                                else
                                    app.table_batch.Data = d;
                                end
                                [error, messages] = verifyBatchTable(app, false, false);
                                if error || messages
                                    markTab (app, app.tab_console, 'green');
                                end
                                markTab (app, app.tab_batch, 'green');
                                checkBatchMenu(app);
                            else
                                return;
                            end
                        else
                            toConsole(app, 'Warning: Batch file is corrupt.');
                            toConsole(app, "");
                            changeTab (app, event, app.tab_console);
                        end
                    else
                        toConsole(app, 'Warning: Batch file is corrupt.');
                        toConsole(app, "");
                        changeTab (app, event, app.tab_console);
                    end
                else
                    toConsole(app, 'Warning: Batch file not found.');
                    toConsole(app, "");
                    changeTab (app, event, app.tab_console);
                end
                warning (prevWarningState.state, prevWarningState.identifier);
            end
        end

        % Menu selected function: Verify
        function VerifyMenuSelected(app, event)
            [error, messages] = verifyBatchTable(app, false, true);
            if error
                changeTab (app, event, app.tab_console);
                markTab (app, app.tab_batch, 'green');
            elseif messages
                markTab (app, app.tab_console, 'green');
            end
        end

        % Button pushed function: cmd_Cancel
        function cmd_CancelButtonPushed(app, event)
            app.cancel = true;
            app.abort = true;
            app.gaitError = true;
            app.Lamp.Color = [1 0 0];
        end

        % Cell edit callback: table_batch
        function table_batchCellEdit(app, event)
            checkBatchMenu(app);
        end

        % Menu selected function: WalkingSpeed
        function WalkingSpeedMenuSelected(app, event)
            unMarkGraphs(app);
            app.WalkingSpeed.Checked = true;
            if (app.fileNameLocomotionMeasures ~= "")
                changeTab(app, event, app.tab_graph);
            end
        end

        % Menu selected function: StrideLength
        function StrideLengthMenuSelected(app, event)
            unMarkGraphs(app);
            app.StrideLength.Checked = true; 
            if (app.fileNameLocomotionMeasures ~= "")
                changeTab(app, event, app.tab_graph);
            end
        end

        % Menu selected function: CumulativeDistance
        function CumulativeDistanceSelected(app, event)
            unMarkGraphs(app);
            app.CumulativeDistance.Checked = true;  
            if (app.fileNameLocomotionMeasures ~= "")
                changeTab(app, event, app.tab_graph);
            end
        end

        % Selection changed function: ViewModeButtonGroup
        function ViewModeButtonGroupSelectionChanged(app, event)
            drawGraph(app); 
        end

        % Button pushed function: PrevButton
        function PrevButtonPushed(app, event)
            if app.ViewModeButtonGroup.SelectedObject == app.PerDayButton
                app.currentHour = app.currentHour - 24;
            elseif app.ViewModeButtonGroup.SelectedObject == app.PerHourButton
                app.currentHour = app.currentHour - 1;
            end
            app.currentHour = max (0, app.currentHour);
            drawGraph(app);
        end

        % Button pushed function: NextButton
        function NextButtonPushed(app, event)
            if app.ViewModeButtonGroup.SelectedObject == app.PerDayButton
                app.currentHour = app.currentHour + 24;
            elseif app.ViewModeButtonGroup.SelectedObject == app.PerHourButton
                app.currentHour = app.currentHour + 1;
            end
            drawGraph(app);
        end

        % Menu selected function: StrideDuration
        function StrideDurationMenuSelected(app, event)
            unMarkGraphs(app);
            app.StrideDuration.Checked = true; 
            if (app.fileNameLocomotionMeasures ~= "")
                changeTab(app, event, app.tab_graph);
            end 
        end

        % Menu selected function: DistributionOfWalkingSpeed
        function DistributionOfWalkingSpeedMenuSelected(app, event)
            unMarkGraphs(app);
            app.DistributionOfWalkingSpeed.Checked = true; 
            if (app.fileNameLocomotionMeasures ~= "")
                changeTab(app, event, app.tab_graph);
            end
        end

        % Menu selected function: WalkingSpeedHistogram
        function WalkingSpeedHistogramMenuSelected(app, event)
            unMarkGraphs(app);
            app.WalkingSpeedHistogram.Checked = true; 
            if (app.fileNameLocomotionMeasures ~= "")
                changeTab(app, event, app.tab_graph);
            end
        end

        % Menu selected function: WalkingSpeedDensity
        function WalkingSpeedDensityMenuSelected(app, event)
            unMarkGraphs(app);
            app.WalkingSpeedDensity.Checked = true; 
            if (app.fileNameLocomotionMeasures ~= "")
                changeTab(app, event, app.tab_graph);
            end
        end

        % Selection changed function: IntervalGroup
        function IntervalGroupSelectionChanged(app, event)
            drawGraph(app);
        end

        % Value changed function: ShowPreferredSpeedCheckBox
        function ShowPreferredSpeedCheckBoxValueChanged(app, event)
            drawGraph(app);
        end

        % Value changed function: ShowNumberOfEpisodesCheckBox
        function ShowNumberOfEpisodesCheckBoxValueChanged(app, event)
            drawGraph(app);
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create figure1 and hide until all components are created
            app.figure1 = uifigure('Visible', 'off');
            app.figure1.NumberTitle = 'on';
            app.figure1.Position = [100 50 912 692];
            app.figure1.Name = 'GaitAnalysis';
            app.figure1.Resize = 'off';
            app.figure1.CloseRequestFcn = createCallbackFcn(app, @figure1_CloseRequestFcn, true);
            app.figure1.HandleVisibility = 'callback';
            app.figure1.Tag = 'figure1';

            % Create BatchMenu
            app.BatchMenu = uimenu(app.figure1);
            app.BatchMenu.MenuSelectedFcn = createCallbackFcn(app, @BatchMenuSelected, true);
            app.BatchMenu.Text = 'Batch';
            app.BatchMenu.Tag = 'menu_batch';

            % Create Add
            app.Add = uimenu(app.BatchMenu);
            app.Add.MenuSelectedFcn = createCallbackFcn(app, @AddMenuSelected, true);
            app.Add.Enable = 'off';
            app.Add.Accelerator = 'A';
            app.Add.Text = 'Add';
            app.Add.BusyAction = 'cancel';
            app.Add.Interruptible = 'off';
            app.Add.Tag = 'batch_add';

            % Create Update
            app.Update = uimenu(app.BatchMenu);
            app.Update.MenuSelectedFcn = createCallbackFcn(app, @UpdateMenuSelected, true);
            app.Update.Enable = 'off';
            app.Update.Accelerator = 'U';
            app.Update.Text = 'Update';
            app.Update.BusyAction = 'cancel';
            app.Update.Interruptible = 'off';
            app.Update.Tag = 'batch_update';

            % Create Verify
            app.Verify = uimenu(app.BatchMenu);
            app.Verify.MenuSelectedFcn = createCallbackFcn(app, @VerifyMenuSelected, true);
            app.Verify.Enable = 'off';
            app.Verify.Accelerator = 'Y';
            app.Verify.Text = 'Verify';
            app.Verify.BusyAction = 'cancel';
            app.Verify.Interruptible = 'off';
            app.Verify.Tag = 'batch_verify';

            % Create Execute
            app.Execute = uimenu(app.BatchMenu);
            app.Execute.MenuSelectedFcn = createCallbackFcn(app, @ExecuteMenuSelected, true);
            app.Execute.Enable = 'off';
            app.Execute.Accelerator = 'X';
            app.Execute.Text = 'Execute';
            app.Execute.BusyAction = 'cancel';
            app.Execute.Tag = 'batch_execute';

            % Create Load
            app.Load = uimenu(app.BatchMenu);
            app.Load.MenuSelectedFcn = createCallbackFcn(app, @LoadMenuSelected, true);
            app.Load.Text = 'Load';
            app.Load.BusyAction = 'cancel';
            app.Load.Interruptible = 'off';
            app.Load.Tag = 'batch_load';

            % Create Save
            app.Save = uimenu(app.BatchMenu);
            app.Save.MenuSelectedFcn = createCallbackFcn(app, @SaveMenuSelected, true);
            app.Save.Enable = 'off';
            app.Save.Text = 'Save';
            app.Save.BusyAction = 'cancel';
            app.Save.Interruptible = 'off';
            app.Save.Tag = 'batch_save';

            % Create GraphMenu
            app.GraphMenu = uimenu(app.figure1);
            app.GraphMenu.Enable = 'off';
            app.GraphMenu.Text = 'Graph';

            % Create CumulativeDistance
            app.CumulativeDistance = uimenu(app.GraphMenu);
            app.CumulativeDistance.MenuSelectedFcn = createCallbackFcn(app, @CumulativeDistanceSelected, true);
            app.CumulativeDistance.Checked = 'on';
            app.CumulativeDistance.Text = 'Cumulative Distance';

            % Create WalkingSpeed
            app.WalkingSpeed = uimenu(app.GraphMenu);
            app.WalkingSpeed.MenuSelectedFcn = createCallbackFcn(app, @WalkingSpeedMenuSelected, true);
            app.WalkingSpeed.Text = 'Walking Speed';
            app.WalkingSpeed.Tag = 'graph_walkingSpeed';

            % Create StrideDuration
            app.StrideDuration = uimenu(app.GraphMenu);
            app.StrideDuration.MenuSelectedFcn = createCallbackFcn(app, @StrideDurationMenuSelected, true);
            app.StrideDuration.Text = 'Stride Duration';

            % Create StrideLength
            app.StrideLength = uimenu(app.GraphMenu);
            app.StrideLength.MenuSelectedFcn = createCallbackFcn(app, @StrideLengthMenuSelected, true);
            app.StrideLength.Text = 'Stride Length';
            app.StrideLength.Tag = 'grpah_strideLength';

            % Create DistributionOfWalkingSpeed
            app.DistributionOfWalkingSpeed = uimenu(app.GraphMenu);
            app.DistributionOfWalkingSpeed.MenuSelectedFcn = createCallbackFcn(app, @DistributionOfWalkingSpeedMenuSelected, true);
            app.DistributionOfWalkingSpeed.Text = 'Distribution of Walking Speed';

            % Create WalkingSpeedHistogram
            app.WalkingSpeedHistogram = uimenu(app.GraphMenu);
            app.WalkingSpeedHistogram.MenuSelectedFcn = createCallbackFcn(app, @WalkingSpeedHistogramMenuSelected, true);
            app.WalkingSpeedHistogram.Text = 'Walking Speed (Histogram)';

            % Create WalkingSpeedDensity
            app.WalkingSpeedDensity = uimenu(app.GraphMenu);
            app.WalkingSpeedDensity.MenuSelectedFcn = createCallbackFcn(app, @WalkingSpeedDensityMenuSelected, true);
            app.WalkingSpeedDensity.Text = 'Walking Speed (Density)';

            % Create HelpMenu
            app.HelpMenu = uimenu(app.figure1);
            app.HelpMenu.Text = 'Help';
            app.HelpMenu.Tag = 'menu_help';

            % Create ShowExampleParameters
            app.ShowExampleParameters = uimenu(app.HelpMenu);
            app.ShowExampleParameters.MenuSelectedFcn = createCallbackFcn(app, @ShowExampleParametersSelected, true);
            app.ShowExampleParameters.Accelerator = 'P';
            app.ShowExampleParameters.Text = 'Show Example Parameters';
            app.ShowExampleParameters.HandleVisibility = 'callback';
            app.ShowExampleParameters.BusyAction = 'cancel';
            app.ShowExampleParameters.Interruptible = 'off';
            app.ShowExampleParameters.Tag = 'show_measures';

            % Create About
            app.About = uimenu(app.HelpMenu);
            app.About.MenuSelectedFcn = createCallbackFcn(app, @AboutMenuSelected, true);
            app.About.Text = 'About';
            app.About.Tag = 'about';

            % Create txt_paramsFile
            app.txt_paramsFile = uilabel(app.figure1);
            app.txt_paramsFile.Tag = 'txt_paramsFile';
            app.txt_paramsFile.VerticalAlignment = 'top';
            app.txt_paramsFile.FontSize = 14;
            app.txt_paramsFile.Position = [208 568 695 73];
            app.txt_paramsFile.Text = '';

            % Create cmd_getPath
            app.cmd_getPath = uibutton(app.figure1, 'push');
            app.cmd_getPath.ButtonPushedFcn = createCallbackFcn(app, @cmd_getPath_Callback, true);
            app.cmd_getPath.Tag = 'cmd_getPath';
            app.cmd_getPath.BackgroundColor = [0.8 0.8 0.8];
            app.cmd_getPath.FontSize = 15;
            app.cmd_getPath.Position = [17 614 171 29];
            app.cmd_getPath.Text = 'Load Parameter File';

            % Create txt_Title
            app.txt_Title = uilabel(app.figure1);
            app.txt_Title.Tag = 'txt_Title';
            app.txt_Title.HorizontalAlignment = 'center';
            app.txt_Title.VerticalAlignment = 'top';
            app.txt_Title.FontSize = 24;
            app.txt_Title.FontColor = [0 0.450980392156863 0.741176470588235];
            app.txt_Title.Position = [0 656 903 32];
            app.txt_Title.Text = 'Gait Analysis Toolbox';

            % Create cmd_Run
            app.cmd_Run = uibutton(app.figure1, 'push');
            app.cmd_Run.ButtonPushedFcn = createCallbackFcn(app, @cmd_Run_Callback, true);
            app.cmd_Run.BusyAction = 'cancel';
            app.cmd_Run.Tag = 'cmd_Run';
            app.cmd_Run.BackgroundColor = [0.8 0.8 0.8];
            app.cmd_Run.FontSize = 18;
            app.cmd_Run.FontColor = [1 0 0];
            app.cmd_Run.Enable = 'off';
            app.cmd_Run.Position = [413 15 96 33];
            app.cmd_Run.Text = 'Run';

            % Create cmd_editFile
            app.cmd_editFile = uibutton(app.figure1, 'push');
            app.cmd_editFile.ButtonPushedFcn = createCallbackFcn(app, @cmd_editFile_Callback, true);
            app.cmd_editFile.BusyAction = 'cancel';
            app.cmd_editFile.Interruptible = 'off';
            app.cmd_editFile.Tag = 'cmd_editFile';
            app.cmd_editFile.BackgroundColor = [0.8 0.8 0.8];
            app.cmd_editFile.FontSize = 15;
            app.cmd_editFile.Enable = 'off';
            app.cmd_editFile.Position = [17 569 171 29];
            app.cmd_editFile.Text = 'Edit Parameter File';

            % Create checkbox_overwriteEpisodes
            app.checkbox_overwriteEpisodes = uicheckbox(app.figure1);
            app.checkbox_overwriteEpisodes.ValueChangedFcn = createCallbackFcn(app, @checkbox_overwriteEpisodes_Callback, true);
            app.checkbox_overwriteEpisodes.Tag = 'checkbox_overwriteEpisodes';
            app.checkbox_overwriteEpisodes.Enable = 'off';
            app.checkbox_overwriteEpisodes.Tooltip = {'Changing parameters may require recalculation of the locomotion episodes (see Help | Show example parameters). If locomotion episodes are recalculated, the locomotion measures and aggregated values also have te be recalcutated.'};
            app.checkbox_overwriteEpisodes.Text = '(Over)write locomotion episodes';
            app.checkbox_overwriteEpisodes.FontSize = 14;
            app.checkbox_overwriteEpisodes.Position = [17 525 257 23];

            % Create checkbox_overwriteMeasures
            app.checkbox_overwriteMeasures = uicheckbox(app.figure1);
            app.checkbox_overwriteMeasures.ValueChangedFcn = createCallbackFcn(app, @checkbox_overwriteMeasures_Callback, true);
            app.checkbox_overwriteMeasures.Tag = 'checkbox_overwriteMeasures';
            app.checkbox_overwriteMeasures.Enable = 'off';
            app.checkbox_overwriteMeasures.Tooltip = {'Changing parameters (or recalculation of the locomotion episodes) may require recalculation of the locomotion measures (see Help | Show example parameters). If locomotion measures are recalculated, the aggregated values  also have te be recalcutated.'};
            app.checkbox_overwriteMeasures.Text = '(Over)write locomotion measures';
            app.checkbox_overwriteMeasures.FontSize = 14;
            app.checkbox_overwriteMeasures.Position = [17 501 257 23];

            % Create checkbox_overwriteAggValues
            app.checkbox_overwriteAggValues = uicheckbox(app.figure1);
            app.checkbox_overwriteAggValues.ValueChangedFcn = createCallbackFcn(app, @checkbox_overwriteAggValues_Callback, true);
            app.checkbox_overwriteAggValues.Tag = 'checkbox_overwriteAggValues';
            app.checkbox_overwriteAggValues.Enable = 'off';
            app.checkbox_overwriteAggValues.Tooltip = {'Changing parameters (or recalculation of the locomotion measures) may require recalculation of the aggregated values (see Help | Show example parameters). '};
            app.checkbox_overwriteAggValues.Text = '(Over)write aggregated values';
            app.checkbox_overwriteAggValues.FontSize = 14;
            app.checkbox_overwriteAggValues.Position = [17 477 257 23];

            % Create TabGroupp
            app.TabGroupp = uitabgroup(app.figure1);
            app.TabGroupp.SelectionChangedFcn = createCallbackFcn(app, @TabGrouppSelectionChanged, true);
            app.TabGroupp.Position = [13 56 890 402];

            % Create tab_console
            app.tab_console = uitab(app.TabGroupp);
            app.tab_console.Title = 'Console';
            app.tab_console.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create ConsoleTextAreaLabel
            app.ConsoleTextAreaLabel = uilabel(app.tab_console);
            app.ConsoleTextAreaLabel.BackgroundColor = [0.9412 0.9412 0.9412];
            app.ConsoleTextAreaLabel.HorizontalAlignment = 'right';
            app.ConsoleTextAreaLabel.FontName = 'Consolas';
            app.ConsoleTextAreaLabel.Visible = 'off';
            app.ConsoleTextAreaLabel.Position = [16 291 52 22];
            app.ConsoleTextAreaLabel.Text = 'Console';

            % Create txt_Console
            app.txt_Console = uitextarea(app.tab_console);
            app.txt_Console.Tag = 'txt_Console';
            app.txt_Console.Editable = 'off';
            app.txt_Console.FontName = 'Consolas';
            app.txt_Console.BackgroundColor = [0.9412 0.9412 0.9412];
            app.txt_Console.Position = [6 14 875 352];

            % Create tab_batch
            app.tab_batch = uitab(app.TabGroupp);
            app.tab_batch.Title = 'Batch';
            app.tab_batch.BackgroundColor = [0.9412 0.9412 0.9412];

            % Create table_batch
            app.table_batch = uitable(app.tab_batch);
            app.table_batch.ColumnName = {'Parameter file'; 'Verified'; 'Overwrite episodes'; 'Overwrite measures'; 'Overwrite agg. values'};
            app.table_batch.ColumnWidth = {383, 70, 140, 140, 140};
            app.table_batch.RowName = {};
            app.table_batch.ColumnSortable = [true true false false false];
            app.table_batch.ColumnEditable = [false true false false false];
            app.table_batch.RowStriping = 'off';
            app.table_batch.CellEditCallback = createCallbackFcn(app, @table_batchCellEdit, true);
            app.table_batch.CellSelectionCallback = createCallbackFcn(app, @table_batchCellSelection, true);
            app.table_batch.Tag = 'table_batch';
            app.table_batch.Position = [6 14 875 352];

            % Create tab_graph
            app.tab_graph = uitab(app.TabGroupp);
            app.tab_graph.Title = 'Graph';

            % Create UIAxes
            app.UIAxes = uiaxes(app.tab_graph);
            title(app.UIAxes, 'No valid data')
            xlabel(app.UIAxes, '')
            ylabel(app.UIAxes, '')
            app.UIAxes.PlotBoxAspectRatio = [1.97212543554007 1 1];
            app.UIAxes.YTick = [0 0.2 0.4 0.6 0.8 1];
            app.UIAxes.Interruptible = 'off';
            app.UIAxes.Position = [39 14 613 342];

            % Create ViewModeButtonGroup
            app.ViewModeButtonGroup = uibuttongroup(app.tab_graph);
            app.ViewModeButtonGroup.SelectionChangedFcn = createCallbackFcn(app, @ViewModeButtonGroupSelectionChanged, true);
            app.ViewModeButtonGroup.TitlePosition = 'centertop';
            app.ViewModeButtonGroup.Title = 'View Mode';
            app.ViewModeButtonGroup.Visible = 'off';
            app.ViewModeButtonGroup.Position = [694 184 101 108];

            % Create AllButton
            app.AllButton = uitogglebutton(app.ViewModeButtonGroup);
            app.AllButton.Text = 'All';
            app.AllButton.Position = [15 55 71 22];
            app.AllButton.Value = true;

            % Create PerDayButton
            app.PerDayButton = uitogglebutton(app.ViewModeButtonGroup);
            app.PerDayButton.Text = 'Per day';
            app.PerDayButton.Position = [15 34 71 22];

            % Create PerHourButton
            app.PerHourButton = uitogglebutton(app.ViewModeButtonGroup);
            app.PerHourButton.Text = 'Per hour';
            app.PerHourButton.Position = [15 13 71 22];

            % Create NextButton
            app.NextButton = uibutton(app.tab_graph, 'push');
            app.NextButton.ButtonPushedFcn = createCallbackFcn(app, @NextButtonPushed, true);
            app.NextButton.Visible = 'off';
            app.NextButton.Position = [748 139 55 22];
            app.NextButton.Text = 'Next';

            % Create PrevButton
            app.PrevButton = uibutton(app.tab_graph, 'push');
            app.PrevButton.ButtonPushedFcn = createCallbackFcn(app, @PrevButtonPushed, true);
            app.PrevButton.Visible = 'off';
            app.PrevButton.Position = [685 139 60 22];
            app.PrevButton.Text = 'Prev';

            % Create IntervalGroup
            app.IntervalGroup = uibuttongroup(app.tab_graph);
            app.IntervalGroup.SelectionChangedFcn = createCallbackFcn(app, @IntervalGroupSelectionChanged, true);
            app.IntervalGroup.TitlePosition = 'centertop';
            app.IntervalGroup.Title = 'Interval Size';
            app.IntervalGroup.Visible = 'off';
            app.IntervalGroup.Position = [694 165 101 127];

            % Create Auto
            app.Auto = uitogglebutton(app.IntervalGroup);
            app.Auto.Text = 'Auto';
            app.Auto.Position = [15 74 72 22];
            app.Auto.Value = true;

            % Create d02
            app.d02 = uitogglebutton(app.IntervalGroup);
            app.d02.Text = '0.02';
            app.d02.Position = [15 53 72 22];

            % Create d05
            app.d05 = uitogglebutton(app.IntervalGroup);
            app.d05.Text = '0.05';
            app.d05.Position = [15 32 72 22];

            % Create d1
            app.d1 = uitogglebutton(app.IntervalGroup);
            app.d1.Text = '0.1';
            app.d1.Position = [15 11 72 22];

            % Create ShowPreferredSpeedCheckBox
            app.ShowPreferredSpeedCheckBox = uicheckbox(app.tab_graph);
            app.ShowPreferredSpeedCheckBox.ValueChangedFcn = createCallbackFcn(app, @ShowPreferredSpeedCheckBoxValueChanged, true);
            app.ShowPreferredSpeedCheckBox.Visible = 'off';
            app.ShowPreferredSpeedCheckBox.Text = 'Show preferred speed';
            app.ShowPreferredSpeedCheckBox.Position = [679 110 140 22];
            app.ShowPreferredSpeedCheckBox.Value = true;

            % Create ShowNumberOfEpisodesCheckBox
            app.ShowNumberOfEpisodesCheckBox = uicheckbox(app.tab_graph);
            app.ShowNumberOfEpisodesCheckBox.ValueChangedFcn = createCallbackFcn(app, @ShowNumberOfEpisodesCheckBoxValueChanged, true);
            app.ShowNumberOfEpisodesCheckBox.Visible = 'off';
            app.ShowNumberOfEpisodesCheckBox.Text = 'Show number of epochs';
            app.ShowNumberOfEpisodesCheckBox.Position = [679 136 151 22];

            % Create tab_help
            app.tab_help = uitab(app.TabGroupp);
            app.tab_help.Title = 'Help';

            % Create ConsoleTextAreaLabel_2
            app.ConsoleTextAreaLabel_2 = uilabel(app.tab_help);
            app.ConsoleTextAreaLabel_2.HorizontalAlignment = 'right';
            app.ConsoleTextAreaLabel_2.FontName = 'Consolas';
            app.ConsoleTextAreaLabel_2.Visible = 'off';
            app.ConsoleTextAreaLabel_2.Position = [16 291 52 22];
            app.ConsoleTextAreaLabel_2.Text = 'Console';

            % Create txt_Help
            app.txt_Help = uitextarea(app.tab_help);
            app.txt_Help.Tag = 'txt_Help';
            app.txt_Help.Editable = 'off';
            app.txt_Help.FontName = 'Consolas';
            app.txt_Help.Position = [6 14 875 352];

            % Create cmd_Clear
            app.cmd_Clear = uibutton(app.figure1, 'push');
            app.cmd_Clear.ButtonPushedFcn = createCallbackFcn(app, @cmd_ClearPushed, true);
            app.cmd_Clear.BusyAction = 'cancel';
            app.cmd_Clear.Interruptible = 'off';
            app.cmd_Clear.Tag = 'cmd_Clear';
            app.cmd_Clear.Position = [835 26 51 22];
            app.cmd_Clear.Text = 'Clear';

            % Create LampLabel
            app.LampLabel = uilabel(app.figure1);
            app.LampLabel.HorizontalAlignment = 'right';
            app.LampLabel.Position = [1 26 25 22];
            app.LampLabel.Text = '';

            % Create Lamp
            app.Lamp = uilamp(app.figure1);
            app.Lamp.Position = [32 27 21 21];
            app.Lamp.Color = [0 0.302 0];

            % Create cmd_Cancel
            app.cmd_Cancel = uibutton(app.figure1, 'push');
            app.cmd_Cancel.ButtonPushedFcn = createCallbackFcn(app, @cmd_CancelButtonPushed, true);
            app.cmd_Cancel.Interruptible = 'off';
            app.cmd_Cancel.Tag = 'cmd_Cancel';
            app.cmd_Cancel.BackgroundColor = [0.8 0.8 0.8];
            app.cmd_Cancel.FontSize = 18;
            app.cmd_Cancel.FontColor = [1 0 0];
            app.cmd_Cancel.Visible = 'off';
            app.cmd_Cancel.Position = [413 15 96 33];
            app.cmd_Cancel.Text = 'Cancel';

            % Create cmd_Execute
            app.cmd_Execute = uibutton(app.figure1, 'push');
            app.cmd_Execute.ButtonPushedFcn = createCallbackFcn(app, @ExecuteMenuSelected, true);
            app.cmd_Execute.BusyAction = 'cancel';
            app.cmd_Execute.Tag = 'cmd_Execute';
            app.cmd_Execute.BackgroundColor = [0.8 0.8 0.8];
            app.cmd_Execute.FontSize = 18;
            app.cmd_Execute.FontColor = [1 0 0];
            app.cmd_Execute.Enable = 'off';
            app.cmd_Execute.Visible = 'off';
            app.cmd_Execute.Position = [412.5 15 96 33];
            app.cmd_Execute.Text = 'Execute';

            % Create ContextMenuBatchTable
            app.ContextMenuBatchTable = uicontextmenu(app.figure1);
            
            % Assign app.ContextMenuBatchTable
            app.table_batch.ContextMenu = app.ContextMenuBatchTable;

            % Create DeleteSelectedItemsMenu
            app.DeleteSelectedItemsMenu = uimenu(app.ContextMenuBatchTable);
            app.DeleteSelectedItemsMenu.MenuSelectedFcn = createCallbackFcn(app, @DeleteSelectedItemsMenuSelected, true);
            app.DeleteSelectedItemsMenu.Text = 'Delete Selected Item(s)';
            app.DeleteSelectedItemsMenu.BusyAction = 'cancel';
            app.DeleteSelectedItemsMenu.Interruptible = 'off';

            % Show the figure after all components are created
            app.figure1.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = gaitAnalysis(varargin)

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.figure1)

            % Execute the startup function
            runStartupFcn(app, @(app)main_OpeningFcn(app, varargin{:}))

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.figure1)
        end
    end
end