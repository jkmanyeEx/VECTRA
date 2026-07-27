function secondsValue = secondsVector(timeValue)
%SECONDSVECTOR Convert supported time representations to elapsed seconds.

if isduration(timeValue)
    secondsValue = seconds(timeValue - timeValue(1));
elseif isdatetime(timeValue)
    secondsValue = seconds(timeValue - timeValue(1));
elseif isnumeric(timeValue)
    secondsValue = double(timeValue(:) - timeValue(1));
else
    error("vectra:data:UnsupportedTimeType", ...
        "Unsupported time type: %s", class(timeValue));
end
end
