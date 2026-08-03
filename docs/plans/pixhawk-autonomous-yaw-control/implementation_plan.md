# Pixhawk Autonomous Yaw Control — Implementation Plan

Status: awaiting operator approval

## Objective

Add a narrowly scoped, repeatable PX4 Offboard maneuver to VECTRA: while the
aircraft is already hovering under a qualified operator, hold its captured
local NED position and command a relative yaw step such as `+15 deg`. PX4 keeps
state estimation, attitude/rate control, motor allocation, arming, and
failsafes.

This first control release will not arm, take off, land, write parameters,
upload missions, or send raw motor/actuator commands.

## Root cause and connection architecture

The current VECTRA bridge is intentionally receive-only and consumes
QGroundControl's UDP forwarding stream. QGroundControl forwarding cannot carry
VECTRA commands back to the vehicle: its documented forwarding direction is
one-way and packets received from the forwarding destination are ignored.

Therefore the passive listener cannot safely be made bidirectional by merely
adding a send call. The control path will use a separate, explicit **Direct
Pixhawk** source that owns the serial MAVLink connection. Passive QGC-forwarded
telemetry remains available and unchanged for observation-only work.

For a direct-control run, QGroundControl must release the Pixhawk serial port.
The RC transmitter remains connected and is the required manual override.

## Operator workflow

1. Qualify the maneuver in simulated mode, then PX4 SITL, then HITL.
2. On hardware, verify RC mode override and the PX4 Offboard-loss action.
3. Close or disconnect QGroundControl from the Pixhawk serial link.
4. In VECTRA select **Direct Pixhawk**, choose the detected serial device and
   baud rate, then connect.
5. Manually arm, take off, and establish a stable hover in Position mode.
6. Start VECTRA recording.
7. Enter `15` and choose **RUN RELATIVE YAW**.
8. Confirm the safety checklist. VECTRA captures the current north/east/down
   position and yaw, streams that hold setpoint for more than one second,
   confirms Offboard mode, then changes only the yaw target by `+15 deg`.
9. Use **EXIT TO POSITION** or the RC mode switch to end external control.

In the PX4 NED heading convention, positive yaw turns clockwise when viewed
from above: `+15 deg` turns right by 15 degrees from the captured heading;
`-15 deg` turns left. The absolute target is wrapped at +/-180 degrees.

## Control state machine

```text
DISABLED
  -> PREFLIGHT_GATE
  -> PRIMING_HOLD (10 Hz setpoints for >= 1 s)
  -> OFFBOARD_REQUESTED
  -> HOLDING_INITIAL_YAW
  -> YAW_STEP_ACTIVE
  -> EXITING_TO_POSITION
  -> DISABLED

Any rejected gate, stale required channel, lost serial process, rejected mode,
or operator abort transitions to EXITING_TO_POSITION when the link is usable.
If the link is lost, PX4's configured Offboard-loss failsafe owns recovery.
```

The setpoint will be `SET_POSITION_TARGET_LOCAL_NED` in
`MAV_FRAME_LOCAL_NED`, using captured `x/y/z` and a yaw angle. Velocity,
acceleration, and yaw-rate fields are ignored. Setpoints are streamed at 10 Hz,
above PX4's required 2 Hz proof-of-life threshold.

## Safety gates

The control button remains disabled unless all machine-verifiable gates pass:

- a direct physical Pixhawk link is selected (never QGC-forwarded telemetry);
- VECTRA is locked to a PX4 vehicle heartbeat;
- heartbeat, attitude, and local position are live and finite;
- the vehicle reports armed and the direct-link process is healthy;
- recording is active, so every command belongs to a raw run ID.

The confirmation dialog additionally requires the operator to attest that:

- propellers are installed only in an approved flight area;
- the RC mode override has just been tested and remains available;
- `COM_OF_LOSS_T` and `COM_OBL_RC_ACT` were checked in QGroundControl;
- position estimation and battery state are safe;
- the vehicle is already in a stable hover with adequate clearance.

