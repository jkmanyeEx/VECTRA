function report = checkFlightAuthority(connectionState)
%CHECKFLIGHTAUTHORITY Evaluate minimum gates before enabling test commands.

arguments
    connectionState struct
end

requiredLogicalFields = [
    "connected"
    "operatorConfirmed"
    "manualOverrideAvailable"
    "failsafeConfigured"
    "positionEstimateValid"
    "batteryHealthy"
];

report = struct();
report.checks = struct();
report.ready = true;
report.failedChecks = strings(0, 1);

for index = 1:numel(requiredLogicalFields)
    fieldName = requiredLogicalFields(index);
    fieldKey = char(fieldName);
    passed = isfield(connectionState, fieldKey) && ...
        islogical(connectionState.(fieldKey)) && ...
        isscalar(connectionState.(fieldKey)) && ...
        connectionState.(fieldKey);
    report.checks.(fieldKey) = passed;
    if ~passed
        report.ready = false;
        report.failedChecks(end + 1, 1) = fieldName;
    end
end
end
