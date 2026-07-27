function assertCalibrated(vehicle)
%ASSERTCALIBRATED Reject a vehicle profile that is not ready for research.

if ~isfield(vehicle, "calibrated") || ~vehicle.calibrated
    error("vectra:config:UncalibratedVehicle", ...
        "The selected vehicle profile is not calibrated. " + ...
        "Populate measured mass, inertia, and propulsion parameters before " + ...
        "using it for research conclusions.");
end

requiredNumericPaths = [
    "massKg"
    "armLengthM"
    "inertiaKgM2.Jxx"
    "inertiaKgM2.Jyy"
    "inertiaKgM2.Jzz"
    "motor.thrustCoefficientNPerRpm2"
    "motor.torqueCoefficientNmPerRpm2"
    "motor.maximumRpm"
];

for index = 1:numel(requiredNumericPaths)
    value = getNestedValue(vehicle, requiredNumericPaths(index));
    if isempty(value) || ~isnumeric(value) || ~isscalar(value) || ~isfinite(value)
        error("vectra:config:MissingCalibrationValue", ...
            "Missing calibrated value: %s", requiredNumericPaths(index));
    end
end
end

function value = getNestedValue(structure, fieldPath)
parts = split(fieldPath, ".");
value = structure;
for index = 1:numel(parts)
    fieldName = char(parts(index));
    if ~isstruct(value) || ~isfield(value, fieldName)
        value = [];
        return
    end
    value = value.(fieldName);
end
end
