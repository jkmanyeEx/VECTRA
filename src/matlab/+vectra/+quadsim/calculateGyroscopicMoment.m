function momentBodyNm = calculateGyroscopicMoment(bodyRatesRadps, ...
    motorRpm, rotorAxesBody, rotorSpinSigns, rotorInertiaKgM2)
%CALCULATEGYROSCOPICMOMENT Calculate generalized rotor gyroscopic moment.

arguments
    bodyRatesRadps (3,1) double {mustBeFinite}
    motorRpm (4,1) double {mustBeFinite, mustBeNonnegative}
    rotorAxesBody (3,4) double {mustBeFinite}
    rotorSpinSigns (1,4) double ...
        {mustBeMember(rotorSpinSigns, [-1, 1])}
    rotorInertiaKgM2 (1,:) double {mustBeNonnegative}
end

if isscalar(rotorInertiaKgM2)
    rotorInertiaKgM2 = repmat(rotorInertiaKgM2, 1, 4);
elseif numel(rotorInertiaKgM2) == 4
    rotorInertiaKgM2 = reshape(rotorInertiaKgM2, 1, 4);
else
    error("vectra:quadsim:InvalidRotorInertia", ...
        "Rotor inertia must be scalar or contain four values.");
end

angularSpeedRadps = motorRpm' * (2 * pi / 60);
signedMomentum = rotorInertiaKgM2 .* rotorSpinSigns .* ...
    angularSpeedRadps;
rotorMomentumBody = rotorAxesBody * signedMomentum';
momentBodyNm = -cross(bodyRatesRadps, rotorMomentumBody);
end
