# PX4 Heartbeat Source-Lock Fix Plan

Status: approved and implemented on 2026-07-28

## Root cause

`TelemetryMonitor` locks to the system ID of the first `HEARTBEAT` received.
It does not validate the heartbeat's MAVLink vehicle type or autopilot field.
When QGroundControl's GCS heartbeat reaches the forwarded UDP listener before
the aircraft heartbeat, VECTRA locks to the QGC system ID and then rejects the
PX4 aircraft's attitude, position, battery, actuator, GPS, target, and wind
messages as foreign-system traffic. The table therefore shows a live heartbeat
while every aircraft channel remains `waiting`.

The behavior is intermittent because it depends on which heartbeat arrives
first after the listener starts.

## Implementation

1. Require a vehicle/autopilot heartbeat before establishing the system lock.
   Reject GCS, antenna-tracker, and invalid-autopilot heartbeats as lock
   candidates.
2. Keep the receiver passive. Do not send heartbeat, stream-rate, parameter, or
   command messages.
3. Continue accepting messages from all components that share the locked PX4
   vehicle system ID.
4. Count pre-lock non-vehicle heartbeats separately from post-lock foreign
   system messages so diagnostics explain why VECTRA is still waiting.
5. Preserve simulated-source behavior by emitting a valid simulated vehicle
   heartbeat or explicitly identifying simulated events as a valid lock source.

## Verification

- Unit-test a QGC/GCS heartbeat arriving before the PX4 heartbeat.
- Verify the GCS heartbeat does not establish the lock.
- Verify the following PX4 heartbeat establishes the lock and subsequent
  attitude, position, and battery messages become live.
- Verify post-lock messages from a different system remain rejected.
- Run the existing telemetry unit and integration tests, MATLAB Code Analyzer,
  Python bridge tests, JSON validation, and diff checks.
- Perform a live disarmed check with QGroundControl forwarding enabled and
  confirm repeated listener reconnects always lock to the aircraft system.

Automated verification completed on 2026-07-28:

- 12 focused MATLAB telemetry monitor/logger tests passed, including the
  QGC-first heartbeat regression.
- The MATLAB-to-PyMAVLink UDP integration test passed.
- All 3 Python bridge tests passed, including the real MAVLink heartbeat
  loopback and receive-only API guard.
- `validateProject()` reported the project valid.
- MATLAB Code Analyzer reported no findings in the changed monitor and tests.
- Repository diff checks passed.

The repeated live disarmed reconnect check remains an operator verification
because it requires the connected QGroundControl/PX4 hardware.

## Safety boundary

This remains a receive-only monitoring correction. It does not arm the vehicle,
change parameters, request streams, or control actuators. Any physical check
must be performed disarmed; propellers are not required for this verification
and should remain removed.
