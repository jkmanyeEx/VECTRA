function snapshot = normalizeTelemetryMessage(snapshot, event)
%NORMALIZETELEMETRYMESSAGE Map one MAVLink event into VECTRA live state.

arguments
    snapshot (1,1) struct
    event (1,1) struct
end

name = upper(string(event.MessageName));
payload = event.Payload;
received = double(event.ReceivedUnixSec);

snapshot.revision = snapshot.revision + 1;
snapshot.receivedUnixSec = received;
snapshot.systemId = double(event.SystemID);
snapshot.componentId = double(event.ComponentID);
snapshot.sourceType = string(event.SourceType);

switch name
    case "HEARTBEAT"
        baseMode = readScalar(payload, "base_mode");
        snapshot.data.Armed = bitand(uint8(max(baseMode, 0)), uint8(128)) ~= 0;
        customMode = readScalar(payload, "custom_mode");
        if isfinite(customMode)
            snapshot.data.FlightMode = "PX4 custom mode " + string(customMode);
        end
        snapshot.data.SystemStatus = unknownToNaN( ...
            readScalar(payload, "system_status"), 255);

    case "ATTITUDE"
        snapshot.data.Roll_rad = readScalar(payload, "roll");
        snapshot.data.Pitch_rad = readScalar(payload, "pitch");
        snapshot.data.Yaw_rad = readScalar(payload, "yaw");
        snapshot.data.P_radps = readScalar(payload, "rollspeed");
        snapshot.data.Q_radps = readScalar(payload, "pitchspeed");
        snapshot.data.R_radps = readScalar(payload, "yawspeed");

    case "LOCAL_POSITION_NED"
        snapshot.data.North_m = readScalar(payload, "x");
        snapshot.data.East_m = readScalar(payload, "y");
        snapshot.data.Down_m = readScalar(payload, "z");
        snapshot.data.VNorth_mps = readScalar(payload, "vx");
        snapshot.data.VEast_mps = readScalar(payload, "vy");
        snapshot.data.VDown_mps = readScalar(payload, "vz");
        snapshot.data.X_m = snapshot.data.North_m;
        snapshot.data.Y_m = snapshot.data.East_m;
        snapshot.data.Z_m = -snapshot.data.Down_m;

    case "BATTERY_STATUS"
        voltages = readVector(payload, "voltages");
        voltages = voltages(voltages ~= 65535 & voltages > 0);
        if isempty(voltages)
            snapshot.data.BatteryVoltage_V = NaN;
        else
            snapshot.data.BatteryVoltage_V = sum(voltages) / 1000;
        end
        snapshot.data.BatteryCurrent_A = scaledUnknown( ...
            readScalar(payload, "current_battery"), -1, 100);
        snapshot.data.BatteryRemaining_pct = unknownToNaN( ...
            readScalar(payload, "battery_remaining"), -1);
        snapshot.data.BatteryConsumed_Ah = scaledUnknown( ...
            readScalar(payload, "current_consumed"), -1, 1000);

    case "ACTUATOR_OUTPUT_STATUS"
        values = readVector(payload, "actuator");
        active = readScalar(payload, "active");
        count = min(numel(values), 16);
        for index = 1:count
            isActive = ~isfinite(active) || ...
                bitand(uint32(active), bitshift(uint32(1), index - 1)) ~= 0;
            if isActive
                snapshot.data.(sprintf("Motor%d_output", index)) = ...
                    double(values(index));
            else
                snapshot.data.(sprintf("Motor%d_output", index)) = NaN;
            end
        end

    case "SERVO_OUTPUT_RAW"
        port = readScalar(payload, "port");
        if ~isfinite(port)
            port = 0;
        end
        snapshot.data.MotorOutputPort = port;
        for index = 1:16
            fieldName = sprintf("servo%d_raw", index);
            value = readScalar(payload, fieldName);
            if ~isfinite(value) || value <= 0 || value == 65535
                value = NaN;
            end
            snapshot.data.(sprintf( ...
                "Motor%d_pwm_us", index)) = value;
        end

    case "GPS_RAW_INT"
        snapshot.data.GpsFixType = readScalar(payload, "fix_type");
        snapshot.data.GpsSatellites = unknownToNaN( ...
            readScalar(payload, "satellites_visible"), 255);
        snapshot.data.GpsHdop = scaledUnknown( ...
            readScalar(payload, "eph"), 65535, 100);
        snapshot.data.GpsLatitude_deg = ...
            readScalar(payload, "lat") / 1e7;
        snapshot.data.GpsLongitude_deg = ...
            readScalar(payload, "lon") / 1e7;
        snapshot.data.GpsAltitude_m = ...
            readScalar(payload, "alt") / 1000;

    case "ESC_TELEMETRY_1_TO_4"
        rpm = readVector(payload, "rpm");
        for index = 1:min(numel(rpm), 4)
            snapshot.data.(sprintf("Motor%d_rpm", index)) = ...
                unknownToNaN(double(rpm(index)), 0);
        end

    case "ATTITUDE_TARGET"
        quaternion = readVector(payload, "q");
        if numel(quaternion) >= 4 && all(isfinite(quaternion(1:4)))
            euler = quaternionToEuler(quaternion(1:4));
            snapshot.data.RollTarget_rad = euler(1);
            snapshot.data.PitchTarget_rad = euler(2);
            snapshot.data.YawTarget_rad = euler(3);
        end
        snapshot.data.ThrustTarget = readScalar(payload, "thrust");

    case "WIND_COV"
        snapshot.data.EstimatorWindNorth_mps = ...
            readScalar(payload, "wind_x");
        snapshot.data.EstimatorWindEast_mps = ...
            readScalar(payload, "wind_y");

    otherwise
        return;
