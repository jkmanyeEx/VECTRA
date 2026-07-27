function report = validateCantConfiguration(profile, armLengthM)
%VALIDATECANTCONFIGURATION Validate and summarize resolved rotor geometry.

arguments
    profile (1,1) struct
    armLengthM (1,1) double {mustBePositive, mustBeFinite}
end

geometry = vectra.quadsim.buildRotorGeometry(profile, armLengthM);
axisNormError = max(abs(vecnorm(geometry.rotorAxesBody, 2, 1) - 1));

report = struct();
report.valid = axisNormError <= 1e-10;
report.axisNormError = axisNormError;
report.geometry = geometry;

if ~report.valid
    error("vectra:quadsim:InvalidCantConfiguration", ...
        "Cant geometry failed unit-axis validation.");
end
end
