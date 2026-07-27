classdef LiveTelemetrySource < handle
    %LIVETELEMETRYSOURCE Passive PyMAVLink receiver process adapter.

    properties
        MessageCallback = []
        StatusCallback = []
    end

    properties (SetAccess = private)
        LocalPort (1,1) double = 14551
        DialectName (1,1) string = "common"
        PollPeriodSec (1,1) double = 0.05
        Status (1,1) string = "disconnected"
        PyMavlinkVersion (1,1) string = ""
    end

    properties (Access = private)
        PythonExecutable (1,1) string = ""
        BridgeScript (1,1) string = ""
        BridgeProcess = []
        StandardOutput = []
        StandardError = []
        PollTimer = []
        StdoutBuffer (1,:) char = ''
        StderrBuffer (1,:) char = ''
        Disconnecting (1,1) logical = false
    end

    methods
        function this = LiveTelemetrySource(options)
            arguments
                options.LocalPort (1,1) double = 14551
                options.DialectName (1,1) string = "common"
                options.PollPeriodSec (1,1) double = 0.05
                options.PythonExecutable (1,1) string = ""
                options.BridgeScript (1,1) string = ""
            end

            profile = vectra.config.loadProfile( ...
                "telemetry", "local_udp");
            environment = vectra.px4.pymavlinkEnvironment(profile);
            this.LocalPort = options.LocalPort;
            this.DialectName = options.DialectName;
            this.PollPeriodSec = options.PollPeriodSec;
            this.PythonExecutable = options.PythonExecutable;
            this.BridgeScript = options.BridgeScript;
            if strlength(this.PythonExecutable) == 0
                this.PythonExecutable = environment.pythonExecutable;
            end
            if strlength(this.BridgeScript) == 0
                this.BridgeScript = environment.bridgeScript;
            end
        end

        function connect(this)
            if this.Status ~= "disconnected"
                return;
            end

            profile = vectra.config.loadProfile( ...
                "telemetry", "local_udp");
            profile.localPort = this.LocalPort;
            profile.dialect = this.DialectName;
            profile.pythonExecutable = this.PythonExecutable;
            profile.bridgeScript = this.BridgeScript;
            environment = vectra.px4.pymavlinkEnvironment(profile);
            if ~environment.ready
                detail = strjoin(environment.issues, " ");
                error("vectra:px4:MissingPyMavlink", "%s", detail);
            end
            this.PyMavlinkVersion = environment.pymavlinkVersion;
            this.Disconnecting = false;
            this.StdoutBuffer = '';
            this.StderrBuffer = '';
            this.setStatus("connecting", ...
                sprintf("Starting PyMAVLink on UDP %d", this.LocalPort));

            parts = [
                this.PythonExecutable
                this.BridgeScript
                "--bind"
                "127.0.0.1"
                "--port"
                string(this.LocalPort)
                "--dialect"
                this.DialectName
            ];

            try
                command = javaArray("java.lang.String", numel(parts));
                for index = 1:numel(parts)
                    command(index) = java.lang.String(char(parts(index)));
                end
                builder = java.lang.ProcessBuilder(command);
                builder.directory(java.io.File(char(vectra.root())));
                builder.redirectErrorStream(false);
                this.BridgeProcess = builder.start();
                this.StandardOutput = ...
                    this.BridgeProcess.getInputStream();
                this.StandardError = ...
                    this.BridgeProcess.getErrorStream();
                this.PollTimer = timer( ...
                    ExecutionMode="fixedSpacing", ...
                    Period=this.PollPeriodSec, ...
                    BusyMode="drop", ...
                    TimerFcn=@(~, ~)this.pollProcess());
                start(this.PollTimer);
            catch exception
                this.terminateProcess();
                this.setStatus("error", exception.message);
                rethrow(exception);
            end
        end

        function disconnect(this)
            if this.Disconnecting
                return;
            end
            this.Disconnecting = true;
            this.stopPolling();
            this.pollStreams();
            this.terminateProcess();
            this.StdoutBuffer = '';
            this.StderrBuffer = '';
            this.PyMavlinkVersion = "";
            this.Disconnecting = false;
            this.setStatus("disconnected", ...
                "PyMAVLink listener closed");
        end

        function delete(this)
            this.disconnect();
        end
    end

    methods (Access = private)
        function pollProcess(this)
            try
                this.pollStreams();
                if ~isempty(this.BridgeProcess) && ...
                        ~this.BridgeProcess.isAlive()
                    exitCode = this.BridgeProcess.exitValue();
                    this.stopPolling();
                    this.terminateProcess();
                    if ~this.Disconnecting
                        this.setStatus("error", sprintf( ...
                            "PyMAVLink bridge exited with code %d", ...
                            exitCode));
                    end
                end
            catch exception
                this.stopPolling();
                this.terminateProcess();
                if ~this.Disconnecting
                    this.setStatus("error", ...
                        "PyMAVLink bridge read failed: " + ...
                        string(exception.message));
                end
            end
        end

        function pollStreams(this)
            if ~isempty(this.StandardOutput)
                this.StdoutBuffer = [this.StdoutBuffer, ...
                    readAvailable(this.StandardOutput)];
                [lines, this.StdoutBuffer] = ...
                    completeLines(this.StdoutBuffer);
                for index = 1:numel(lines)
                    this.handleProtocolLine(lines{index});
                end
            end
            if ~isempty(this.StandardError)
                this.StderrBuffer = [this.StderrBuffer, ...
                    readAvailable(this.StandardError)];
                [lines, this.StderrBuffer] = ...
                    completeLines(this.StderrBuffer);
                for index = 1:numel(lines)
                    if strlength(strtrim(string(lines{index}))) > 0
                        this.emitStatus("warning", ...
                            "PyMAVLink: " + strtrim(string(lines{index})));
                    end
                end
            end
        end

        function handleProtocolLine(this, line)
            line = strtrim(string(line));
            if strlength(line) == 0
                return;
            end
            try
                record = jsondecode(line);
            catch
                this.emitStatus("warning", ...
                    "Ignored non-JSON bridge output");
                return;
            end
            if ~isfield(record, "RecordType")
                return;
            end

            switch string(record.RecordType)
                case "event"
                    if ~isempty(this.MessageCallback)
                        this.MessageCallback(record);
                    end
                case "status"
                    state = lower(string(record.State));
                    detail = string(record.Detail);
                    if isfield(record, "PyMavlinkVersion")
                        this.PyMavlinkVersion = ...
                            string(record.PyMavlinkVersion);
                    end
                    if ismember(state, [ ...
                            "starting", "listening", ...
                            "error", "stopped"])
                        this.Status = state;
                    end
                    this.emitStatus(state, detail);
            end
        end

        function setStatus(this, state, detail)
            this.Status = string(state);
            this.emitStatus(state, detail);
        end

        function emitStatus(this, state, detail)
            if ~isempty(this.StatusCallback)
                this.StatusCallback(struct( ...
                    "state", string(state), ...
                    "detail", string(detail), ...
                    "unixSec", posixtime(datetime( ...
                        "now", "TimeZone", "UTC"))));
            end
        end

        function stopPolling(this)
            if ~isempty(this.PollTimer)
                try
                    stop(this.PollTimer);
                    delete(this.PollTimer);
                catch
                end
                this.PollTimer = [];
            end
        end

        function terminateProcess(this)
            if ~isempty(this.BridgeProcess)
                try
                    if this.BridgeProcess.isAlive()
                        this.BridgeProcess.destroy();
                    end
                catch
                end
                this.BridgeProcess = [];
            end
            this.StandardOutput = [];
            this.StandardError = [];
        end
    end
end

function text = readAvailable(stream)
text = '';
count = double(stream.available());
if count <= 0
    return;
end
bytes = stream.readNBytes(count);
values = uint8(mod(double(bytes), 256));
text = native2unicode(values(:)', "UTF-8");
end

function [lines, remainder] = completeLines(buffer)
newlineIndices = find(buffer == newline);
lines = cell(0, 1);
startIndex = 1;
for index = 1:numel(newlineIndices)
    stopIndex = newlineIndices(index) - 1;
    line = buffer(startIndex:stopIndex);
    if ~isempty(line) && line(end) == char(13)
        line(end) = [];
    end
    lines{end + 1, 1} = line; %#ok<AGROW>
    startIndex = newlineIndices(index) + 1;
end
remainder = buffer(startIndex:end);
end
