function plan = flightTestPlan(experiment)
%FLIGHTTESTPLAN Build a conservative high-level hover test sequence.

arguments
    experiment struct
end

required = ["durationSec", "command"];
for index = 1:numel(required)
    if ~isfield(experiment, required(index))
        error("vectra:px4:InvalidExperiment", ...
            "Experiment is missing field: %s", required(index));
    end
end

if isfield(experiment.command, "altitudeM")
    targetAltitudeM = experiment.command.altitudeM;
else
    targetAltitudeM = 2;
end

phase = [
    "preflight"
    "arm"
    "takeoff"
    "settle"
    "measure"
    "land"
    "disarm"
];
durationSec = [
    0
    0
    5
    5
    experiment.durationSec
    5
    0
];
altitudeM = [
    0
    0
    targetAltitudeM
    targetAltitudeM
    targetAltitudeM
    0
    0
];
requiresOperatorConfirmation = [
    true
    true
    false
    false
    false
    false
    false
];

plan = table(phase, durationSec, altitudeM, ...
    requiresOperatorConfirmation);
end
