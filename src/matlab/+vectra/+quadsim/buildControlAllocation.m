function allocation = buildControlAllocation(wrenchMatrix, ...
    characteristicLengthM)
%BUILDCONTROLALLOCATION Build the active hover-control effectiveness matrix.

arguments
    wrenchMatrix (6,4) double {mustBeFinite}
    characteristicLengthM (1,1) double {mustBePositive, mustBeFinite}
end

activeRows = [3, 4, 5, 6];
active = wrenchMatrix(activeRows, :);
scale = diag([1, 1 / characteristicLengthM, ...
    1 / characteristicLengthM, 1 / characteristicLengthM]);
scaled = scale * active;
singularValues = svd(scaled);
matrixRank = rank(scaled);

allocation = struct();
allocation.wrenchMatrix = wrenchMatrix;
allocation.activeRows = activeRows;
allocation.activeControlMatrix = active;
allocation.scaledActiveControlMatrix = scaled;
allocation.rank = matrixRank;
allocation.fullRank = matrixRank == 4;
allocation.singularValues = singularValues;
if singularValues(end) > 0
    allocation.conditionNumber = singularValues(1) / singularValues(end);
else
    allocation.conditionNumber = Inf;
end

if ~allocation.fullRank
    error("vectra:quadsim:RankDeficientAllocation", ...
        "Cant geometry active control matrix must have rank four.");
end
end
