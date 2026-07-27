function files = generateComparison(comparison, outputDirectory)
%GENERATECOMPARISON Create reproducible comparison files and figures.

arguments
    comparison struct
    outputDirectory (1,1) string
end

if ~isfolder(outputDirectory)
    mkdir(outputDirectory);
end

metricsFile = fullfile(outputDirectory, "comparison_metrics.json");
metrics = struct( ...
    "simulation", comparison.simulationMetrics, ...
    "flight", comparison.flightMetrics, ...
    "residual", comparison.residualMetrics);
vectra.data.writeJson(metricsFile, metrics);

figureFile = fullfile(outputDirectory, "attitude_comparison.png");
aligned = comparison.aligned;
required = [
    "Sim_Roll_rad", "Flight_Roll_rad"
    "Sim_Pitch_rad", "Flight_Pitch_rad"
    "Sim_Yaw_rad", "Flight_Yaw_rad"
];
available = string(aligned.Properties.VariableNames);
if all(ismember(required(:), available))
    figureHandle = figure("Visible", "off", "Color", "white", ...
        "Position", [100, 100, 1200, 800]);
    cleanup = onCleanup(@() close(figureHandle));
    labels = ["Roll", "Pitch", "Yaw"];
    elapsedTime = seconds(aligned.Properties.RowTimes);
    for index = 1:3
        subplot(3, 1, index);
        plot(elapsedTime, ...
            rad2deg(aligned.(required(index, 1))), ...
            "LineWidth", 1.4);
        hold on;
        plot(elapsedTime, ...
            rad2deg(aligned.(required(index, 2))), ...
            "LineWidth", 1.2);
        grid on;
        ylabel(labels(index) + " (deg)");
        if index == 1
            legend("Simulation", "Flight", "Location", "best");
        end
    end
    xlabel("Elapsed time (s)");
    exportgraphics(figureHandle, figureFile, "Resolution", 180);
else
    figureFile = "";
end

files = struct("metrics", metricsFile, "attitudeFigure", figureFile);
end
