classdef LiveTelemetryLogger < handle
    %LIVETELEMETRYLOGGER Stream immutable raw events and normalized samples.

    properties (SetAccess = private)
        RunDirectory (1,1) string
        RunId (1,1) string
        IsRecording (1,1) logical = false
        EventCount uint64 = 0
        SampleCount uint64 = 0
        StartedUnixSec (1,1) double = NaN
    end

    properties
        SamplePeriodSec (1,1) double = 0.1
        FlushEveryMessages (1,1) double = 100
    end

    properties (Access = private)
        EventFileId (1,1) double = -1
        SampleFileId (1,1) double = -1
        LastSampleUnixSec (1,1) double = -Inf
        ResolvedConfig struct
    end

    methods
        function this = LiveTelemetryLogger(resolved, options)
            arguments
                resolved (1,1) struct
                options.RootDirectory (1,1) string = ...
                    fullfile(vectra.root(), "data", "raw")
                options.SamplePeriodSec (1,1) double = 0.1
            end

            if ~isfield(resolved, "runId")
                error("vectra:data:InvalidResolvedConfig", ...
                    "Resolved configuration must contain runId.");
            end

            this.RunId = string(resolved.runId);
            this.ResolvedConfig = resolved;
            this.SamplePeriodSec = options.SamplePeriodSec;
            this.RunDirectory = fullfile( ...
                options.RootDirectory, this.RunId);
            if isfolder(this.RunDirectory)
                error("vectra:data:RunAlreadyExists", ...
                    "Run directory already exists: %s", ...
                    this.RunDirectory);
            end

            mkdir(this.RunDirectory);
            vectra.data.writeJson(fullfile(this.RunDirectory, ...
                "resolved_config.json"), resolved);
            this.openFiles("w");
            this.writeSampleHeader();
            this.StartedUnixSec = posixtime(datetime( ...
                "now", "TimeZone", "UTC"));
            this.IsRecording = true;
        end

        function append(this, event, snapshot)
            if ~this.IsRecording
                error("vectra:data:LoggerClosed", ...
                    "Cannot append to a closed telemetry logger.");
            end

            encoded = jsonencode(event);
            fprintf(this.EventFileId, "%s\n", encoded);
            this.EventCount = this.EventCount + 1;

            received = double(event.ReceivedUnixSec);
            if received - this.LastSampleUnixSec >= ...
                    this.SamplePeriodSec
                this.writeSample(snapshot, received);
                this.LastSampleUnixSec = received;
                this.SampleCount = this.SampleCount + 1;
            end

            if mod(double(this.EventCount), ...
                    this.FlushEveryMessages) == 0
                this.flush();
            end
        end

        function manifestFile = stop(this, stopReason, monitorSummary, channelStatus)
            arguments
                this
                stopReason (1,1) string = "operator-stop"
                monitorSummary struct = struct()
                channelStatus = table()
            end

            if ~this.IsRecording
                manifestFile = fullfile( ...
                    this.RunDirectory, "telemetry_manifest.json");
                return;
            end

            this.closeFiles();
            this.IsRecording = false;
            stoppedUnixSec = posixtime(datetime( ...
                "now", "TimeZone", "UTC"));
            manifest = struct( ...
                "schemaVersion", "1.0.0", ...
                "runId", this.RunId, ...
                "startedAtUtc", isoTime(this.StartedUnixSec), ...
                "stoppedAtUtc", isoTime(stoppedUnixSec), ...
                "durationSec", stoppedUnixSec - this.StartedUnixSec, ...
                "stopReason", stopReason, ...
                "eventCount", this.EventCount, ...
                "sampleCount", this.SampleCount, ...
                "monitor", monitorSummary, ...
                "channels", tableToRecords(channelStatus), ...
                "rawJournal", "telemetry_events.jsonl", ...
                "normalizedSamples", "telemetry_samples.csv");
            manifestFile = fullfile( ...
                this.RunDirectory, "telemetry_manifest.json");
            vectra.data.writeJson(manifestFile, manifest);
        end

        function flush(this)
            if ~this.IsRecording
                return;
            end
            this.closeFiles();
            this.openFiles("a");
        end

        function delete(this)
            if this.IsRecording
                this.stop("logger-deleted");
            else
                this.closeFiles();
            end
        end
    end

    methods (Access = private)
        function openFiles(this, mode)
            this.EventFileId = fopen(fullfile(this.RunDirectory, ...
                "telemetry_events.jsonl"), mode, "n", "UTF-8");
            this.SampleFileId = fopen(fullfile(this.RunDirectory, ...
                "telemetry_samples.csv"), mode, "n", "UTF-8");
            if this.EventFileId < 0 || this.SampleFileId < 0
                this.closeFiles();
                error("vectra:data:CannotOpenTelemetryLog", ...
                    "Cannot open telemetry log files in %s", ...
                    this.RunDirectory);
            end
        end

        function closeFiles(this)
            if this.EventFileId >= 0
                fclose(this.EventFileId);
                this.EventFileId = -1;
            end
            if this.SampleFileId >= 0
                fclose(this.SampleFileId);
                this.SampleFileId = -1;
            end
        end

        function writeSampleHeader(this)
            names = sampleFieldNames();
            fprintf(this.SampleFileId, "%s\n", strjoin(names, ","));
        end

        function writeSample(this, snapshot, received)
            data = snapshot.data;
            values = [
                received
                received - this.StartedUnixSec
                snapshot.systemId
                snapshot.componentId
                double(snapshot.sourceType == "simulated")
                numericValue(data.Armed)
                data.Roll_rad
                data.Pitch_rad
                data.Yaw_rad
                data.P_radps
                data.Q_radps
                data.R_radps
                data.North_m
                data.East_m
                data.Down_m
                data.VNorth_mps
                data.VEast_mps
                data.VDown_mps
                data.X_m
                data.Y_m
                data.Z_m
                data.BatteryVoltage_V
                data.BatteryCurrent_A
                data.BatteryRemaining_pct
                data.GpsFixType
                data.GpsSatellites
            ];
            for index = 1:4
                values(end + 1, 1) = data.( ...
                    sprintf("Motor%d_output", index)); %#ok<AGROW>
            end
            for index = 1:4
                values(end + 1, 1) = data.( ...
                    sprintf("Motor%d_rpm", index)); %#ok<AGROW>
            end

            fields = strings(numel(values), 1);
            for index = 1:numel(values)
                if isfinite(values(index))
                    fields(index) = sprintf("%.10g", values(index));
                else
                    fields(index) = "";
                end
            end
            fprintf(this.SampleFileId, "%s\n", strjoin(fields, ","));
        end
    end
