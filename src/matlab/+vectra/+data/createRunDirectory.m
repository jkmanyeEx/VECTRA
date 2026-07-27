function runDirectory = createRunDirectory(resolved)
%CREATERUNDIRECTORY Create an immutable raw-data directory for one run.

if ~isstruct(resolved) || ~isfield(resolved, "runId")
    error("vectra:data:InvalidResolvedConfig", ...
        "Resolved configuration must contain runId.");
end

runDirectory = fullfile(vectra.root(), "data", "raw", ...
    string(resolved.runId));
if isfolder(runDirectory)
    error("vectra:data:RunAlreadyExists", ...
        "Run directory already exists: %s", runDirectory);
end

mkdir(runDirectory);
vectra.data.writeJson(fullfile(runDirectory, ...
    "resolved_config.json"), resolved);
end