The first hardware validation is props-off. Automated tests never send commands
to a real aircraft.

## Planned implementation

### MAVLink bridge

- Extend the Python bridge with mutually exclusive passive-UDP and direct-serial
  transports.
- Add a strict NDJSON request/response protocol over stdin/stdout for only:
  `prepare_offboard_hold`, `set_relative_yaw`, `exit_to_position`, and
  `abort_control`.
- Stream the captured position/yaw hold at 10 Hz, request PX4 Offboard mode only
  after priming, and confirm mode transitions from vehicle heartbeat state.
- Reject malformed, out-of-range, stale, wrong-system, or wrong-state requests.
- Never expose generic `COMMAND_LONG`, parameter-write, arming, actuator, or
  arbitrary-message APIs to the MATLAB UI.

### MATLAB control boundary

- Extend `LiveTelemetrySource` for serial selection and bridge requests without
  putting protocol logic in the GUI.
- Add a VECTRA-owned `OffboardYawController` state machine that evaluates
  flight-authority gates, captures the hold point, normalizes relative yaw, and
  handles timeout/abort transitions.
- Decode PX4 main/sub-mode from `HEARTBEAT.custom_mode` so the UI confirms the
  actual mode rather than treating a sent request as success.

### Operator console

- Preserve the existing passive telemetry and fixed raw-PWM chart.
- Add source choices for passive QGC forwarding, direct Pixhawk control, and
  simulated data; show serial-device/baud controls only for direct mode.
- Add a compact control card with relative yaw input, current/target heading,
  controller state, **RUN RELATIVE YAW**, and **EXIT TO POSITION**.
- Make control status unmistakable in the header and event log; no hidden
  auto-arm or automatic takeoff behavior.

### Experiment evidence

- Add a `yaw_step_15` experiment profile with explicit settle/hold timing and
  relative-yaw semantics.
- Write an append-only `control_events.jsonl` beside telemetry evidence,
  including requested/sent/acknowledged mode transitions, captured hold point,
  yaw target, timestamps, state changes, and abort reason.
- Include the control profile and final control summary in
  `resolved_config.json` and `telemetry_manifest.json`.

### Documentation

- Split the usage guide into passive-monitor and direct-control workflows.
- Document the exact `+15 deg` procedure, yaw sign convention, QGC serial-port
  conflict, RC override, Offboard-loss behavior, SITL/HITL sequence, and abort
  procedure.
- Add `walkthrough.md` with simulated-mode screenshots showing the control card,
  confirmation gate, active yaw step, and clean exit.

## Verification

1. Python unit tests with fake MAVLink connections for setpoint masks/frames,
   10 Hz streaming, one-second priming, yaw wrapping, target-system locking,
   mode confirmation, input rejection, timeout, and abort behavior.
2. MATLAB unit tests for gate evaluation, PX4 mode decoding, controller state
   transitions, run-linked control journaling, and simulated yaw response.
3. UI smoke test in hidden/simulated mode; visual walkthrough screenshots.
4. `validateProject`, `tests/runAllTests.m`, Python tests, JSON/schema checks,
   `git diff --check`, and credential/device-identifier scan.
5. Manual acceptance order: simulated -> SITL -> HITL -> props-off hardware.
   No powered real-flight command is part of unattended verification.

## Expected file scope

- `apps/VectraTelemetryApp.m`
- `scripts/launchTelemetryApp.m`
- `scripts/telemetry/pymavlink_bridge.py`
- `src/matlab/+vectra/+px4/LiveTelemetrySource.m`
- new PX4 control/state helpers under `src/matlab/+vectra/+px4/`
- `src/matlab/+vectra/+data/LiveTelemetryLogger.m`
- telemetry/experiment profiles and schemas
- focused Python/MATLAB tests
- README, usage guide, data dictionary, changelog, and walkthrough

Existing uncommitted cant-model, heartbeat-lock, PWM, report, and documentation
work will be preserved. Overlapping files will be edited additively and reviewed
as combined diffs; `vendor/QuadSim` and prior raw data remain untouched.
