function data = importWindCsv(filename)
%IMPORTWINDCSV Import and normalize an external wind-sensor CSV file.

filename = string(filename);
if ~isfile(filename)
    error("vectra:sensors:FileNotFound", ...
        "Wind sensor CSV not found: %s", filename);
end

raw = readtable(filename, "VariableNamingRule", "preserve");
originalNames = string(raw.Properties.VariableNames);
normalizedNames = lower(regexprep(originalNames, "[^a-zA-Z0-9]", ""));

timeIndex = find(ismember(normalizedNames, ...
    ["time", "times", "timesec", "seconds", "timestamp"]), 1);
speedIndex = find(ismember(normalizedNames, ...
    ["windspeed", "windspeedmps", "speedmps"]), 1);
directionIndex = find(ismember(normalizedNames, ...
    ["winddirection", "winddirectiondeg", "directiondeg"]), 1);

if isempty(timeIndex) || isempty(speedIndex)
    error("vectra:sensors:InvalidWindCsv", ...
        "Wind CSV requires a time column and a wind-speed column. " + ...
        "Recognized examples are time_s and wind_speed_mps.");
end

timeValue = raw.(originalNames(timeIndex));
elapsedSeconds = vectra.util.secondsVector(timeValue);
rowTimes = seconds(elapsedSeconds);
windSpeedMps = double(raw.(originalNames(speedIndex)));

if isempty(directionIndex)
    windDirectionDeg = NaN(height(raw), 1);
else
    windDirectionDeg = double(raw.(originalNames(directionIndex)));
end

data = timetable(rowTimes, windSpeedMps, windDirectionDeg, ...
    'VariableNames', {'WindSpeed_mps', 'WindDirection_deg'});
data.Properties.DimensionNames{1} = 'Time';
end
