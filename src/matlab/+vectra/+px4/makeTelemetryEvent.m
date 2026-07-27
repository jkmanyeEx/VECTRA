function event = makeTelemetryEvent(messageName, payload, metadata)
%MAKETELEMETRYEVENT Create a source-neutral live telemetry event.

arguments
    messageName (1,1) string
    payload (1,1) struct
    metadata.SystemID (1,1) double = 1
    metadata.ComponentID (1,1) double = 1
    metadata.Sequence (1,1) double = 0
    metadata.ReceivedUnixSec (1,1) double = ...
        posixtime(datetime("now", "TimeZone", "UTC"))
    metadata.SourceType (1,1) string = "physical"
    metadata.SourceTimestampUs (1,1) double = NaN
end

event = struct();
event.SchemaVersion = "1.0.0";
event.MessageName = upper(messageName);
event.Payload = payload;
event.SystemID = metadata.SystemID;
event.ComponentID = metadata.ComponentID;
event.Sequence = metadata.Sequence;
event.ReceivedUnixSec = metadata.ReceivedUnixSec;
event.ReceivedAtUtc = string(datetime(metadata.ReceivedUnixSec, ...
    "ConvertFrom", "posixtime", "TimeZone", "UTC", ...
    "Format", "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"));
event.SourceType = metadata.SourceType;
event.SourceTimestampUs = metadata.SourceTimestampUs;
end