end

definitions = vectra.px4.telemetryDefinitions();
matches = false(1, numel(definitions));
for definitionIndex = 1:numel(definitions)
    matches(definitionIndex) = any(string( ...
        definitions(definitionIndex).acceptedMessageNames) == name);
end
match = find(matches, 1, "first");
if isempty(match)
    return;
end

key = definitions(match).key;
channel = snapshot.channels.(key);
previousReceived = channel.lastReceivedUnixSec;
channel.count = channel.count + 1;
channel.messageName = name;
channel.lastReceivedUnixSec = received;
channel.ageSec = 0;
channel.state = "live";
if isfinite(previousReceived) && received > previousReceived
    instantaneousRate = 1 / (received - previousReceived);
    if channel.rateHz == 0
        channel.rateHz = instantaneousRate;
    else
        channel.rateHz = 0.8 * channel.rateHz + ...
            0.2 * instantaneousRate;
    end
end
snapshot.channels.(key) = channel;
end

function value = readScalar(payload, fieldName)
if ~isfield(payload, fieldName)
    value = NaN;
    return;
end
raw = payload.(fieldName);
if isempty(raw)
    value = NaN;
else
    value = double(raw(1));
end
end

function value = readVector(payload, fieldName)
if ~isfield(payload, fieldName) || isempty(payload.(fieldName))
    value = zeros(0, 1);
else
    value = double(payload.(fieldName)(:));
end
end

function value = unknownToNaN(value, sentinel)
if isempty(value) || ~isfinite(value) || value == sentinel
    value = NaN;
end
end

function value = scaledUnknown(value, sentinel, scale)
value = unknownToNaN(value, sentinel);
if isfinite(value)
    value = value / scale;
end
end

function euler = quaternionToEuler(q)
% MAVLink quaternions are ordered [w x y z].
q = double(q(:));
q = q / norm(q);
w = q(1);
x = q(2);
y = q(3);
z = q(4);

roll = atan2(2 * (w * x + y * z), ...
    1 - 2 * (x * x + y * y));
pitchArgument = 2 * (w * y - z * x);
pitch = asin(max(-1, min(1, pitchArgument)));
yaw = atan2(2 * (w * z + x * y), ...
    1 - 2 * (y * y + z * z));
euler = [roll, pitch, yaw];
end
