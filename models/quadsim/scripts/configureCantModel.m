function report = configureCantModel()
%CONFIGURECANTMODEL Reproducibly wire VECTRA cant dynamics and allocation.

setupVECTRA();
locations = vectra.quadsim.paths();
vectra.quadsim.setupPaths();

modelFile = fullfile(locations.vectraModels, ...
    "VECTRA_Cant_Quadcopter_Simulation.slx");
if ~isfile(modelFile)
    error("vectra:quadsim:CantModelNotFound", ...
        "Cant model is missing: %s", modelFile);
end

[~, modelName] = fileparts(modelFile);
vehicleData = load(fullfile(locations.vehicleModels, "quadModel_+.mat"));
initialData = load(fullfile(locations.initialConditions, "Hover.mat"));
zeroProfile = vectra.config.loadProfile("geometries", "cant_00");
editingQuadModel = vectra.quadsim.extendQuadModel( ...
    vehicleData.quadModel, zeroProfile);

hadQuadModel = evalin("base", "exist('quadModel','var') == 1");
hadInitialConditions = evalin("base", "exist('IC','var') == 1");
if hadQuadModel
    previousQuadModel = evalin("base", "quadModel");
else
    previousQuadModel = [];
end
if hadInitialConditions
    previousInitialConditions = evalin("base", "IC");
else
    previousInitialConditions = [];
end
assignin("base", "quadModel", editingQuadModel);
assignin("base", "IC", initialData.IC);

fprintf("VECTRA_CANT_CONFIG: load_model\n");
load_system(modelFile);
cleanup = onCleanup(@() cleanupEditingSession( ...
    modelName, hadQuadModel, previousQuadModel, ...
    hadInitialConditions, previousInitialConditions));

stateBlocks = find_system(modelName, "LookUnderMasks", "all", ...
    "FollowLinks", "on", "Name", "State Equations");
if numel(stateBlocks) ~= 1
    error("vectra:quadsim:UnexpectedStateBlockCount", ...
        "Expected one State Equations block, found %d.", ...
        numel(stateBlocks));
end
set_param(stateBlocks{1}, ...
    "FunctionName", "vectraCantDynamicsSFunction", ...
    "Parameters", "quadModel, IC");
fprintf("VECTRA_CANT_CONFIG: state_function\n");

motorBlocks = find_system(modelName, "LookUnderMasks", "all", ...
    "FollowLinks", "on", "Name", "Motor Dynamics");
if numel(motorBlocks) ~= 1
    error("vectra:quadsim:UnexpectedMotorBlockCount", ...
        "Expected one Motor Dynamics block, found %d.", ...
        numel(motorBlocks));
end
motorBlock = motorBlocks{1};
parent = get_param(motorBlock, "Parent");
allocatorBlock = parent + "/Cant Control Allocation";

if getSimulinkBlockHandle(allocatorBlock) == -1
    add_block("simulink/User-Defined Functions/Level-2 MATLAB S-Function", ...
        allocatorBlock, ...
        "FunctionName", "vectraCantAllocatorSFunction", ...
        "Parameters", "quadModel", ...
        "Position", [170, 65, 270, 425]);
else
    set_param(allocatorBlock, ...
        "FunctionName", "vectraCantAllocatorSFunction", ...
        "Parameters", "quadModel");
end
fprintf("VECTRA_CANT_CONFIG: allocator_block\n");

motorPorts = get_param(motorBlock, "PortHandles");
allocatorPorts = get_param(allocatorBlock, "PortHandles");
for index = 1:4
    motorLine = get_param(motorPorts.Inport(index), "Line");
    if motorLine == -1
        error("vectra:quadsim:DisconnectedMotorInput", ...
            "Motor Dynamics input %d is disconnected.", index);
    end
    sourcePort = get_param(motorLine, "SrcPortHandle");
    sourceParent = get_param(get_param(sourcePort, "Parent"), "Name");
    if string(sourceParent) ~= "Cant Control Allocation"
        delete_line(motorLine);
        add_line(parent, sourcePort, allocatorPorts.Inport(index), ...
            "autorouting", "on");
        add_line(parent, allocatorPorts.Outport(index), ...
            motorPorts.Inport(index), "autorouting", "on");
    end
end
fprintf("VECTRA_CANT_CONFIG: allocator_wiring\n");

diagnosticBlock = parent + "/Cant Allocation Diagnostics";
if getSimulinkBlockHandle(diagnosticBlock) == -1
    add_block("simulink/Sinks/To Workspace", diagnosticBlock, ...
        "VariableName", "cantAllocationDiagnostics", ...
        "SaveFormat", "Structure With Time", ...
        "Position", [310, 470, 450, 500]);
end
diagnosticPorts = get_param(diagnosticBlock, "PortHandles");
diagnosticLine = get_param(diagnosticPorts.Inport, "Line");
if diagnosticLine == -1
    add_line(parent, allocatorPorts.Outport(5), ...
        diagnosticPorts.Inport, "autorouting", "on");
end
fprintf("VECTRA_CANT_CONFIG: diagnostics\n");

set_param(modelName, "SignalLogging", "on");
fprintf("VECTRA_CANT_CONFIG: save_start\n");
save_system(modelName, modelFile);
fprintf("VECTRA_CANT_CONFIG: save_complete\n");

report = struct();
report.modelFile = string(modelFile);
report.stateEquationBlock = string(stateBlocks{1});
report.stateFunction = string(get_param(stateBlocks{1}, "FunctionName"));
report.allocatorBlock = string(allocatorBlock);
report.diagnosticsVariable = "cantAllocationDiagnostics";
fprintf("VECTRA_CANT_CONFIG: cleanup_start\n");
clear cleanup
fprintf("VECTRA_CANT_CONFIG: complete\n");
end

function cleanupEditingSession(modelName, hadQuadModel, previousQuadModel, ...
    hadInitialConditions, previousInitialConditions)
if bdIsLoaded(modelName)
    close_system(modelName, 0);
end
restoreBaseVariable("quadModel", hadQuadModel, previousQuadModel);
restoreBaseVariable("IC", hadInitialConditions, previousInitialConditions);
end

function restoreBaseVariable(name, existed, previousValue)
if existed
    assignin("base", name, previousValue);
else
    evalin("base", "clear " + name);
end
end
