function allocation = allocateMotorCommands(referenceRpm, ...
    zeroActiveMatrix, cantActiveMatrix, maximumRpm)
%ALLOCATEMOTORCOMMANDS Map a zero-cant RPM request to a cant geometry.

arguments
    referenceRpm (4,1) double {mustBeFinite, mustBeNonnegative}
    zeroActiveMatrix (4,4) double {mustBeFinite}
    cantActiveMatrix (4,4) double {mustBeFinite}
    maximumRpm (1,:) double {mustBePositive} = Inf
end

if rank(cantActiveMatrix) ~= 4
    error("vectra:quadsim:RankDeficientAllocation", ...
        "Cant active-control matrix must have rank four.");
end

if isscalar(maximumRpm)
    maximumRpm = repmat(maximumRpm, 4, 1);
elseif numel(maximumRpm) == 4
    maximumRpm = reshape(maximumRpm, 4, 1);
else
    error("vectra:quadsim:InvalidMaximumRpm", ...
        "maximumRpm must be scalar or contain four values.");
end

qReference = referenceRpm .^ 2;
desiredWrench = zeroActiveMatrix * qReference;
if isequal(cantActiveMatrix, zeroActiveMatrix)
    qRequested = qReference;
else
    qRequested = cantActiveMatrix \ desiredWrench;
end

numericalTolerance = max(1, max(qReference)) * 1e-12;
negativeDemand = qRequested < -numericalTolerance;
overSpeedDemand = qRequested > maximumRpm .^ 2 + numericalTolerance;
qCommand = min(max(qRequested, 0), maximumRpm .^ 2);
achievedWrench = cantActiveMatrix * qCommand;

allocation = struct();
allocation.referenceRpm = referenceRpm;
allocation.qReference = qReference;
allocation.desiredWrench = desiredWrench;
allocation.qRequested = qRequested;
allocation.requestedRpm = sqrt(max(qRequested, 0));
allocation.qCommand = qCommand;
allocation.commandRpm = sqrt(qCommand);
allocation.achievedWrench = achievedWrench;
allocation.residual = achievedWrench - desiredWrench;
allocation.residualNorm = norm(allocation.residual);
allocation.negativeDemand = negativeDemand;
allocation.overSpeedDemand = overSpeedDemand;
allocation.feasible = ~any(negativeDemand | overSpeedDemand);
end
