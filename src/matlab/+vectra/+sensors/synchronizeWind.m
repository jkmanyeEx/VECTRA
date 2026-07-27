function combined = synchronizeWind(flightData, windData, sampleTimeSec)
%SYNCHRONIZEWIND Align flight and wind timetables to a common time grid.

arguments
    flightData timetable
    windData timetable
    sampleTimeSec (1,1) double {mustBePositive} = 0.02
end

combined = synchronize(flightData, windData, "regular", "linear", ...
    "TimeStep", seconds(sampleTimeSec));
end
