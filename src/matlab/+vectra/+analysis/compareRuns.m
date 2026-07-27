function comparison = compareRuns(simulationData, flightData, sampleTimeSec)
%COMPARERUNS Calculate separate metrics and aligned signal residuals.

arguments
    simulationData timetable
    flightData timetable
    sampleTimeSec (1,1) double {mustBePositive} = 0.02
end

comparison = struct();
comparison.simulationMetrics = ...
    vectra.analysis.calculateMetrics(simulationData);
comparison.flightMetrics = vectra.analysis.calculateMetrics(flightData);
comparison.aligned = vectra.analysis.alignRuns( ...
    simulationData, flightData, sampleTimeSec);

pairs = [
    "Roll_rad", "rollResidualRmseDeg", 180 / pi
    "Pitch_rad", "pitchResidualRmseDeg", 180 / pi
    "Yaw_rad", "yawResidualRmseDeg", 180 / pi
    "X_m", "xResidualRmseM", 1
    "Y_m", "yResidualRmseM", 1
    "Z_m", "zResidualRmseM", 1
];

comparison.residualMetrics = struct();
available = string(comparison.aligned.Properties.VariableNames);
for index = 1:size(pairs, 1)
    signalName = string(pairs(index, 1));
    metricName = char(string(pairs(index, 2)));
    scale = str2double(string(pairs(index, 3)));
    simulationName = "Sim_" + signalName;
    flightName = "Flight_" + signalName;
    if all(ismember([simulationName, flightName], available))
        residual = comparison.aligned.(simulationName) - ...
            comparison.aligned.(flightName);
        comparison.residualMetrics.(metricName) = ...
            sqrt(mean((scale * residual).^2, "omitnan"));
    end
end
end
