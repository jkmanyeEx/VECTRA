# VECTRA Engineering Rules

## Safety and evidence

- Treat PX4 as the owner of stabilization, state estimation, arming, actuator
  output, and failsafes.
- Never issue real-aircraft commands from unattended tests.
- Require explicit operator confirmation and manual override before a live test.
- Preserve `data/raw` as immutable evidence.
- Save a resolved configuration snapshot for every simulation or flight run.

## Dependency boundaries

- Do not edit `vendor/QuadSim`.
- Create VECTRA-owned Simulink variants under `models/quadsim`.
- Access upstream paths through `vectra.quadsim.paths`.
- Keep GUI code free of simulation, parsing, hardware, and metric logic.

## Data conventions

- Use SI units in normalized data.
- Document every coordinate-frame conversion.
- Keep nominal and measured cant angles separate.
- Do not present uncalibrated example parameters as measurements.
- Associate derived outputs with the raw run ID and processing version.

## Verification

- Run `validateProject` and `tests/runAllTests.m` after MATLAB changes.
- Compare the zero-cant VECTRA model with the pinned upstream baseline.
- Use SITL and HITL before any real flight.
- Scan changes for secrets and sensitive device information before committing.
