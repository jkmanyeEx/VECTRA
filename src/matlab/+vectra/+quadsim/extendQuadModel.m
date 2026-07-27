function quadModel = extendQuadModel(upstreamQuadModel, geometryProfile)
%EXTENDQUADMODEL Add resolved cant geometry to an upstream QuadSim model.

arguments
    upstreamQuadModel (1,1) struct
    geometryProfile (1,1) struct
end

required = ["d", "ct", "cq", "Jm", "dctcq", "cr", "b", "minThr"];
missingFields = required(~isfield(upstreamQuadModel, required));
if ~isempty(missingFields)
    error("vectra:quadsim:MissingUpstreamFields", ...
        "Upstream QuadSim model is missing fields: %s", ...
        strjoin(missingFields, ", "));
end

geometry = vectra.quadsim.buildRotorGeometry( ...
    geometryProfile, upstreamQuadModel.d);
ctPerMotor = expandPerMotor(upstreamQuadModel.ct, "ct");
cqPerMotor = expandPerMotor(upstreamQuadModel.cq, "cq");
jmPerMotor = expandPerMotor(upstreamQuadModel.Jm, "Jm");

wrenchMatrix = vectra.quadsim.buildWrenchMatrix( ...
    geometry.motorPositionsBodyM, geometry.rotorAxesBody, ...
    geometry.reactionTorqueSigns, ctPerMotor, cqPerMotor);
allocation = vectra.quadsim.buildControlAllocation( ...
    wrenchMatrix, upstreamQuadModel.d);

zeroAxes = repmat([0; 0; 1], 1, 4);
zeroWrenchMatrix = vectra.quadsim.buildWrenchMatrix( ...
    geometry.motorPositionsBodyM, zeroAxes, ...
    geometry.reactionTorqueSigns, ctPerMotor, cqPerMotor);
zeroAllocation = vectra.quadsim.buildControlAllocation( ...
    zeroWrenchMatrix, upstreamQuadModel.d);

quadModel = upstreamQuadModel;
quadModel.modelVersion = "vectra-cant-1.0.0";
quadModel.coordinateFrame = geometry.coordinateFrame;
quadModel.axisMeaning = geometry.axisMeaning;
quadModel.geometryId = geometry.geometryId;
quadModel.geometryRevision = geometry.geometryRevision;
quadModel.motorOrder = geometry.motorOrder;
quadModel.motorPositionsBodyM = geometry.motorPositionsBodyM;
quadModel.rotorAxesBody = geometry.rotorAxesBody;
quadModel.rotorSpinSigns = geometry.rotorSpinSigns;
quadModel.reactionTorqueSigns = geometry.reactionTorqueSigns;
quadModel.cantAnglesDeg = geometry.cantAnglesDeg;
quadModel.ctPerMotor = ctPerMotor;
quadModel.cqPerMotor = cqPerMotor;
quadModel.jmPerMotor = jmPerMotor;
quadModel.wrenchMatrix = wrenchMatrix;
quadModel.activeControlMatrix = allocation.activeControlMatrix;
quadModel.scaledActiveControlMatrix = ...
    allocation.scaledActiveControlMatrix;
quadModel.allocationRank = allocation.rank;
quadModel.allocationConditionNumber = allocation.conditionNumber;
quadModel.zeroWrenchMatrix = zeroWrenchMatrix;
quadModel.zeroActiveControlMatrix = ...
    zeroAllocation.activeControlMatrix;
quadModel.maximumRpm = upstreamQuadModel.cr * 100 + upstreamQuadModel.b;
end

function values = expandPerMotor(values, fieldName)
values = double(values);
if isscalar(values)
    values = repmat(values, 1, 4);
elseif numel(values) == 4
    values = reshape(values, 1, 4);
else
    error("vectra:quadsim:InvalidUpstreamField", ...
        "%s must be scalar or contain four values.", fieldName);
end
end
