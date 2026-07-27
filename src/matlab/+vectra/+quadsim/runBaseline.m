function result = runBaseline(experimentProfile, durationSec)
%RUNBASELINE Run the unmodified upstream QuadSim attitude-control model.

arguments
    experimentProfile (1,1) string = "smoke_hover"
    durationSec (1,1) double {mustBePositive, mustBeFinite} = 10
end

resolved = vectra.config.resolveRun(experimentProfile, "simulation");
locations = vectra.quadsim.paths();
vectra.quadsim.setupPaths();

modelName = string(resolved.experiment.simulationModel);
modelFile = fullfile(locations.models, modelName + ".slx");
if ~isfile(modelFile)
    error("vectra:quadsim:ModelNotFound", ...
        "QuadSim model not found: %s", modelFile);
end

initialConditionFile = fullfile(locations.initialConditions, ...
    string(resolved.experiment.initialCondition) + ".mat");
vehicleModelFile = fullfile(locations.vehicleModels, "quadModel_+.mat");

initialConditionData = load(initialConditionFile);
vehicleModelData = load(vehicleModelFile);
if ~isfield(initialConditionData, "IC")
    error("vectra:quadsim:InvalidInitialCondition", ...
        "Initial-condition file does not contain IC: %s", ...
        initialConditionFile);
end
if ~isfield(vehicleModelData, "quadModel")
    error("vectra:quadsim:InvalidVehicleModel", ...
        "Vehicle model file does not contain quadModel: %s", ...
        vehicleModelFile);
end

load_system(modelFile);
simulationInput = Simulink.SimulationInput(char(modelName));
simulationInput = simulationInput.setVariable("IC", initialConditionData.IC);
simulationInput = simulationInput.setVariable( ...
    "quadModel", vehicleModelData.quadModel);
simulationInput = simulationInput.setModelParameter( ...
    "StopTime", string(durationSec));

simulationOutput = sim(simulationInput);
yout = simulationOutput.get("yout");
tout = simulationOutput.get("tout");

result = struct();
result.config = resolved;
result.raw = struct("tout", tout, "yout", yout);
result.data = vectra.quadsim.normalizeOutput(yout, tout);
end
