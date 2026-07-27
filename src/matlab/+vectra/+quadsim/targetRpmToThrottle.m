function throttlePercent = targetRpmToThrottle(rpm, quadModel)
%TARGETRPMTOTHROTTLE Invert QuadSim's static motor mapping where feasible.

arguments
    rpm double {mustBeFinite, mustBeNonnegative}
    quadModel (1,1) struct
end

if quadModel.cr <= 0
    error("vectra:quadsim:InvalidMotorSlope", ...
        "quadModel.cr must be positive.");
end

throttlePercent = zeros(size(rpm));
spinning = rpm > 0;
throttlePercent(spinning) = ...
    (rpm(spinning) - quadModel.b) ./ quadModel.cr;
throttlePercent(spinning) = max( ...
    throttlePercent(spinning), quadModel.minThr);
end
