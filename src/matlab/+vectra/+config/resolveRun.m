function resolved = resolveRun(experimentProfile, source)
%RESOLVERUN Combine experiment, vehicle, and geometry profiles.

arguments
    experimentProfile (1,1) string
    source (1,1) string {mustBeMember(source, ...
        ["simulation", "flight", "hybrid"])} = "simulation"
end

experiment = vectra.config.loadProfile("experiments", experimentProfile);
vehicle = vectra.config.loadProfile("vehicles", ...
    string(experiment.vehicleProfile));
geometry = vectra.config.loadProfile("geometries", ...
    string(experiment.geometryProfile));

timestamp = datetime("now", "TimeZone", "UTC", ...
    "Format", "yyyyMMdd'T'HHmmss'Z'");
createdAt = datetime("now", "TimeZone", "UTC", ...
    "Format", "yyyy-MM-dd'T'HH:mm:ss.SSSXXX");

resolved = struct();
resolved.schemaVersion = "1.0.0";
resolved.runId = string(experiment.experimentId) + "-" + string(timestamp);
resolved.createdAt = string(createdAt);
resolved.source = source;
resolved.vehicle = vehicle;
resolved.geometry = geometry;
resolved.experiment = experiment;
environmentInfo = vectra.environment();
resolved.software = struct( ...
    "vectraVersion", vectra.version(), ...
    "matlabVersion", environmentInfo.matlabVersion, ...
    "quadSimCommit", vectra.quadsim.pinnedCommit());
resolved.hardware = struct();
end
