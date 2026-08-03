classdef TelemetryMonitor < handle
    %TELEMETRYMONITOR Track normalized state, provenance, and link quality.

    properties (SetAccess = private)
        Snapshot
        LockedSystemID double = NaN
        LockedComponentID double = NaN
        TotalMessages uint64 = 0
        AcceptedMessages uint64 = 0
        ForeignMessages uint64 = 0
        RejectedLockHeartbeats uint64 = 0
        SequenceGaps uint64 = 0
        DecodeErrors uint64 = 0
    end

    properties (Access = private)
        LastSequence
        MessageCounts
    end

    methods
        function this = TelemetryMonitor()
            this.LastSequence = containers.Map( ...
                "KeyType", "char", "ValueType", "double");
            this.MessageCounts = containers.Map( ...
                "KeyType", "char", "ValueType", "double");
            this.reset();
        end

        function reset(this)
            this.Snapshot = vectra.px4.emptyTelemetrySnapshot();
            this.LockedSystemID = NaN;
            this.LockedComponentID = NaN;
            this.TotalMessages = 0;
            this.AcceptedMessages = 0;
            this.ForeignMessages = 0;
            this.RejectedLockHeartbeats = 0;
            this.SequenceGaps = 0;
            this.DecodeErrors = 0;
            remove(this.LastSequence, keys(this.LastSequence));
            remove(this.MessageCounts, keys(this.MessageCounts));
        end

        function accepted = ingest(this, event)
            accepted = false;
            this.TotalMessages = this.TotalMessages + 1;

            name = upper(string(event.MessageName));
            if isnan(this.LockedSystemID)
                if name ~= "HEARTBEAT"
                    return;
                end
                if ~isPx4VehicleHeartbeat(event)
                    this.RejectedLockHeartbeats = ...
                        this.RejectedLockHeartbeats + 1;
                    return;
                end
                this.LockedSystemID = double(event.SystemID);
                this.LockedComponentID = double(event.ComponentID);
            elseif double(event.SystemID) ~= this.LockedSystemID
                this.ForeignMessages = this.ForeignMessages + 1;
                return;
            end

            sequenceKey = sprintf("%d:%d", ...
                event.SystemID, event.ComponentID);
            sequence = double(event.Sequence);
            if isKey(this.LastSequence, sequenceKey)
                expected = mod(this.LastSequence(sequenceKey) + 1, 256);
                if sequence ~= expected
                    gap = mod(sequence - expected, 256);
                    if gap > 0 && gap < 128
                        this.SequenceGaps = this.SequenceGaps + uint64(gap);
                    end
                end
            end
            this.LastSequence(sequenceKey) = sequence;

            try
                this.Snapshot = vectra.px4.normalizeTelemetryMessage( ...
                    this.Snapshot, event);
            catch exception
                this.DecodeErrors = this.DecodeErrors + 1;
                rethrow(exception);
            end

            countKey = char(name);
            if isKey(this.MessageCounts, countKey)
                this.MessageCounts(countKey) = ...
                    this.MessageCounts(countKey) + 1;
            else
                this.MessageCounts(countKey) = 1;
            end
            this.AcceptedMessages = this.AcceptedMessages + 1;
            accepted = true;
        end

        function refreshFreshness(this, nowUnixSec)
            if nargin < 2
                nowUnixSec = posixtime(datetime( ...
                    "now", "TimeZone", "UTC"));
            end

            definitions = vectra.px4.telemetryDefinitions();
            snapshot = this.Snapshot;
            for index = 1:numel(definitions)
                key = definitions(index).key;
                channel = snapshot.channels.(key);
                if isfinite(channel.lastReceivedUnixSec)
                    channel.ageSec = max(0, ...
                        nowUnixSec - channel.lastReceivedUnixSec);
                    if channel.ageSec > channel.freshnessSec
                        channel.state = "stale";
                    else
                        channel.state = "live";
                    end
                end
                snapshot.channels.(key) = channel;
            end
            this.Snapshot = snapshot;
        end

        function status = channelStatus(this)
            definitions = vectra.px4.telemetryDefinitions();
            count = numel(definitions);
            labels = strings(count, 1);
            sources = strings(count, 1);
            states = strings(count, 1);
            rates = zeros(count, 1);
            ages = NaN(count, 1);
            required = false(count, 1);

            for index = 1:count
                channel = this.Snapshot.channels.(definitions(index).key);
                labels(index) = channel.label;
                sources(index) = channel.messageName;
                states(index) = channel.state;
                rates(index) = channel.rateHz;
                ages(index) = channel.ageSec;
                required(index) = channel.required;
            end

            status = table(labels, sources, states, rates, ages, required, ...
                VariableNames=[ ...
                    "Channel", "Source", "State", "RateHz", ...
                    "AgeSec", "Required"]);
        end

        function value = summary(this)
            countKeys = keys(this.MessageCounts);
            counts = struct();
            for index = 1:numel(countKeys)
                safeName = matlab.lang.makeValidName(countKeys{index});
                counts.(safeName) = this.MessageCounts(countKeys{index});
            end

            value = struct( ...
                "systemId", this.LockedSystemID, ...
                "componentId", this.LockedComponentID, ...
                "totalMessages", this.TotalMessages, ...
                "acceptedMessages", this.AcceptedMessages, ...
                "foreignMessages", this.ForeignMessages, ...
                "rejectedLockHeartbeats", ...
                    this.RejectedLockHeartbeats, ...
                "sequenceGaps", this.SequenceGaps, ...
                "decodeErrors", this.DecodeErrors, ...
                "messageCounts", counts);
        end
    end
end

function valid = isPx4VehicleHeartbeat(event)
%ISPX4VEHICLEHEARTBEAT Reject forwarded GCS heartbeats as lock candidates.

valid = false;
if ~isfield(event, "Payload") || ~isstruct(event.Payload) || ...
        ~isfield(event.Payload, "autopilot")
    return;
end

autopilot = double(event.Payload.autopilot);
mavAutopilotPx4 = 12;
valid = isscalar(autopilot) && isfinite(autopilot) && ...
    autopilot == mavAutopilotPx4;
end
