function app = launchTelemetryApp(options)
%LAUNCHTELEMETRYAPP Launch the VECTRA PX4 telemetry operator console.

arguments
    options.Source (1,1) string {mustBeMember( ...
        options.Source, ["hardware", "simulated"])} = "hardware"
    options.AutoConnect (1,1) logical = false
    options.TestMode (1,1) logical = false
    options.Visible (1,1) string {mustBeMember( ...
        options.Visible, ["on", "off"])} = "on"
end

setupVECTRA();
appDirectory = fullfile(vectra.root(), "apps");
addpath(appDirectory);

autoSimulated = options.Source == "simulated" && options.AutoConnect;
app = VectraTelemetryApp( ...
    Visible=options.Visible, ...
    TestMode=options.TestMode, ...
    AutoConnectSimulated=autoSimulated);
end
