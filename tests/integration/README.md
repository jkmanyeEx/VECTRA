# Integration tests

Integration tests cover external boundaries and are kept separate from unit
tests because they require licensed products, hardware, or recorded fixtures.

Required integration suites:

- upstream QuadSim baseline execution on the supported MATLAB release;
- VECTRA cant model regression against the zero-degree baseline;
- PX4 ULog import using a non-sensitive fixture;
- external wind log synchronization;
- SITL command and abort-state behavior;
- HITL telemetry and logging with propellers removed.

Real aircraft commands must never run as part of an unattended automated test.
