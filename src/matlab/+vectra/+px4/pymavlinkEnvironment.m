function environment = pymavlinkEnvironment(profile)
%PYMAVLINKENVIRONMENT Resolve and inspect the project PyMAVLink runtime.

arguments
    profile struct = vectra.config.loadProfile("telemetry", "local_udp")
end

projectRoot = string(vectra.root());
pythonExecutable = resolveProjectPath( ...
    projectRoot, string(profile.pythonExecutable));
if ispc && ~isfile(pythonExecutable)
    pythonExecutable = fullfile(projectRoot, ...
        ".venv", "Scripts", "python.exe");
end
bridgeScript = resolveProjectPath( ...
    projectRoot, string(profile.bridgeScript));

environment = struct();
environment.pythonExecutable = pythonExecutable;
environment.bridgeScript = bridgeScript;
environment.pythonAvailable = isfile(pythonExecutable);
environment.bridgeAvailable = isfile(bridgeScript);
environment.pymavlinkAvailable = false;
environment.pymavlinkVersion = "";
environment.importOutput = "";

if environment.pythonAvailable && environment.bridgeAvailable
    command = quoteShell(pythonExecutable) + " " + ...
        quoteShell(bridgeScript) + " --version";
    [status, output] = system(command);
    environment.importOutput = strtrim(string(output));
    if status == 0
        lines = splitlines(strtrim(string(output)));
        try
            record = jsondecode(lines(end));
            if isfield(record, "PyMavlinkVersion")
                environment.pymavlinkVersion = ...
                    string(record.PyMavlinkVersion);
                environment.pymavlinkAvailable = true;
            end
        catch
        end
    end
end

environment.ready = environment.pythonAvailable && ...
    environment.bridgeAvailable && environment.pymavlinkAvailable;
environment.installCommand = quoteShell(pythonExecutable) + ...
    " -m pip install -r " + quoteShell(fullfile( ...
        projectRoot, "config", "telemetry", "requirements.txt"));

issues = strings(0, 1);
if ~environment.pythonAvailable
    issues(end + 1, 1) = ...
        "Project Python environment is missing.";
end
if ~environment.bridgeAvailable
    issues(end + 1, 1) = ...
        "PyMAVLink bridge script is missing.";
end
if environment.pythonAvailable && ~environment.pymavlinkAvailable
    issues(end + 1, 1) = ...
        "PyMAVLink is not installed in the project environment.";
end
environment.issues = issues;
end

function value = resolveProjectPath(projectRoot, configuredPath)
if isAbsolutePath(configuredPath)
    value = configuredPath;
else
    value = fullfile(projectRoot, configuredPath);
end
end

function result = isAbsolutePath(pathValue)
pathValue = char(pathValue);
if ispc
    result = ~isempty(regexp(pathValue, ...
        "^[A-Za-z]:[\\/]|^\\\\", "once"));
else
    result = startsWith(pathValue, "/");
end
end

function value = quoteShell(pathValue)
pathValue = string(pathValue);
if ispc
    if contains(pathValue, """")
        error("vectra:px4:UnsafeRuntimePath", ...
            "Runtime paths cannot contain a double quote.");
    end
    value = """" + pathValue + """";
else
    if contains(pathValue, "'")
        error("vectra:px4:UnsafeRuntimePath", ...
            "Runtime paths cannot contain an apostrophe.");
    end
    value = "'" + pathValue + "'";
end
end
