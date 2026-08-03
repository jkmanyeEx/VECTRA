classdef VectraTelemetryApp < handle
    %VECTRATELEMETRYAPP Passive PX4 telemetry logging and monitoring GUI.

    properties (SetAccess = private)
        Figure
    end

    properties (Access = private)
        Monitor
        Source = []
        Logger = []
        UiTimer = []
        TestMode (1,1) logical = false

        SourceDropDown
        VehicleDropDown
        GeometryDropDown
        ExperimentDropDown
        PortField
        HardwareCheckButton
        ConnectButton
        RecordButton
        RunIdLabel
        ConnectionBadge
        VehicleBadge
        RecordingBadge
        SimulatedBanner
        ChannelTable
        EventArea
        SummaryLabels

        AttitudeAxes
        PositionAxes
        BatteryAxes
        MotorAxes
        AttitudeLines
        PositionLines
        BatteryLines
        MotorBars

        LastPlottedRevision uint64 = 0
        History
        EventLines string = strings(0, 1)
        FirstDataUnixSec (1,1) double = NaN
    end

    properties (Constant, Access = private)
        Background = [0.045, 0.045, 0.045]
        Surface = [0.070, 0.070, 0.070]
        SurfaceRaised = [0.105, 0.105, 0.105]
        Border = [0.185, 0.185, 0.185]
        TextPrimary = [0.94, 0.94, 0.94]
        TextMuted = [0.64, 0.64, 0.64]
        Accent = [0.43, 0.64, 0.56]
        AccentMuted = [0.35, 0.46, 0.42]
        Amber = [0.78, 0.61, 0.34]
        Red = [0.80, 0.38, 0.38]
        UiFont = "Helvetica Neue"
        DataFont = "Menlo"
    end

    methods
        function app = VectraTelemetryApp(options)
            arguments
                options.Visible (1,1) string = "on"
                options.TestMode (1,1) logical = false
                options.AutoConnectSimulated (1,1) logical = false
            end

            app.TestMode = options.TestMode;
            app.Monitor = vectra.px4.TelemetryMonitor();
            app.resetHistory();
            app.buildInterface(options.Visible);
            app.UiTimer = timer( ...
                ExecutionMode="fixedRate", ...
                Period=0.1, ...
                BusyMode="drop", ...
                TimerFcn=@(~, ~)app.updateInterface());
            start(app.UiTimer);
            app.addEvent("INFO", "VECTRA telemetry console ready");

            if options.AutoConnectSimulated
                app.SourceDropDown.Value = "Simulated";
                app.connectSource();
            end
        end

        function delete(app)
            app.cleanup();
            if ~isempty(app.Figure) && isvalid(app.Figure)
                app.Figure.CloseRequestFcn = "";
                delete(app.Figure);
            end
        end
    end

    methods (Access = private)
        function buildInterface(app, visibility)
            app.Figure = uifigure( ...
                Name="VECTRA // PX4 Telemetry Console", ...
                Position=[80, 70, 1510, 930], ...
                Color=app.Background, ...
                Visible=visibility, ...
                CloseRequestFcn=@(~, ~)app.closeRequested());

            root = uigridlayout(app.Figure, [3, 3]);
            root.Padding = [18, 16, 18, 16];
            root.RowSpacing = 12;
            root.ColumnSpacing = 12;
            root.RowHeight = {64, "1x", 178};
            root.ColumnWidth = {274, "1x", 330};
            root.BackgroundColor = app.Background;

            app.buildHeader(root);
            app.buildRunPanel(root);
            app.buildCharts(root);
            app.buildQualityPanel(root);
            app.buildEventPanel(root);
        end

        function buildHeader(app, root)
            panel = uipanel(root, ...
                BackgroundColor=app.Surface, ...
                BorderColor=app.Border, ...
                HighlightColor=app.Border);
            panel.Layout.Row = 1;
            panel.Layout.Column = [1, 3];
            grid = uigridlayout(panel, [1, 5]);
            grid.Padding = [18, 10, 18, 10];
            grid.ColumnWidth = {245, 130, 145, 150, "1x"};
            grid.ColumnSpacing = 12;
            grid.BackgroundColor = app.Surface;

            brand = uilabel(grid, ...
                Text="VECTRA", ...
                FontName=app.UiFont, ...
                FontSize=24, ...
                FontWeight="bold", ...
                FontColor=app.TextPrimary);
            brand.Layout.Column = 1;

            app.ConnectionBadge = app.makeBadge(grid, ...
                "● DISCONNECTED", app.TextMuted);
            app.VehicleBadge = app.makeBadge(grid, ...
                "SYS -- / COMP --", app.TextMuted);
            app.RecordingBadge = app.makeBadge(grid, ...
                "○ NOT RECORDING", app.TextMuted);

            app.SimulatedBanner = uilabel(grid, ...
                Text="", ...
                HorizontalAlignment="center", ...
                FontSize=12, ...
                FontWeight="bold", ...
                FontColor=app.Amber);
            app.SimulatedBanner.Layout.Column = 5;
        end

        function buildRunPanel(app, root)
            panel = app.makePanel(root, "RUN CONFIGURATION");
            panel.Layout.Row = 2;
            panel.Layout.Column = 1;
            grid = uigridlayout(panel, [16, 1]);
            grid.Padding = [16, 16, 16, 16];
            grid.RowSpacing = 8;
            grid.RowHeight = { ...
                18, 34, 18, 34, 18, 34, 18, 34, ...
                18, 34, 40, 44, 44, 18, 50, "1x"};
            grid.BackgroundColor = app.Surface;

            app.makeFieldLabel(grid, "SOURCE");
            app.SourceDropDown = uidropdown(grid, ...
                Items=["PX4 Hardware", "Simulated"], ...
                Value="PX4 Hardware", ...
                ValueChangedFcn=@(~, ~)app.sourceSelectionChanged());
            app.styleInput(app.SourceDropDown);

            app.makeFieldLabel(grid, "VEHICLE PROFILE");
            app.VehicleDropDown = uidropdown(grid, ...
                Items=profileNames("vehicles"), Value="main_quad");
            app.styleInput(app.VehicleDropDown);

            app.makeFieldLabel(grid, "GEOMETRY PROFILE");
            app.GeometryDropDown = uidropdown(grid, ...
                Items=profileNames("geometries"), Value="cant_00");
            app.styleInput(app.GeometryDropDown);

            app.makeFieldLabel(grid, "EXPERIMENT PROFILE");
            app.ExperimentDropDown = uidropdown(grid, ...
                Items=profileNames("experiments"), Value="smoke_hover");
            app.styleInput(app.ExperimentDropDown);

            app.makeFieldLabel(grid, "LOCAL UDP PORT");
            app.PortField = uieditfield(grid, "numeric", ...
                Value=14551, ...
                Limits=[1024, 65535], ...
                ValueDisplayFormat="%.0f", ...
                RoundFractionalValues=true);
            app.styleInput(app.PortField);

            app.HardwareCheckButton = uibutton(grid, "push", ...
                Text="CHECK HARDWARE", ...
                ButtonPushedFcn=@(~, ~)app.runHardwareCheck(), ...
                BackgroundColor=app.SurfaceRaised, ...
                FontColor=app.TextPrimary, ...
                FontWeight="bold", ...
                FontSize=11);

            app.ConnectButton = uibutton(grid, "push", ...
                Text="CONNECT LISTENER", ...
                ButtonPushedFcn=@(~, ~)app.connectButtonPressed(), ...
                BackgroundColor=app.Accent, ...
                FontColor=app.Background, ...
                FontWeight="bold", ...
                FontSize=12);
            app.RecordButton = uibutton(grid, "push", ...
                Text="START RECORDING", ...
                Enable="off", ...
                ButtonPushedFcn=@(~, ~)app.recordButtonPressed(), ...
                BackgroundColor=app.SurfaceRaised, ...
                FontColor=app.TextMuted, ...
                FontWeight="bold", ...
                FontSize=12);

            app.makeFieldLabel(grid, "RUN OUTPUT");
            app.RunIdLabel = uilabel(grid, ...
                Text="No active recording", ...
                WordWrap="on", ...
                VerticalAlignment="top", ...
                FontName=app.UiFont, ...
                FontSize=10, ...
                FontColor=app.TextMuted);

            uilabel(grid, ...
                Text=["PASSIVE RECEIVE ONLY" newline ...
                "No arm, mode, mission, parameter, or actuator commands."], ...
                WordWrap="on", ...
                VerticalAlignment="bottom", ...
                FontSize=10, ...
                FontColor=app.TextMuted);
        end

        function buildCharts(app, root)
            panel = app.makePanel(root, "LIVE FLIGHT STATE");
            panel.Layout.Row = 2;
            panel.Layout.Column = 2;
            grid = uigridlayout(panel, [3, 2]);
            grid.Padding = [12, 12, 12, 12];
            grid.RowSpacing = 10;
            grid.ColumnSpacing = 10;
            grid.RowHeight = {62, "1x", "1x"};
            grid.ColumnWidth = {"1x", "1x"};
            grid.BackgroundColor = app.Surface;

            summaryPanel = uipanel(grid, ...
                BackgroundColor=app.SurfaceRaised, ...
                BorderColor=app.Border);
            summaryPanel.Layout.Row = 1;
            summaryPanel.Layout.Column = [1, 2];
            summaryGrid = uigridlayout(summaryPanel, [1, 5]);
            summaryGrid.Padding = [12, 7, 12, 7];
            summaryGrid.ColumnSpacing = 10;
            summaryGrid.BackgroundColor = app.SurfaceRaised;
            summaryNames = ["ROLL", "PITCH", "YAW", "ALTITUDE", "BATTERY"];
            app.SummaryLabels = gobjects(1, numel(summaryNames));
            for index = 1:numel(summaryNames)
                card = uilabel(summaryGrid, ...
                    Text=summaryNames(index) + newline + "—", ...
                    HorizontalAlignment="center", ...
                    FontName=app.UiFont, ...
                    FontSize=12, ...
                    FontWeight="bold", ...
                    FontColor=app.TextPrimary);
                app.SummaryLabels(index) = card;
            end

            app.AttitudeAxes = app.makeAxes(grid, ...
                2, 1, "ATTITUDE", "deg");
            app.AttitudeAxes.YLim = [-180, 180];
            app.AttitudeAxes.YTick = -180:90:180;
            hold(app.AttitudeAxes, "on");
            app.AttitudeLines = [
                plot(app.AttitudeAxes, NaN, NaN, ...
                    Color=app.Accent, LineWidth=1.6)
                plot(app.AttitudeAxes, NaN, NaN, ...
                    Color=app.AccentMuted, LineWidth=1.6)
                plot(app.AttitudeAxes, NaN, NaN, ...
                    Color=app.Amber, LineWidth=1.6)
            ];
            legend(app.AttitudeAxes, ["Roll", "Pitch", "Yaw"], ...
                Location="northwest", TextColor=app.TextMuted, ...
                Color="none", Box="off");

            app.PositionAxes = app.makeAxes(grid, ...
                2, 2, "LOCAL POSITION", "m");
            hold(app.PositionAxes, "on");
            app.PositionLines = [
                plot(app.PositionAxes, NaN, NaN, ...
                    Color=app.Accent, LineWidth=1.6)
                plot(app.PositionAxes, NaN, NaN, ...
                    Color=app.AccentMuted, LineWidth=1.6)
                plot(app.PositionAxes, NaN, NaN, ...
                    Color=app.Amber, LineWidth=1.6)
            ];
            legend(app.PositionAxes, ["X · North", "Y · East", "Z · Up"], ...
                Location="northwest", TextColor=app.TextMuted, ...
                Color="none", Box="off");

            app.BatteryAxes = app.makeAxes(grid, ...
                3, 1, "BATTERY", "V / A");
            hold(app.BatteryAxes, "on");
            app.BatteryLines = [
                plot(app.BatteryAxes, NaN, NaN, ...
                    Color=app.Accent, LineWidth=1.8)
                plot(app.BatteryAxes, NaN, NaN, ...
                    Color=app.Amber, LineWidth=1.5)
            ];
            legend(app.BatteryAxes, ["Voltage", "Current"], ...
                Location="northwest", TextColor=app.TextMuted, ...
                Color="none", Box="off");

            app.MotorAxes = app.makeAxes(grid, ...
                3, 2, "PWM OUTPUTS 1–4", "PWM µs");
            app.MotorBars = bar(app.MotorAxes, 1:4, zeros(1, 4), ...
                FaceColor=app.Accent, ...
                EdgeColor="none", ...
                FaceAlpha=0.85);
            app.MotorBars.BaseValue = 900;
            app.MotorAxes.XTick = 1:4;
            app.MotorAxes.XTickLabel = [ ...
                "OUT 1", "OUT 2", "OUT 3", "OUT 4"];
            xlabel(app.MotorAxes, "");
            app.MotorAxes.YLim = [900, 2100];
            app.MotorAxes.YTick = 1000:250:2000;
        end

        function buildQualityPanel(app, root)
            panel = app.makePanel(root, "DATA QUALITY");
            panel.Layout.Row = 2;
            panel.Layout.Column = 3;
            grid = uigridlayout(panel, [1, 1]);
            grid.Padding = [12, 12, 12, 12];
            grid.BackgroundColor = app.Surface;

            app.ChannelTable = uitable(grid, ...
                Data=app.Monitor.channelStatus(), ...
                ColumnName={ ...
                    "Channel", "Source", "State", "Hz", "Age", "Req"}, ...
                ColumnWidth={112, 114, 62, 44, 44, 38}, ...
                RowName={}, ...
                FontName=app.DataFont, ...
                FontSize=10, ...
                ForegroundColor=app.TextPrimary, ...
                BackgroundColor=[app.Surface; app.SurfaceRaised]);
        end

        function buildEventPanel(app, root)
            panel = app.makePanel(root, "EVENT LOG");
            panel.Layout.Row = 3;
            panel.Layout.Column = [1, 3];
            grid = uigridlayout(panel, [2, 2]);
            grid.Padding = [12, 10, 12, 10];
            grid.RowHeight = {28, "1x"};
            grid.ColumnWidth = {"1x", 110};
            grid.RowSpacing = 6;
            grid.ColumnSpacing = 8;
            grid.BackgroundColor = app.Surface;

            clearButton = uibutton(grid, "push", ...
                Text="CLEAR LOG", ...
                ButtonPushedFcn=@(~, ~)app.clearEventLog(), ...
                BackgroundColor=app.SurfaceRaised, ...
                FontColor=app.TextMuted, ...
                FontName=app.UiFont, ...
                FontSize=10);
            clearButton.Layout.Row = 1;
            clearButton.Layout.Column = 2;

            app.EventArea = uitextarea(grid, ...
                Editable="off", ...
                Value={'Waiting for source connection...'}, ...
                FontName=app.DataFont, ...
                FontSize=10, ...
                FontColor=app.TextMuted, ...
                BackgroundColor=app.Background);
            app.EventArea.Layout.Row = 2;
            app.EventArea.Layout.Column = [1, 2];
        end

        function panel = makePanel(app, parent, titleText)
            panel = uipanel(parent, ...
                Title=titleText, ...
                FontName=app.UiFont, ...
                FontSize=11, ...
                FontWeight="bold", ...
                ForegroundColor=app.TextMuted, ...
                BackgroundColor=app.Surface, ...
                BorderColor=app.Border, ...
                HighlightColor=app.Border);
        end

        function badge = makeBadge(app, parent, text, color)
            badge = uilabel(parent, ...
                Text=text, ...
                HorizontalAlignment="center", ...
                FontName=app.UiFont, ...
                FontSize=11, ...
                FontWeight="normal", ...
                FontColor=color, ...
                BackgroundColor=app.SurfaceRaised);
        end

        function label = makeFieldLabel(app, parent, text)
            label = uilabel(parent, ...
                Text=text, ...
                FontName=app.UiFont, ...
                FontSize=9, ...
                FontWeight="bold", ...
                FontColor=app.TextMuted);
        end

        function styleInput(app, control)
            control.BackgroundColor = app.SurfaceRaised;
            control.FontColor = app.TextPrimary;
            control.FontName = app.UiFont;
            control.FontSize = 11;
        end

        function axesHandle = makeAxes(app, parent, row, column, titleText, yLabelText)
            axesHandle = uiaxes(parent);
            axesHandle.Layout.Row = row;
            axesHandle.Layout.Column = column;
            axesHandle.Color = app.Background;
            axesHandle.XColor = app.TextMuted;
            axesHandle.YColor = app.TextMuted;
            axesHandle.GridColor = app.Border;
            axesHandle.MinorGridColor = app.Border;
            axesHandle.GridAlpha = 0.28;
            axesHandle.FontName = app.UiFont;
            axesHandle.FontSize = 9;
            axesHandle.Toolbar.Visible = "off";
            grid(axesHandle, "on");
            title(axesHandle, titleText, ...
                Color=app.TextPrimary, ...
                FontName=app.UiFont, ...
                FontSize=11, ...
                FontWeight="bold");
            xlabel(axesHandle, "elapsed s");
            ylabel(axesHandle, yLabelText);
        end

        function sourceSelectionChanged(app)
            if app.isSourceConnected()
                app.disconnectSource();
            end
            isSimulated = app.SourceDropDown.Value == "Simulated";
            app.PortField.Enable = onOff(~isSimulated);
            if isSimulated
                app.SimulatedBanner.Text = "◆ SIMULATED DATA";
            else
                app.SimulatedBanner.Text = "";
            end
        end

        function connectButtonPressed(app)
            if app.isSourceConnected()
                app.disconnectSource();
            else
                app.connectSource();
            end
        end

        function runHardwareCheck(app)
            report = vectra.px4.checkTelemetryHardware( ...
                app.PortField.Value);
            if report.usbSerialDetected
                app.addEvent("CHECK", ...
                    sprintf("USB telemetry adapter detected (%d port)", ...
                    numel(report.usbSerialPorts)));
            else
                app.addEvent("WARN", ...
                    "No USB telemetry adapter detected");
            end
            if report.localPortAvailable
                app.addEvent("CHECK", sprintf( ...
                    "UDP %d is available", report.localPort));
            else
                app.addEvent("ERROR", sprintf( ...
                    "UDP %d is already in use", report.localPort));
            end
            if report.pymavlinkAvailable
                app.addEvent("CHECK", ...
                    "PyMAVLink " + report.pymavlinkVersion + ...
                    " is available");
            else
                app.addEvent("ERROR", ...
                    "PyMAVLink is not installed in .venv");
            end
        end

        function connectSource(app)
            app.Monitor.reset();
            app.resetHistory();
            isSimulated = app.SourceDropDown.Value == "Simulated";
            if isSimulated
                app.Source = vectra.px4.SimulatedTelemetrySource();
                app.SimulatedBanner.Text = "◆ SIMULATED DATA";
            else
                app.Source = vectra.px4.LiveTelemetrySource( ...
                    LocalPort=app.PortField.Value);
                app.SimulatedBanner.Text = "";
            end
            app.Source.MessageCallback = @(event)app.handleMessage(event);
            app.Source.StatusCallback = @(status)app.handleSourceStatus(status);

            try
                app.Source.connect();
                app.ConnectButton.Text = "DISCONNECT";
                app.RecordButton.Enable = "on";
                app.RecordButton.BackgroundColor = app.Amber;
                app.RecordButton.FontColor = app.Background;
                app.setSelectorsEnabled(false);
            catch exception
                app.addEvent("ERROR", exception.message);
                app.Source = [];
                app.ConnectButton.Text = "CONNECT LISTENER";
                app.setSelectorsEnabled(true);
            end
        end

        function disconnectSource(app)
            if app.isRecording()
                app.stopRecording("source-disconnected");
            end
            if ~isempty(app.Source)
                app.Source.MessageCallback = [];
                app.Source.StatusCallback = [];
                app.Source.disconnect();
                app.Source = [];
            end
            app.Monitor.reset();
            app.resetHistory();
            app.ConnectButton.Text = "CONNECT LISTENER";
            app.RecordButton.Enable = "off";
            app.RecordButton.BackgroundColor = app.SurfaceRaised;
            app.RecordButton.FontColor = app.TextMuted;
            app.ConnectionBadge.Text = "● DISCONNECTED";
            app.ConnectionBadge.FontColor = app.TextMuted;
            app.VehicleBadge.Text = "SYS -- / COMP --";
            app.setSelectorsEnabled(true);
            app.addEvent("INFO", "Telemetry source disconnected");
        end

        function recordButtonPressed(app)
            if app.isRecording()
                app.stopRecording("operator-stop");
            else
                app.startRecording();
            end
        end

        function startRecording(app)
            if ~app.isSourceConnected()
                app.addEvent("ERROR", "Connect a source before recording");
                return;
            end

            isSimulated = app.SourceDropDown.Value == "Simulated";
            if ~isSimulated && ~app.TestMode
                answer = uiconfirm(app.Figure, [ ...
                    "Start passive PX4 telemetry recording?" newline newline ...
                    "This app sends no aircraft commands. Confirm that the " ...
                    "selected vehicle, geometry, and experiment profiles " ...
                    "match the current test."], ...
                    "Confirm physical recording", ...
                    Options=["Start recording", "Cancel"], ...
                    DefaultOption=2, ...
                    CancelOption=2, ...
                    Icon="warning");
                if answer ~= "Start recording"
                    return;
                end
            end

            sourceType = "flight";
            if isSimulated
                sourceType = "simulation";
            end
            resolved = vectra.config.resolveRun( ...
                string(app.ExperimentDropDown.Value), sourceType);
            resolved.vehicle = vectra.config.loadProfile( ...
                "vehicles", string(app.VehicleDropDown.Value));
            resolved.geometry = vectra.config.loadProfile( ...
                "geometries", string(app.GeometryDropDown.Value));
            telemetry = vectra.config.loadProfile( ...
                "telemetry", "local_udp");
            telemetry.localPort = app.PortField.Value;
            telemetry.sourceType = lower(strrep( ...
                app.SourceDropDown.Value, " ", "-"));
            telemetry.simulated = isSimulated;
            if ~isSimulated
                python = vectra.px4.pymavlinkEnvironment(telemetry);
                telemetry.pymavlinkVersion = ...
                    python.pymavlinkVersion;
            else
                telemetry.pymavlinkVersion = "";
            end
            resolved.hardware.telemetry = telemetry;

            try
                app.Logger = vectra.data.LiveTelemetryLogger( ...
                    resolved, SamplePeriodSec=telemetry.samplePeriodSec);
            catch exception
                app.addEvent("ERROR", exception.message);
                return;
            end

            app.RecordButton.Text = "STOP & FINALIZE";
            app.RecordButton.BackgroundColor = app.Red;
            app.RecordButton.FontColor = app.TextPrimary;
            app.RecordingBadge.Text = "● RECORDING";
            app.RecordingBadge.FontColor = app.Red;
            app.RunIdLabel.Text = app.Logger.RunId + newline + ...
                app.Logger.RunDirectory;
            app.addEvent("REC", "Recording started: " + app.Logger.RunId);
        end

        function stopRecording(app, reason)
            if ~app.isRecording()
                return;
            end
            runId = app.Logger.RunId;
            runDirectory = app.Logger.RunDirectory;
            app.Monitor.refreshFreshness();
            app.Logger.stop(reason, ...
                app.Monitor.summary(), app.Monitor.channelStatus());
            app.Logger = [];
            app.RecordButton.Text = "START RECORDING";
            app.RecordButton.BackgroundColor = app.Amber;
            app.RecordButton.FontColor = app.Background;
            app.RecordingBadge.Text = "○ NOT RECORDING";
            app.RecordingBadge.FontColor = app.TextMuted;
            app.RunIdLabel.Text = "Completed: " + runId + newline + ...
                runDirectory;
            app.addEvent("REC", "Recording finalized: " + runId);
        end

        function handleMessage(app, event)
            try
                accepted = app.Monitor.ingest(event);
            catch exception
                app.addEvent("ERROR", ...
                    "Decode failed: " + string(exception.message));
                return;
            end
            if ~accepted
                return;
            end
            if app.isRecording()
                try
                    app.Logger.append(event, app.Monitor.Snapshot);
                catch exception
                    app.addEvent("ERROR", ...
                        "Recorder failed: " + string(exception.message));
                    app.stopRecording("logger-error");
                end
            end
        end

        function handleSourceStatus(app, status)
            app.addEvent(upper(status.state), status.detail);
            switch string(status.state)
                case "listening"
                    app.ConnectionBadge.Text = "● LISTENING";
                    app.ConnectionBadge.FontColor = app.Accent;
                case "starting"
                    app.ConnectionBadge.Text = "● STARTING";
                    app.ConnectionBadge.FontColor = app.Accent;
                case "simulated"
                    app.ConnectionBadge.Text = "● SIMULATED";
                    app.ConnectionBadge.FontColor = app.Amber;
                case "error"
                    app.ConnectionBadge.Text = "● LINK ERROR";
                    app.ConnectionBadge.FontColor = app.Red;
                case "warning"
                    return;
                otherwise
                    app.ConnectionBadge.Text = "● " + ...
                        upper(string(status.state));
                    app.ConnectionBadge.FontColor = app.TextMuted;
            end
        end

        function updateInterface(app)
            if isempty(app.Figure) || ~isvalid(app.Figure)
                return;
            end
            app.Monitor.refreshFreshness();
            snapshot = app.Monitor.Snapshot;
            if snapshot.revision ~= app.LastPlottedRevision
                app.appendHistory(snapshot);
                app.LastPlottedRevision = snapshot.revision;
                app.updatePlots(snapshot);
            end

            status = app.Monitor.channelStatus();
            displayStatus = status;
            displayStatus.RateHz = round(displayStatus.RateHz, 1);
            displayStatus.AgeSec = round(displayStatus.AgeSec, 1);
            app.ChannelTable.Data = displayStatus;

            sourceCanReportHeartbeat = app.isSourceConnected() && ...
                app.Source.Status ~= "error";
            if sourceCanReportHeartbeat && ...
                    isfinite(app.Monitor.LockedSystemID)
                app.VehicleBadge.Text = sprintf( ...
                    "SYS %d / COMP %d", ...
                    app.Monitor.LockedSystemID, ...
                    app.Monitor.LockedComponentID);
                heartbeat = snapshot.channels.heartbeat;
                if heartbeat.state == "live"
                    app.ConnectionBadge.Text = "● PX4 LIVE";
                    if snapshot.sourceType == "simulated"
                        app.ConnectionBadge.FontColor = app.Amber;
                    else
                        app.ConnectionBadge.FontColor = app.Accent;
                    end
                elseif heartbeat.state == "stale"
                    app.ConnectionBadge.Text = "● LINK STALE";
                    app.ConnectionBadge.FontColor = app.Red;
                end
            end

            app.updateSummary(snapshot);
            drawnow limitrate nocallbacks;
        end

        function appendHistory(app, snapshot)
            if ~isfinite(snapshot.receivedUnixSec)
                return;
            end
            if ~isfinite(app.FirstDataUnixSec)
                app.FirstDataUnixSec = snapshot.receivedUnixSec;
            end
            elapsed = snapshot.receivedUnixSec - app.FirstDataUnixSec;
            data = snapshot.data;
            app.History.time(end + 1) = elapsed;
            app.History.roll(end + 1) = rad2deg(data.Roll_rad);
            app.History.pitch(end + 1) = rad2deg(data.Pitch_rad);
            app.History.yaw(end + 1) = rad2deg(data.Yaw_rad);
            app.History.x(end + 1) = data.X_m;
            app.History.y(end + 1) = data.Y_m;
            app.History.z(end + 1) = data.Z_m;
            app.History.voltage(end + 1) = data.BatteryVoltage_V;
            app.History.current(end + 1) = data.BatteryCurrent_A;

            maximumPoints = 600;
            if numel(app.History.time) > maximumPoints
                fields = fieldnames(app.History);
                for index = 1:numel(fields)
                    values = app.History.(fields{index});
                    app.History.(fields{index}) = ...
                        values(end - maximumPoints + 1:end);
                end
            end
        end

        function updatePlots(app, snapshot)
            set(app.AttitudeLines(1), ...
                XData=app.History.time, YData=app.History.roll);
            set(app.AttitudeLines(2), ...
                XData=app.History.time, YData=app.History.pitch);
            set(app.AttitudeLines(3), ...
                XData=app.History.time, YData=app.History.yaw);
            set(app.PositionLines(1), ...
                XData=app.History.time, YData=app.History.x);
            set(app.PositionLines(2), ...
                XData=app.History.time, YData=app.History.y);
            set(app.PositionLines(3), ...
                XData=app.History.time, YData=app.History.z);
            set(app.BatteryLines(1), ...
                XData=app.History.time, YData=app.History.voltage);
            set(app.BatteryLines(2), ...
                XData=app.History.time, YData=app.History.current);

            outputs = NaN(1, 4);
            for index = 1:4
                outputs(index) = snapshot.data.( ...
                    sprintf("Motor%d_pwm_us", index));
            end
            app.MotorBars.YData = outputs;
        end

        function updateSummary(app, snapshot)
            data = snapshot.data;
            app.SummaryLabels(1).Text = ...
                "ROLL" + newline + displayValue(rad2deg(data.Roll_rad), "°");
            app.SummaryLabels(2).Text = ...
                "PITCH" + newline + displayValue(rad2deg(data.Pitch_rad), "°");
            app.SummaryLabels(3).Text = ...
                "YAW" + newline + displayValue(rad2deg(data.Yaw_rad), "°");
            app.SummaryLabels(4).Text = ...
                "ALTITUDE" + newline + displayValue(data.Z_m, " m");
            app.SummaryLabels(5).Text = ...
                "BATTERY" + newline + ...
                displayValue(data.BatteryVoltage_V, " V");
        end

        function addEvent(app, severity, message)
            timestamp = string(datetime("now", ...
                TimeZone="UTC", Format="HH:mm:ss.SSS"));
            line = sprintf("%s  %-9s  %s", ...
                timestamp, upper(string(severity)), string(message));
            app.EventLines(end + 1, 1) = line;
            if numel(app.EventLines) > 80
                app.EventLines = app.EventLines(end - 79:end);
            end
            if ~isempty(app.EventArea) && isvalid(app.EventArea)
                app.EventArea.Value = cellstr(app.EventLines);
                drawnow limitrate;
                try
                    scroll(app.EventArea, "bottom");
                catch
                end
            end
        end

        function clearEventLog(app)
            app.EventLines = strings(0, 1);
            if ~isempty(app.EventArea) && isvalid(app.EventArea)
                app.EventArea.Value = {''};
            end
        end

        function resetHistory(app)
            app.History = struct( ...
                "time", zeros(1, 0), ...
                "roll", zeros(1, 0), ...
                "pitch", zeros(1, 0), ...
                "yaw", zeros(1, 0), ...
                "x", zeros(1, 0), ...
                "y", zeros(1, 0), ...
                "z", zeros(1, 0), ...
                "voltage", zeros(1, 0), ...
                "current", zeros(1, 0));
            app.FirstDataUnixSec = NaN;
            app.LastPlottedRevision = 0;
        end

        function setSelectorsEnabled(app, enabled)
            value = onOff(enabled);
            app.SourceDropDown.Enable = value;
            app.VehicleDropDown.Enable = value;
            app.GeometryDropDown.Enable = value;
            app.ExperimentDropDown.Enable = value;
            app.PortField.Enable = onOff(enabled && ...
                app.SourceDropDown.Value ~= "Simulated");
            app.HardwareCheckButton.Enable = onOff(enabled);
        end

        function value = isSourceConnected(app)
            value = ~isempty(app.Source) && ...
                app.Source.Status ~= "disconnected";
        end

        function value = isRecording(app)
            value = ~isempty(app.Logger) && app.Logger.IsRecording;
        end

        function closeRequested(app)
            if app.isRecording() && ~app.TestMode
                answer = uiconfirm(app.Figure, ...
                    "A telemetry recording is active. Stop and finalize it before closing?", ...
                    "Recording active", ...
                    Options=["Stop and close", "Keep open"], ...
                    DefaultOption=2, ...
                    CancelOption=2, ...
                    Icon="warning");
                if answer ~= "Stop and close"
                    return;
                end
            end
            if app.isRecording()
                app.stopRecording("application-closed");
            end
            app.cleanup();
            app.Figure.CloseRequestFcn = "";
            delete(app.Figure);
        end

        function cleanup(app)
            if ~isempty(app.UiTimer)
                try
                    stop(app.UiTimer);
                    delete(app.UiTimer);
                catch
                end
                app.UiTimer = [];
            end
            if app.isRecording()
                app.stopRecording("application-cleanup");
            end
            if ~isempty(app.Source)
                try
                    app.Source.MessageCallback = [];
                    app.Source.StatusCallback = [];
                    app.Source.disconnect();
                catch
                end
                app.Source = [];
            end
        end
    end
end

function names = profileNames(category)
entries = dir(fullfile(vectra.root(), "config", category, "*.json"));
names = strings(1, numel(entries));
for index = 1:numel(entries)
    [~, names(index)] = fileparts(entries(index).name);
end
names = sort(names);
end

function value = displayValue(number, suffix)
if isfinite(number)
    value = sprintf("%.2f%s", number, suffix);
else
    value = "—";
end
end

function value = onOff(logicalValue)
if logicalValue
    value = "on";
else
    value = "off";
end
end
