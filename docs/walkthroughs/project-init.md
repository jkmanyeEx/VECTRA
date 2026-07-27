# Project initialization walkthrough

## MATLAB session

1. Open MATLAB with `VECTRA` as the current folder.
2. Run `startup.m`.
3. Run `vectra.environment()` to inspect required and optional products.
4. Run `validateProject()` to verify the local hierarchy and dependency.
5. Run `tests/runAllTests.m` before changing shared code.

## Configuration

1. Copy or revise the vehicle profile only after measurements are available.
2. Add one geometry profile for each physical cant configuration.
3. Add a versioned experiment profile.
4. Resolve the run before simulation or log collection.
5. Preserve the resolved configuration beside raw evidence.

## Dependency baseline

Run `scripts/runSmokeSimulation.m` before modifying any Simulink model. The
result establishes whether the pinned upstream model is compatible with the
current MATLAB release.

## Verified initialization result

On 2026-07-27, MATLAB R2026a reported:

- project validation: passed;
- unit tests: 6 passed, 0 failed, 0 incomplete;
- upstream attitude-control smoke run: 183 samples by 24 output variables;
- upstream compatibility warning: Model History is deprecated and may be
  removed in a future Simulink release.
