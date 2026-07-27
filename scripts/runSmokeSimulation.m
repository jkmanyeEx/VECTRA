%RUNSMOKESIMULATION Execute and save the upstream QuadSim baseline run.

setupVECTRA();
result = vectra.quadsim.runBaseline("smoke_hover");
metrics = vectra.analysis.calculateMetrics(result.data);

outputDirectory = fullfile(vectra.root(), "results", "reports", ...
    result.config.runId);
if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

save(fullfile(outputDirectory, "smoke_result.mat"), "result", "metrics");
vectra.data.writeJson(fullfile(outputDirectory, "metrics.json"), metrics);

fprintf("Smoke simulation completed: %s\n", result.config.runId);
fprintf("Samples: %d\n", metrics.sampleCount);
fprintf("Output: %s\n", outputDirectory);
