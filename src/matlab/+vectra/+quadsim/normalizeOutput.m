function data = normalizeOutput(yout, tout)
%NORMALIZEOUTPUT Convert upstream QuadSim arrays to a canonical timetable.

[values, time] = coerceSignals(yout, tout);
columnCount = size(values, 2);
if columnCount ~= 24 && columnCount ~= 26
    error("vectra:quadsim:UnexpectedOutputWidth", ...
        "Expected 24 or 26 QuadSim columns, received %d.", columnCount);
end

names = [ ...
    "P_radps", "Q_radps", "R_radps", ...
    "Roll_rad", "Pitch_rad", "Yaw_rad", ...
    "U_mps", "V_mps", "W_mps", ...
    "X_m", "Y_m", "Z_m", ...
    "Motor1_rpm", "Motor2_rpm", "Motor3_rpm", "Motor4_rpm", ...
    "Motor1_throttle_pct", "Motor2_throttle_pct", ...
    "Motor3_throttle_pct", "Motor4_throttle_pct", ...
    "RollCmd_rad", "PitchCmd_rad", "YawCmd_rad", "ZCmd_m"];
if columnCount == 26
    names = [names, "XCmd_m", "YCmd_m"];
end

elapsedSeconds = vectra.util.secondsVector(time);
rowTimes = seconds(elapsedSeconds);
data = array2timetable(values, 'RowTimes', rowTimes, ...
    'VariableNames', cellstr(names));
data.Properties.DimensionNames{1} = 'Time';
data.Properties.Description = ...
    "Canonical VECTRA data converted from upstream QuadSim output.";
end

function [values, time] = coerceSignals(yout, tout)
if isa(yout, "timeseries")
    values = squeeze(yout.Data);
    time = yout.Time;
elseif isstruct(yout) && isfield(yout, "signals") && ...
        isfield(yout, "time")
    values = yout.signals.values;
    time = yout.time;
else
    values = yout;
    time = tout;
end

if isa(tout, "timeseries")
    time = tout.Time;
elseif isstruct(tout) && isfield(tout, "time")
    time = tout.time;
end

values = double(values);
time = double(time(:));
if size(values, 1) ~= numel(time)
    error("vectra:quadsim:TimeLengthMismatch", ...
        "QuadSim output rows and time samples do not match.");
end
end
