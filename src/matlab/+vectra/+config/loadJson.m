function value = loadJson(filename)
%LOADJSON Read a UTF-8 JSON file into a MATLAB value.

filename = string(filename);
if ~isfile(filename)
    candidate = fullfile(vectra.root(), "config", filename);
    if isfile(candidate)
        filename = candidate;
    else
        error("vectra:config:FileNotFound", ...
            "Configuration file not found: %s", filename);
    end
end

text = fileread(filename);
try
    value = jsondecode(text);
catch exception
    wrapped = MException("vectra:config:InvalidJson", ...
        "Invalid JSON in %s: %s", filename, exception.message);
    throwAsCaller(wrapped);
end
end