end

function names = sampleFieldNames()
names = [ ...
    "ReceivedUnixSec"
    "Elapsed_s"
    "SystemID"
    "ComponentID"
    "IsSimulated"
    "Armed"
    "Roll_rad"
    "Pitch_rad"
    "Yaw_rad"
    "P_radps"
    "Q_radps"
    "R_radps"
    "North_m"
    "East_m"
    "Down_m"
    "VNorth_mps"
    "VEast_mps"
    "VDown_mps"
    "X_m"
    "Y_m"
    "Z_m"
    "BatteryVoltage_V"
    "BatteryCurrent_A"
    "BatteryRemaining_pct"
    "GpsFixType"
    "GpsSatellites"
    "Motor1_output"
    "Motor2_output"
    "Motor3_output"
    "Motor4_output"
    "Motor1_rpm"
    "Motor2_rpm"
    "Motor3_rpm"
    "Motor4_rpm"
];
end

function value = numericValue(input)
value = double(input);
end

function value = isoTime(unixSec)
value = string(datetime(unixSec, ...
    "ConvertFrom", "posixtime", "TimeZone", "UTC", ...
    "Format", "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"));
end

function records = tableToRecords(input)
if istable(input) && ~isempty(input)
    records = table2struct(input);
else
    records = struct([]);
end
end
