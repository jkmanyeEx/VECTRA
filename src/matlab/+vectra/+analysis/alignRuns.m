function aligned = alignRuns(simulationData, flightData, sampleTimeSec)
%ALIGNRUNS Resample simulation and flight data onto one elapsed-time grid.

arguments
    simulationData timetable
    flightData timetable
    sampleTimeSec (1,1) double {mustBePositive} = 0.02
end

simulationData.Properties.RowTimes = seconds(vectra.util.secondsVector( ...
    simulationData.Properties.RowTimes));
flightData.Properties.RowTimes = seconds(vectra.util.secondsVector( ...
    flightData.Properties.RowTimes));

simulationData = prefixVariables(simulationData, "Sim_");
flightData = prefixVariables(flightData, "Flight_");
aligned = synchronize(simulationData, flightData, "regular", "linear", ...
    "TimeStep", seconds(sampleTimeSec));
end

function data = prefixVariables(data, prefix)
names = string(data.Properties.VariableNames);
data.Properties.VariableNames = cellstr(prefix + names);
end
