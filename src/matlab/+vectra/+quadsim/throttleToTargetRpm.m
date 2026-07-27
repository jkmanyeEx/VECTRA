function rpm = throttleToTargetRpm(throttlePercent, quadModel)
%THROTTLETOTARGETRPM Reproduce QuadSim's static throttle-to-RPM mapping.

arguments
    throttlePercent double {mustBeFinite}
    quadModel (1,1) struct
end

throttle = min(max(throttlePercent, 0), 100);
rpm = quadModel.cr .* throttle + quadModel.b;
rpm(throttle < quadModel.minThr) = 0;
end
