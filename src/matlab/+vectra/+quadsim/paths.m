function value = paths()
%PATHS Return absolute paths inside the pinned QuadSim dependency.

base = fullfile(vectra.root(), "vendor", "QuadSim", ...
    "Quadcopter Dynamic Modeling and Simulation");

value = struct();
value.root = base;
value.models = fullfile(base, "Simulation Files", "Simulink Models");
value.functions = fullfile(base, "Simulation Files", "Functions");
value.initialConditions = fullfile(base, "Simulation Files", ...
    "Initial Conditions");
value.vehicleModels = fullfile(base, "Simulation Files", ...
    "Quadcopter Structure Files");
value.pathCommands = fullfile(base, "Simulation Files", ...
    "Path Command Files");
value.interfaces = fullfile(base, "Graphical User Interfaces");
value.vectraModels = fullfile(vectra.root(), "models", "quadsim");
value.vectraFunctions = fullfile(value.vectraModels, "functions");
value.vectraScripts = fullfile(value.vectraModels, "scripts");
end
