function geometry = buildRotorGeometry(profile, armLengthM)
%BUILDROTORGEOMETRY Resolve a four-rotor QuadSim geometry profile.

arguments
    profile (1,1) struct
    armLengthM (1,1) double {mustBePositive, mustBeFinite}
end

requiredFields = [
    "coordinateFrame"
    "axisMeaning"
    "motorOrder"
    "cantType"
    "motorCantAnglesDeg"
    "motorAzimuthsDeg"
    "motorSpinDirections"
];
missingFields = requiredFields(~isfield(profile, requiredFields));
if ~isempty(missingFields)
    error("vectra:quadsim:MissingGeometryFields", ...
        "Geometry profile is missing fields: %s", ...
        strjoin(missingFields, ", "));
end

if string(profile.coordinateFrame) ~= "QUADSIM_BODY_XY_ZUP"
    error("vectra:quadsim:UnsupportedCoordinateFrame", ...
        "Expected QUADSIM_BODY_XY_ZUP geometry.");
end
if string(profile.axisMeaning) ~= "FORCE_ON_BODY"
    error("vectra:quadsim:UnsupportedAxisMeaning", ...
        "Rotor axes must describe force on the vehicle body.");
end

motorOrder = string(profile.motorOrder(:));
if numel(motorOrder) ~= 4 || numel(unique(motorOrder)) ~= 4
    error("vectra:quadsim:InvalidMotorOrder", ...
        "Geometry must define four unique motors.");
end

azimuthDeg = rowOfFour(profile.motorAzimuthsDeg, "motorAzimuthsDeg");
cantAnglesDeg = effectiveCantAngles(profile);
motorPositionsBodyM = resolveMotorPositions( ...
    profile, armLengthM, azimuthDeg);
rotorAxesBody = resolveRotorAxes(profile, azimuthDeg, cantAnglesDeg);

spinDirections = upper(string(profile.motorSpinDirections(:)'));
if numel(spinDirections) ~= 4 || ...
        any(~ismember(spinDirections, ["CW", "CCW"]))
    error("vectra:quadsim:InvalidSpinDirections", ...
        "motorSpinDirections must contain four CW or CCW values.");
end

rotorSpinSigns = ones(1, 4);
rotorSpinSigns(spinDirections == "CW") = -1;
reactionTorqueSigns = -rotorSpinSigns;

geometry = struct();
geometry.coordinateFrame = "QUADSIM_BODY_XY_ZUP";
geometry.axisMeaning = "FORCE_ON_BODY";
geometry.motorOrder = motorOrder';
geometry.motorPositionsBodyM = motorPositionsBodyM;
geometry.rotorAxesBody = rotorAxesBody;
geometry.motorAzimuthsDeg = azimuthDeg;
geometry.cantAnglesDeg = cantAnglesDeg;
geometry.rotorSpinSigns = rotorSpinSigns;
geometry.reactionTorqueSigns = reactionTorqueSigns;
geometry.cantType = string(profile.cantType);
if isfield(profile, "geometryId")
    geometry.geometryId = string(profile.geometryId);
else
    geometry.geometryId = "unspecified";
end
if isfield(profile, "geometryRevision")
    geometry.geometryRevision = string(profile.geometryRevision);
else
    geometry.geometryRevision = "unspecified";
end
end

function angles = effectiveCantAngles(profile)
angles = rowOfFour(profile.motorCantAnglesDeg, ...
    "motorCantAnglesDeg");
if isfield(profile, "measuredMotorCantAnglesDeg")
    measured = rowOfFour(profile.measuredMotorCantAnglesDeg, ...
        "measuredMotorCantAnglesDeg");
    useMeasured = isfinite(measured);
    angles(useMeasured) = measured(useMeasured);
end
if any(abs(angles) >= 90)
    error("vectra:quadsim:InvalidCantAngle", ...
        "Cant angles must be strictly between -90 and 90 degrees.");
end
end

function positions = resolveMotorPositions(profile, armLengthM, azimuthDeg)
if isfield(profile, "motorPositionsBodyM") && ...
        ~isempty(profile.motorPositionsBodyM)
    positions = matrixThreeByFour(profile.motorPositionsBodyM, ...
        "motorPositionsBodyM");
else
    azimuthRad = deg2rad(azimuthDeg);
    positions = [
        armLengthM * cos(azimuthRad)
        armLengthM * sin(azimuthRad)
        zeros(1, 4)
    ];
end
end

function axesBody = resolveRotorAxes(profile, azimuthDeg, cantAnglesDeg)
cantType = string(profile.cantType);
if cantType == "custom"
    if ~isfield(profile, "customRotorAxesBody") || ...
            isempty(profile.customRotorAxesBody)
        error("vectra:quadsim:MissingCustomRotorAxes", ...
            "Custom cant geometry requires customRotorAxesBody.");
    end
    axesBody = matrixThreeByFour(profile.customRotorAxesBody, ...
        "customRotorAxesBody");
    norms = vecnorm(axesBody, 2, 1);
    if any(abs(norms - 1) > 1e-10)
        error("vectra:quadsim:InvalidRotorAxis", ...
            "Custom rotor axes must be unit vectors.");
    end
    return
end

azimuthRad = deg2rad(azimuthDeg);
cantRad = deg2rad(cantAnglesDeg);
radial = [cos(azimuthRad); sin(azimuthRad); zeros(1, 4)];
tangential = [-sin(azimuthRad); cos(azimuthRad); zeros(1, 4)];

switch cantType
    case "radial-outward"
        horizontal = radial;
    case "radial-inward"
        horizontal = -radial;
    case "tangential"
        horizontal = tangential;
    otherwise
        error("vectra:quadsim:UnsupportedCantType", ...
            "Unsupported cant type: %s", cantType);
end

axesBody = horizontal .* sin(cantRad) + ...
    repmat([0; 0; 1], 1, 4) .* cos(cantRad);
end

function values = rowOfFour(values, fieldName)
values = double(values);
if numel(values) ~= 4
    error("vectra:quadsim:InvalidGeometryField", ...
        "%s must contain four values.", fieldName);
end
values = reshape(values, 1, 4);
end

function values = matrixThreeByFour(values, fieldName)
values = double(values);
if isequal(size(values), [4, 3])
    values = values';
elseif ~isequal(size(values), [3, 4])
    error("vectra:quadsim:InvalidGeometryField", ...
        "%s must be a four-by-three motor list.", fieldName);
end
end
