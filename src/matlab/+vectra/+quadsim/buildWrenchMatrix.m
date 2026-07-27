function matrix = buildWrenchMatrix(motorPositionsM, rotorAxes, ...
    reactionTorqueSigns, thrustCoefficient, torqueCoefficient)
%BUILDWRENCHMATRIX Build the 6-by-4 rotor force/moment allocation matrix.

arguments
    motorPositionsM (3,4) double {mustBeFinite}
    rotorAxes (3,4) double {mustBeFinite}
    reactionTorqueSigns (1,4) double ...
        {mustBeMember(reactionTorqueSigns, [-1, 1])}
    thrustCoefficient (1,:) double {mustBePositive}
    torqueCoefficient (1,:) double {mustBeNonnegative}
end

axisNorms = vecnorm(rotorAxes, 2, 1);
if any(abs(axisNorms - 1) > 1e-10)
    error("vectra:quadsim:InvalidRotorAxis", ...
        "Every rotor axis must be a unit vector.");
end

thrustCoefficient = expandPerMotor(thrustCoefficient, ...
    "thrustCoefficient");
torqueCoefficient = expandPerMotor(torqueCoefficient, ...
    "torqueCoefficient");

matrix = zeros(6, 4);
for motorIndex = 1:4
    forcePerRpm2 = thrustCoefficient(motorIndex) * ...
        rotorAxes(:, motorIndex);
    armMomentPerRpm2 = cross( ...
        motorPositionsM(:, motorIndex), forcePerRpm2);
    reactionMomentPerRpm2 = reactionTorqueSigns(motorIndex) * ...
        torqueCoefficient(motorIndex) * rotorAxes(:, motorIndex);
    matrix(:, motorIndex) = [
        forcePerRpm2
        armMomentPerRpm2 + reactionMomentPerRpm2
    ];
end
end

function values = expandPerMotor(values, argumentName)
if isscalar(values)
    values = repmat(values, 1, 4);
elseif numel(values) ~= 4
    error("vectra:quadsim:InvalidPerMotorCoefficient", ...
        "%s must be scalar or contain four motor values.", argumentName);
else
    values = reshape(values, 1, 4);
end
end
