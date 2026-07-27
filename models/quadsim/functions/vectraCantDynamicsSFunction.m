function vectraCantDynamicsSFunction(block)
%VECTRACANTDYNAMICSSFUNCTION QuadSim-compatible cant-aware rigid-body model.
%
% This VECTRA-owned Level-2 MATLAB S-function preserves the state ordering
% and rigid-body equations of the QuadSim 2014 dynamics function while
% replacing its vertical-only rotor wrench and z-axis-only gyroscopic term.
% QuadSim is distributed under the GNU Lesser General Public License.

setup(block);
end

function setup(block)
block.NumInputPorts = 5;
block.NumOutputPorts = 12;

for index = 1:4
    block.InputPort(index).Dimensions = 1;
    block.InputPort(index).DirectFeedthrough = false;
    block.InputPort(index).SamplingMode = "Sample";
end
block.InputPort(5).Dimensions = 6;
block.InputPort(5).DirectFeedthrough = false;
block.InputPort(5).SamplingMode = "Sample";

for index = 1:12
    block.OutputPort(index).Dimensions = 1;
    block.OutputPort(index).SamplingMode = "Sample";
end

block.NumDialogPrms = 2;
block.NumContStates = 12;
block.SampleTimes = [0, 0];
block.SetAccelRunOnTLC(false);
block.SimStateCompliance = "DefaultSimState";

block.RegBlockMethod("CheckParameters", @checkParameters);
block.RegBlockMethod("InitializeConditions", @initializeConditions);
block.RegBlockMethod("Outputs", @outputs);
block.RegBlockMethod("Derivatives", @derivatives);
end

function checkParameters(block)
quad = block.DialogPrm(1).Data;
required = [
    "mass", "g", "Jb", "Jbinv", "wrenchMatrix", ...
    "rotorAxesBody", "rotorSpinSigns", "jmPerMotor"
];
missing = required(~isfield(quad, required));
if ~isempty(missing)
    error("vectra:quadsim:InvalidCantQuadModel", ...
        "Cant quadModel is missing fields: %s", strjoin(missing, ", "));
end
end

function initializeConditions(block)
initial = block.DialogPrm(2).Data;
state = [
    initial.P * pi / 180
    initial.Q * pi / 180
    initial.R * pi / 180
    initial.Phi * pi / 180
    initial.The * pi / 180
    initial.Psi * pi / 180
    initial.U
    initial.V
    initial.W
    initial.X
    initial.Y
    initial.Z
];
block.ContStates.Data = state;
for index = 1:12
    block.OutputPort(index).Data = state(index);
end
end

function outputs(block)
for index = 1:12
    block.OutputPort(index).Data = block.ContStates.Data(index);
end
end

function derivatives(block)
quad = block.DialogPrm(1).Data;
state = block.ContStates.Data;

P = state(1);
Q = state(2);
R = state(3);
Phi = state(4);
The = state(5);
Psi = state(6);
bodyVelocity = state(7:9);
Z = state(12);

motorRpm = zeros(4, 1);
for index = 1:4
    motorRpm(index) = block.InputPort(index).Data;
end
disturbance = block.InputPort(5).Data;
disturbanceMomentBody = disturbance(1:3);
disturbanceForceInertial = disturbance(4:6);

rpmSquared = motorRpm .^ 2;
forceBody = quad.wrenchMatrix(1:3, :) * rpmSquared;
propulsiveMomentBody = quad.wrenchMatrix(4:6, :) * rpmSquared;

bodyRates = [P; Q; R];
rotorAngularSpeed = motorRpm * (2 * pi / 60);
signedAngularMomentum = quad.rotorSpinSigns(:) .* ...
    quad.jmPerMotor(:) .* rotorAngularSpeed;
rotorMomentumBody = quad.rotorAxesBody * signedAngularMomentum;
gyroMomentBody = -cross(bodyRates, rotorMomentumBody);

totalMomentBody = propulsiveMomentBody + gyroMomentBody + ...
    disturbanceMomentBody;
omegaCross = [
    0, -R, Q
    R, 0, -P
    -Q, P, 0
];
bodyRateDerivative = quad.Jbinv * ...
    (totalMomentBody - omegaCross * quad.Jb * bodyRates);

eulerRateMatrix = [
    1, tan(The) * sin(Phi), tan(The) * cos(Phi)
    0, cos(Phi), -sin(Phi)
    0, sin(Phi) / cos(The), cos(Phi) / cos(The)
];
eulerDerivative = eulerRateMatrix * bodyRates;

rotationInertialFromBody = [
    cos(Psi)*cos(The), ...
        cos(Psi)*sin(The)*sin(Phi)-sin(Psi)*cos(Phi), ...
        cos(Psi)*sin(The)*cos(Phi)+sin(Psi)*sin(Phi)
    sin(Psi)*cos(The), ...
        sin(Psi)*sin(The)*sin(Phi)+cos(Psi)*cos(Phi), ...
        sin(Psi)*sin(The)*cos(Phi)-cos(Psi)*sin(Phi)
    -sin(The), cos(The)*sin(Phi), cos(The)*cos(Phi)
];
rotationBodyFromInertial = rotationInertialFromBody';
gravityBody = rotationBodyFromInertial * [0; 0; -quad.g];
disturbanceForceBody = rotationBodyFromInertial * ...
    disturbanceForceInertial;

bodyVelocityDerivative = forceBody / quad.mass + gravityBody + ...
    disturbanceForceBody - omegaCross * bodyVelocity;
positionDerivative = rotationInertialFromBody * bodyVelocity;

if Z <= 0 && positionDerivative(3) <= 0
    positionDerivative(3) = 0;
    block.ContStates.Data(12) = 0;
end

block.Derivatives.Data = [
    bodyRateDerivative
    eulerDerivative
    bodyVelocityDerivative
    positionDerivative
];
end
