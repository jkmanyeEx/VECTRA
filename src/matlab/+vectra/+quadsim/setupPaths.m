function addedPaths = setupPaths()
%SETUPPATHS Add only the QuadSim directories required for execution.

locations = vectra.quadsim.paths();
addedPaths = [
    string(locations.models)
    string(locations.functions)
    string(locations.initialConditions)
    string(locations.vehicleModels)
    string(locations.pathCommands)
    string(locations.vectraModels)
    string(locations.vectraFunctions)
    string(locations.vectraScripts)
];

missing = addedPaths(~isfolder(addedPaths));
if ~isempty(missing)
    error("vectra:quadsim:MissingDependency", ...
        "QuadSim directories are missing: %s", strjoin(missing, ", "));
end

for index = 1:numel(addedPaths)
    addpath(addedPaths(index));
end
end
