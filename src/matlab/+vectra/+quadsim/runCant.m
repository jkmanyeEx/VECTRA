function result = runCant(geometryProfile, saveOutput, durationSec)
%RUNCANT Run the VECTRA cant-aware attitude-control model.

arguments
    geometryProfile (1,1) string = "cant_00"
    saveOutput (1,1) logical = true
    durationSec (1,1) double {mustBePositive, mustBeFinite} = 10
end

resolved = vectra.config.resolveRun("smoke_hover", "simulation");
resolved.geometry = vectra.config.loadProfile( ...
    "geometries", geometryProfile);
resolved.experiment.geometryProfile = geometryProfile;
resolved.experiment.simulationModel = ...
    "VECTRA_Cant_Quadcopter_Simulation";
resolved.experiment.durationSec = durationSec;
resolved.runId = "cant-" + geometryProfile + "-" + ...
    string(datetime("now", "TimeZone", "UTC", ...
    "Format", "yyyyMMdd'T'HHmmss'Z'"));
resolved.simulation = struct( ...
    "vehicleModelSource", "upstream-quadModel-plus", ...
    "controller", "upstream-AC-PID-with-cant-allocation", ...
    "coordinateFrame", "QUADSIM_BODY_XY_ZUP");

locations = vectra.quadsim.paths();
vectra.quadsim.setupPaths();
modelFile = fullfile(locations.vectraModels, ...
    "VECTRA_Cant_Quadcopter_Simulation.slx");
initialConditionFile = fullfile(locations.initialConditions, ...
    string(resolved.experiment.initialCondition) + ".mat");
vehicleModelFile = fullfile(locations.vehicleModels, "quadModel_+.mat");

initialConditionData = load(initialConditionFile);
vehicleModelData = load(vehicleModelFile);
quadModel = vectra.quadsim.extendQuadModel( ...
    vehicleModelData.quadModel, resolved.geometry);
IC = initialConditionData.IC;

modelName = "VECTRA_Cant_Quadcopter_Simulation";
load_system(modelFile);
simulationInput = Simulink.SimulationInput(modelName);
simulationInput = simulationInput.setVariable("IC", IC);
simulationInput = simulationInput.setVariable("quadModel", quadModel);
simulationInput = simulationInput.setModelParameter( ...
    "StopTime", string(resolved.experiment.durationSec));
fprintf("VECTRA_CANT_RUN: simulation_start %s\n", geometryProfile);
simulationOutput = sim(simulationInput);
fprintf("VECTRA_CANT_RUN: simulation_complete %s\n", geometryProfile);

yout = simulationOutput.get("yout");
tout = simulationOutput.get("tout");
data = vectra.quadsim.normalizeOutput(yout, tout);
wrench = calculateWrenchTimetable(data, quadModel.wrenchMatrix);
fprintf("VECTRA_CANT_RUN: normalized %s\n", geometryProfile);

allocationDiagnostics = [];
try
    allocationDiagnostics = simulationOutput.get( ...
        "cantAllocationDiagnostics");
catch diagnosticError
    if ~contains(diagnosticError.message, "not found", ...
            "IgnoreCase", true)
        rethrow(diagnosticError);
    end
end
fprintf("VECTRA_CANT_RUN: diagnostics %s\n", geometryProfile);

verticalScale = sum(quadModel.wrenchMatrix(3, :)) / ...
    sum(quadModel.zeroWrenchMatrix(3, :));
validation = struct();
validation.verticalForceScale = verticalScale;
validation.expectedVerticalForceScale = ...
    mean(cosd(quadModel.cantAnglesDeg));
validation.expectedHoverRpmRatio = 1 / sqrt(verticalScale);
validation.finite = all(isfinite(data.Variables), "all");
dataNames = string(data.Properties.VariableNames);
rpmColumns = startsWith(dataNames, "Motor") & endsWith(dataNames, "_rpm");
validation.maximumSimulatedRpm = max(data{:, rpmColumns}, [], "all");
validation.motorLimitExceeded = ...
    validation.maximumSimulatedRpm > quadModel.maximumRpm + 1e-9;

result = struct();
result.config = resolved;
result.quadModel = quadModel;
result.raw = struct("tout", tout, "yout", yout);
result.data = data;
result.wrench = wrench;
result.allocationDiagnostics = allocationDiagnostics;
result.validation = validation;
fprintf("VECTRA_CANT_RUN: result_ready %s\n", geometryProfile);

if saveOutput
    runDirectory = vectra.data.createRunDirectory(resolved);
    rawFile = fullfile(runDirectory, "simulation_raw.mat");
    save(rawFile, "tout", "yout", "allocationDiagnostics", "-v7.3");
    processed = struct("state", data, "wrench", wrench);
    metadata = struct( ...
        "runId", resolved.runId, ...
        "geometryId", string(resolved.geometry.geometryId), ...
        "modelVersion", string(quadModel.modelVersion), ...
        "validation", validation);
    result.processedFile = vectra.data.saveProcessedRun( ...
        resolved.runId, processed, metadata);
    result.rawFile = string(rawFile);
end
end

function wrench = calculateWrenchTimetable(data, wrenchMatrix)
rpmNames = "Motor" + (1:4) + "_rpm";
rpm = data{:, cellstr(rpmNames)};
wrenchValues = (wrenchMatrix * (rpm .^ 2)')';
wrench = array2timetable(wrenchValues, ...
    "RowTimes", data.Properties.RowTimes, ...
    "VariableNames", [ ...
    "Fx_body_N", "Fy_body_N", "Fz_body_N", ...
    "Mx_body_Nm", "My_body_Nm", "Mz_body_Nm"]);
end
