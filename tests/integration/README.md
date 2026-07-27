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

`TestTelemetryLoopback.m` verifies that the passive source receives a real
PyMAVLink-encoded MAVLink 2 heartbeat from a local UDP sender. When the project
Python dependency is absent, it verifies the explicit
`vectra:px4:MissingPyMavlink` error. Python tests independently verify the
bridge protocol, checksum-aware UDP decode, and absence of send calls.

Real aircraft commands must never run as part of an unattended automated test.
