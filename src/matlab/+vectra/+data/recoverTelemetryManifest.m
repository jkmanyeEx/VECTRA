function manifestFile = recoverTelemetryManifest(runDirectory)
%RECOVERTELEMETRYMANIFEST Rebuild a manifest from an intact event journal.

runDirectory = string(runDirectory);
journalFile = fullfile(runDirectory, "telemetry_events.jsonl");
if ~isfile(journalFile)
    error("vectra:data:JournalNotFound", ...
        "Telemetry journal not found: %s", journalFile);
end

fileId = fopen(journalFile, "r", "n", "UTF-8");
if fileId < 0
    error("vectra:data:CannotOpenTelemetryLog", ...
        "Cannot open telemetry journal: %s", journalFile);
end
cleanup = onCleanup(@() fclose(fileId));

eventCount = uint64(0);
firstUnixSec = NaN;
lastUnixSec = NaN;
counts = struct();
while true
    line = fgetl(fileId);
    if ~ischar(line)
        break;
    end
    if strlength(strtrim(string(line))) == 0
        continue;
    end
    event = jsondecode(line);
    eventCount = eventCount + 1;
    received = double(event.ReceivedUnixSec);
    if ~isfinite(firstUnixSec)
        firstUnixSec = received;
    end
    lastUnixSec = received;
    key = matlab.lang.makeValidName(char(event.MessageName));
    if isfield(counts, key)
        counts.(key) = counts.(key) + 1;
    else
        counts.(key) = 1;
    end
end

manifest = struct( ...
    "schemaVersion", "1.0.0", ...
    "recovered", true, ...
    "recoveredAtUtc", isoTime(posixtime(datetime( ...
        "now", "TimeZone", "UTC"))), ...
    "startedAtUtc", isoTime(firstUnixSec), ...
    "stoppedAtUtc", isoTime(lastUnixSec), ...
    "durationSec", lastUnixSec - firstUnixSec, ...
    "stopReason", "recovered-after-interruption", ...
    "eventCount", eventCount, ...
    "messageCounts", counts, ...
    "rawJournal", "telemetry_events.jsonl");

manifestFile = fullfile(runDirectory, "telemetry_manifest.json");
vectra.data.writeJson(manifestFile, manifest);
end

function value = isoTime(unixSec)
if isfinite(unixSec)
    value = string(datetime(unixSec, ...
        "ConvertFrom", "posixtime", "TimeZone", "UTC", ...
        "Format", "yyyy-MM-dd'T'HH:mm:ss.SSSXXX"));
else
    value = "";
end
end
