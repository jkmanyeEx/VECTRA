function environment = installPymavlink()
%INSTALLPYMAVLINK Create VECTRA's Python environment and install PyMAVLink.

projectRoot = string(vectra.root());
if ispc
    virtualPython = fullfile( ...
        projectRoot, ".venv", "Scripts", "python.exe");
else
    virtualPython = fullfile( ...
        projectRoot, ".venv", "bin", "python");
end

if ~isfile(virtualPython)
    command = "python3 -m venv " + quoteShell( ...
        fullfile(projectRoot, ".venv"));
    runCommand(command, "create the project Python environment");
end

requirements = fullfile( ...
    projectRoot, "config", "telemetry", "requirements.txt");
command = quoteShell(virtualPython) + ...
    " -m pip install -r " + quoteShell(requirements);
runCommand(command, "install PyMAVLink");

profile = vectra.config.loadProfile("telemetry", "local_udp");
environment = vectra.px4.pymavlinkEnvironment(profile);
if ~environment.ready
    error("vectra:px4:PyMavlinkInstallFailed", ...
        "PyMAVLink installation completed but import verification failed.");
end

[status, frozen] = system(quoteShell(virtualPython) + ...
    " -m pip freeze");
if status ~= 0
    error("vectra:px4:PyMavlinkLockFailed", ...
        "PyMAVLink installed but the package lock could not be read.");
end

lock = struct( ...
    "schemaVersion", "1.0.0", ...
    "generatedAtUtc", string(datetime("now", ...
        TimeZone="UTC", ...
        Format="yyyy-MM-dd'T'HH:mm:ss.SSSXXX")), ...
    "pythonVersion", pythonVersion(virtualPython), ...
    "pymavlinkVersion", environment.pymavlinkVersion, ...
    "packages", splitlines(strtrim(string(frozen))));
vectra.data.writeJson(fullfile(projectRoot, ...
    "config", "telemetry", "pymavlink-lock.json"), lock);

fprintf("PyMAVLink %s ready at %s\n", ...
    environment.pymavlinkVersion, virtualPython);
end

function runCommand(command, purpose)
[status, output] = system(command);
if status ~= 0
    error("vectra:px4:PyMavlinkInstallFailed", ...
        "Could not %s:\n%s", purpose, output);
end
end

function value = pythonVersion(executable)
[status, output] = system(quoteShell(executable) + " --version");
if status == 0
    value = strtrim(string(output));
else
    value = "unknown";
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
