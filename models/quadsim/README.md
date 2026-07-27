# VECTRA Simulink Models

This directory contains VECTRA-owned model variants. Upstream files must not be
edited in place under `vendor/QuadSim`.

## Baseline copy

`VECTRA_Cant_Quadcopter_Simulation.slx` is an exact copy of the verified
upstream `AC_Quadcopter_Simulation.slx` before cant changes.

SHA-256:

`f893ebd7d75ba55f632504edf83c4b2bcd21d96304eec40d4c1d0edfd70f7341`

The first research model will be derived from the upstream attitude-control
model and will add:

1. motor-specific rotor-axis geometry;
2. three-dimensional force and moment summation;
3. cant-aware control allocation;
4. motor saturation and allocation diagnostics;
5. a versioned model interface consumed by `vectra.quadsim`.

Wind-relative aerodynamic disturbance is intentionally deferred until the
cant-only model passes its minimal verification.

## Rebuild the model

From the VECTRA root in MATLAB:

```matlab
run("startup.m")
vectra.quadsim.setupPaths()
configureCantModel()
```

The script is idempotent and updates only the VECTRA-owned model copy. It
points the State Equations block to `vectraCantDynamicsSFunction`, inserts
`vectraCantAllocatorSFunction` before the original Motor Dynamics subsystem,
and records allocation diagnostics without changing the upstream 24-column
`yout` contract.

Model changes require a baseline comparison against the pinned upstream model
before research sweeps are accepted.

The approved implementation design is documented in
`docs/plans/cant-implementation-plan.md`.
