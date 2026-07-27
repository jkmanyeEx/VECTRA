function metrics = calculateMetrics(data)
%CALCULATEMETRICS Calculate core attitude, position, and actuator metrics.

arguments
    data timetable
end

vectra.util.requireVariables(data, ...
    ["Roll_rad", "Pitch_rad", "Yaw_rad"], "flight data");

metrics = struct();
metrics.sampleCount = height(data);
if height(data) < 2
    metrics.durationSec = 0;
else
    rowTimes = data.Properties.RowTimes;
    metrics.durationSec = seconds(rowTimes(end) - rowTimes(1));
end

metrics.rollRmsDeg = sqrt(mean(rad2deg(data.Roll_rad).^2, "omitnan"));
metrics.pitchRmsDeg = sqrt(mean(rad2deg(data.Pitch_rad).^2, "omitnan"));
metrics.yawRmsDeg = sqrt(mean(rad2deg(data.Yaw_rad).^2, "omitnan"));
metrics.maxAbsoluteRollDeg = max(abs(rad2deg(data.Roll_rad)), [], "omitnan");
metrics.maxAbsolutePitchDeg = max(abs(rad2deg(data.Pitch_rad)), [], "omitnan");

available = string(data.Properties.VariableNames);
if all(ismember(["RollCmd_rad", "PitchCmd_rad", "YawCmd_rad"], available))
    rollError = data.Roll_rad - data.RollCmd_rad;
    pitchError = data.Pitch_rad - data.PitchCmd_rad;
    rawYawError = data.Yaw_rad - data.YawCmd_rad;
    yawError = atan2(sin(rawYawError), cos(rawYawError));
    metrics.rollTrackingRmseDeg = sqrt(mean(rad2deg(rollError).^2, ...
        "omitnan"));
    metrics.pitchTrackingRmseDeg = sqrt(mean(rad2deg(pitchError).^2, ...
        "omitnan"));
    metrics.yawTrackingRmseDeg = sqrt(mean(rad2deg(yawError).^2, ...
        "omitnan"));
end

if all(ismember(["X_m", "Y_m", "Z_m"], available))
    displacement = [ ...
        data.X_m - data.X_m(1), ...
        data.Y_m - data.Y_m(1), ...
        data.Z_m - data.Z_m(1)];
    positionErrorMagnitude = vecnorm(displacement, 2, 2);
    metrics.positionHoldRmseM = sqrt(mean(positionErrorMagnitude.^2, ...
        "omitnan"));
    metrics.maximumDisplacementM = max(positionErrorMagnitude, [], ...
        "omitnan");
end

throttleNames = "Motor" + (1:4) + "_throttle_pct";
if all(ismember(throttleNames, available))
    throttle = data{:, cellstr(throttleNames)};
    metrics.maximumThrottlePercent = max(throttle, [], "all", "omitnan");
    metrics.throttleSaturationFraction = mean(throttle >= 99, ...
        "all", "omitnan");
end
end
