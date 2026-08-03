function report = validateProject()
%VALIDATEPROJECT Validate the local VECTRA scaffold and configuration.

setupVECTRA();
projectRoot = vectra.root();

requiredDirectories = [
    "config/vehicles"
    "config/geometries"
    "config/experiments"
    "config/telemetry"
    "config/schemas"
    "models/quadsim"
    "src/matlab/+vectra"
    "scripts"
    "apps"
    "tests"
    "data/raw"
    "data/processed"
    "results"
    "hardware"
    "docs"
    "vendor/QuadSim"
];

requiredFiles = [
    "README.md"
    "implementation_plan.md"
    "VERSION"
    "config/vehicles/main_quad.json"
    "config/geometries/cant_00.json"
    "config/geometries/cant_tangential_10.json"
    "config/experiments/smoke_hover.json"
    "config/telemetry/local_udp.json"
    "config/telemetry/requirements.txt"
    "apps/VectraTelemetryApp.m"
    "scripts/installPymavlink.m"
    "scripts/launchTelemetryApp.m"
    "scripts/telemetry/pymavlink_bridge.py"
    "docs/usage/px4-telemetry-gui.md"
    "vendor/quadsim-lock.json"
];

missingDirectories = strings(0, 1);
for index = 1:numel(requiredDirectories)
    if ~isfolder(fullfile(projectRoot, requiredDirectories(index)))
        missingDirectories(end + 1, 1) = requiredDirectories(index); %#ok<AGROW>
    end
end

missingFiles = strings(0, 1);
for index = 1:numel(requiredFiles)
    if ~isfile(fullfile(projectRoot, requiredFiles(index)))
        missingFiles(end + 1, 1) = requiredFiles(index); %#ok<AGROW>
    end
end

jsonFiles = dir(fullfile(projectRoot, "config", "**", "*.json"));
invalidJsonFiles = strings(0, 1);
for index = 1:numel(jsonFiles)
    filename = fullfile(jsonFiles(index).folder, jsonFiles(index).name);
    try
        jsondecode(fileread(filename));
    catch
        invalidJsonFiles(end + 1, 1) = string(filename); %#ok<AGROW>
    end
end

quadSimPaths = vectra.quadsim.paths();
quadSimModels = [
    "AC_Quadcopter_Simulation.slx"
    "PC_Quadcopter_Simulation.slx"
    "Team37_Quadcopter_Simulation.slx"
];
missingQuadSimModels = quadSimModels( ...
    ~isfile(fullfile(quadSimPaths.models, quadSimModels)));

report = struct();
report.valid = isempty(missingDirectories) && isempty(missingFiles) && ...
    isempty(invalidJsonFiles) && isempty(missingQuadSimModels);
report.missingDirectories = missingDirectories;
report.missingFiles = missingFiles;
report.invalidJsonFiles = invalidJsonFiles;
report.missingQuadSimModels = missingQuadSimModels;

if nargout == 0
    disp(report);
    if ~report.valid
        error("vectra:project:ValidationFailed", ...
            "VECTRA project validation failed.");
    end
end
end
