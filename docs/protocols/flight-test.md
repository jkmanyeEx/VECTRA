# Flight-test protocol

## Qualification sequence

1. Validate the unmodified QuadSim baseline.
2. Validate the zero-degree VECTRA model against the upstream baseline.
3. Exercise the experiment in PX4 software-in-the-loop.
4. Exercise the controller and logging path in hardware-in-the-loop.
5. Verify actuator ordering with propellers removed.
6. Perform a restricted zero-degree hover test.
7. Repeat the qualified protocol for each mechanical geometry.
8. Introduce wind conditions only after still-air qualification.

## Run sequence

1. Resolve vehicle, geometry, experiment, and software versions.
2. Create the immutable raw run directory.
3. Complete the preflight checklist.
4. Start external sensor recording.
5. Start PX4 logging and confirm the run marker.
6. Execute takeoff, settle, measurement, landing, and disarm phases.
7. Record operator notes and deviations.
8. Copy original logs into the run directory.
9. Verify file integrity before processing.
10. Normalize, quality-check, analyze, and report.

## Abort conditions

Abort the test when manual override is unavailable, position estimation is
invalid, battery state is unsafe, communication is unreliable, actuator
saturation is sustained, the aircraft exits the test boundary, or the operator
observes unexpected behavior.
