# Changelog

## 0.1.0 - 2026-07-27

- Initialized the VECTRA research software hierarchy.
- Pinned the upstream QuadSim dependency.
- Added configuration schemas, MATLAB package entry points, test structure,
  data governance rules, and research documentation.
- Verified the project validator, six MATLAB unit tests, and the upstream
  QuadSim attitude-control smoke simulation on MATLAB R2026a.
- Added the VECTRA-owned Cant geometry, three-dimensional rotor wrench,
  generalized rotor gyroscopic moment, reference-wrench allocator, model
  configuration script, diagnostic logging, and zero-/ten-degree validation
  pipeline.
- Corrected the distinction between rotor spin direction and reaction-torque
  direction so zero cant reproduces QuadSim's yaw moment row.
- Passed the final MATLAB R2026a Cant validation: nine unit tests, zero-cant
  upstream regression, symmetric ten-degree physical sanity checks, finite
  simulation output, and no motor-limit exceedance.
- Added the reproducible Cant implementation and validation report in Markdown,
  editable DOCX, and visually verified PDF formats.
- Added the passive PX4 live-telemetry console with hardware and deterministic
  simulated sources, channel freshness/provenance, bounded rolling plots, and
  run-scoped recording controls.
- Added append-only MAVLink JSONL journals, normalized CSV samples, final
  manifests, interrupted-run recovery, and telemetry unit/integration tests.
- Added a hardware prerequisite check and changed the VECTRA listener default
  to `14551` after the connected QGroundControl process was found to own
  `14550`.
- Added the QGroundControl forwarding setup and complete telemetry GUI usage
  guide.
- Replaced the paid UAV Toolbox live-receive dependency with a pinned,
  project-local PyMAVLink bridge while retaining the same passive MATLAB source
  contract, telemetry monitor, GUI, and raw-data formats.
- Added a one-command MATLAB installer, dependency/runtime health reporting,
  and a real MAVLink 2 UDP heartbeat loopback test for the Python bridge.
- Added a `SERVO_OUTPUT_RAW` compatibility path for PX4 builds that do not
  expose `ACTUATOR_OUTPUT_STATUS`, preserving PWM microseconds in snapshots,
  CSV logs, channel provenance, and the unit-aware output chart.
- Prevented QGroundControl's `SYS 255 / COMP 190` GCS heartbeat from winning
  the telemetry source-lock race; VECTRA now waits for a PX4 autopilot
  heartbeat before accepting a vehicle system ID.
