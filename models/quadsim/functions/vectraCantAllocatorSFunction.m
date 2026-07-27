function vectraCantAllocatorSFunction(block)
%VECTRACANTALLOCATORSFUNCTION Preserve the zero-cant wrench for cant geometry.

setup(block);
end

function setup(block)
block.NumInputPorts = 4;
block.NumOutputPorts = 5;
for index = 1:4
    block.InputPort(index).Dimensions = 1;
    block.InputPort(index).DirectFeedthrough = true;
    block.InputPort(index).SamplingMode = "Sample";
    block.OutputPort(index).Dimensions = 1;
    block.OutputPort(index).SamplingMode = "Sample";
end
block.OutputPort(5).Dimensions = 6;
block.OutputPort(5).SamplingMode = "Sample";

block.NumDialogPrms = 1;
block.SampleTimes = [-1, 0];
block.SetAccelRunOnTLC(false);
block.SimStateCompliance = "DefaultSimState";
block.RegBlockMethod("CheckParameters", @checkParameters);
block.RegBlockMethod("Outputs", @outputs);
end

function checkParameters(block)
quad = block.DialogPrm(1).Data;
required = [
    "zeroActiveControlMatrix", "activeControlMatrix", ...
    "cr", "b", "minThr", "maximumRpm"
];
missing = required(~isfield(quad, required));
if ~isempty(missing)
    error("vectra:quadsim:InvalidCantAllocatorModel", ...
        "Cant allocator quadModel is missing fields: %s", ...
        strjoin(missing, ", "));
end
if rank(quad.activeControlMatrix) ~= 4
    error("vectra:quadsim:RankDeficientAllocation", ...
        "Cant active-control matrix must have rank four.");
end
end

function outputs(block)
quad = block.DialogPrm(1).Data;
referenceThrottle = zeros(4, 1);
for index = 1:4
    referenceThrottle(index) = block.InputPort(index).Data;
end

referenceRpm = throttleToRpm(referenceThrottle, quad);
qReference = referenceRpm .^ 2;
desiredWrench = quad.zeroActiveControlMatrix * qReference;

if isequal(quad.activeControlMatrix, quad.zeroActiveControlMatrix)
    qRequested = qReference;
    commandThrottle = referenceThrottle;
else
    qRequested = quad.activeControlMatrix \ desiredWrench;
    commandThrottle = rpmToThrottle(sqrt(max(qRequested, 0)), quad);
end

maximumRpm = quad.maximumRpm;
qAchieved = min(max(qRequested, 0), maximumRpm ^ 2);
achievedWrench = quad.activeControlMatrix * qAchieved;
residualNorm = norm(achievedWrench - desiredWrench);
tolerance = max(1, max(qReference)) * 1e-12;
negativeDemand = any(qRequested < -tolerance);
overSpeedDemand = any(qRequested > maximumRpm ^ 2 + tolerance);
feasible = ~(negativeDemand || overSpeedDemand);

for index = 1:4
    block.OutputPort(index).Data = commandThrottle(index);
end
block.OutputPort(5).Data = [
    double(feasible)
    double(negativeDemand)
    double(overSpeedDemand)
    residualNorm
    min(qRequested)
    max(sqrt(max(qRequested, 0)))
];
end

function rpm = throttleToRpm(throttle, quad)
limitedThrottle = min(max(throttle, 0), 100);
rpm = quad.cr .* limitedThrottle + quad.b;
rpm(limitedThrottle < quad.minThr) = 0;
end

function throttle = rpmToThrottle(rpm, quad)
throttle = zeros(size(rpm));
spinning = rpm > 0;
throttle(spinning) = (rpm(spinning) - quad.b) ./ quad.cr;
throttle(spinning) = max(throttle(spinning), quad.minThr);
end
