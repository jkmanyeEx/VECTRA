function outputFile = saveProcessedRun(runId, data, metadata)
%SAVEPROCESSEDRUN Save normalized data and metadata for a run.

arguments
    runId (1,1) string
    data
    metadata struct = struct()
end

outputDirectory = fullfile(vectra.root(), "data", "processed", runId);
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

outputFile = fullfile(outputDirectory, "normalized.mat");
save(outputFile, "data", "metadata", "-v7.3");
vectra.data.writeJson(fullfile(outputDirectory, "metadata.json"), metadata);
end
