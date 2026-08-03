# SERVO_OUTPUT_RAW Motor-Output Fallback Plan

Status: approved and implemented on 2026-07-28

## Root cause

The connected PX4 firmware streams `SERVO_OUTPUT_RAW` but does not expose
`ACTUATOR_OUTPUT_STATUS` in its MAVLink stream list. VECTRA currently monitors
only `ACTUATOR_OUTPUT_STATUS`, so the motor-output channel remains waiting and
the bars retain their initial values.

## Implementation

1. Accept `SERVO_OUTPUT_RAW` as the physical-output source when normalized
   actuator status is unavailable.
2. Preserve raw PWM values in microseconds. Do not silently assume a universal
   1000–2000 µs normalization range.
3. Add explicit `MotorN_pwm_us` snapshot and logger columns while retaining the
   existing normalized `MotorN_output` fields for sources that provide them.
4. Keep the output chart fixed to PWM microseconds from `SERVO_OUTPUT_RAW`.
   Normalized actuator values remain log-only and never change chart units.
5. Report the actual active MAVLink source and units in channel quality and
   recorded metadata.
6. Keep the implementation receive-only; no stream or parameter command will
   be sent from VECTRA.

## Verification

- Unit-test `SERVO_OUTPUT_RAW` parsing, sentinel handling, and first-four-output
  ordering.
- Verify disarmed 1000 µs outputs display as 1000 µs, not zero or NaN.
- Preserve existing normalized actuator tests and simulated-source behavior.
- Verify logger columns and manifest provenance.
- Run MATLAB Code Analyzer, Python bridge tests, JSON checks, diff checks, and
  sensitive-device scans.

## Safety boundary

Motor/output mapping must be confirmed against the PX4 actuator assignment.
Testing physical output movement must be performed disarmed through the
approved actuator-test procedure with propellers removed.
