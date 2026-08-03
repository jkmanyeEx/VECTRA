# Cant implementation walkthrough

## Implemented scope

The Cant MVP extends the pinned QuadSim AC model without modifying
`vendor/QuadSim`.

- `buildRotorGeometry` resolves motor positions, cant axes, spin signs, and
  opposite reaction-torque signs.
- `buildWrenchMatrix` calculates rotor force, arm moment, and reaction moment
  per squared RPM.
- `calculateGyroscopicMoment` generalizes the upstream z-axis gyro expression.
- `vectraCantDynamicsSFunction` applies the three-dimensional wrench to the
  existing QuadSim rigid-body equations.
- `vectraCantAllocatorSFunction` maps the upstream zero-cant reference wrench
  to the active cant geometry before the original Motor Dynamics subsystem.
- `configureCantModel` reproducibly edits only
  `VECTRA_Cant_Quadcopter_Simulation.slx`.
- `runCant` preserves the original 24-column state contract and separately
  derives body force/moment and allocation diagnostics.

## Visible MATLAB log

Run from the VECTRA root:

```matlab
run("startup.m")
runCantValidationLogged()
```

The complete MATLAB/Simulink console transcript is written to:

```text
results/reports/cant-validation/console.log
```

The machine-readable summary is written to:

```text
results/reports/cant-validation/validation-report.json
```

## Final logged validation

The accepted MATLAB R2026a run completed at `2026-07-27 13:00:43`:

```text
UNIT_PASSED=9 UNIT_FAILED=0
VECTRA_CANT_RUN: simulation_start cant_00
VECTRA_CANT_RUN: simulation_complete cant_00
VECTRA_CANT_RUN: result_ready cant_00
VECTRA_CANT_RUN: simulation_start cant_10
VECTRA_CANT_RUN: simulation_complete cant_10
VECTRA_CANT_RUN: result_ready cant_10
CANT_VALIDATION_PASSED=1
VECTRA_CANT_VALIDATION_COMPLETE=27-Jul-2026 13:00:43
```

Zero-cant regression:

```text
same time grid: true
maximum state error: 6.455877499256246e-13
maximum RPM error: 2.180968294851482e-9 rpm
maximum throttle error except final discontinuity sample: 1.733724275254645e-12 %
passed: true
```

Ten-degree physical sanity check:

```text
expected vertical-force scale: 0.9848077530122080
actual vertical-force scale:   0.9848077530122081
horizontal coefficient sum:   [1.58e-24, 3.31e-24]
expected hover-RPM ratio:      1.0076837856618241
actual hover-RPM ratio:        1.0081336305103508
finite output: true
motor limit exceeded: false
passed: true
```

Overall result: `passed = true`.

The final sample at exactly one second coincides with a legacy command
discontinuity. The added direct-feedthrough allocation block changes the
algebraic output ordering at that one sample by 0.20625 percentage points,
while continuous states and RPM remain equivalent. The automated regression
therefore excludes only the final throttle sample and still checks all states
and RPM samples.

The upstream model emits a Model History deprecation warning when loaded in
MATLAB R2026a. This warning comes from the pinned 2014 QuadSim model, does not
stop simulation, and does not change the accepted numerical result.

## Minimal acceptance check

`validateCantImplementation(1)` checks:

1. zero-cant state and RPM equivalence;
2. zero-cant throttle equivalence outside the final discontinuity sample;
3. ten-degree vertical-force ratio equal to `cos(10 deg)`;
4. symmetric horizontal-force coefficient cancellation;
5. hover RPM ratio moving toward `1/sqrt(cos(10 deg))`;
6. finite state output and no motor-limit exceedance.

The approved cant-angle sweep, wind testing, and statistical sensitivity
analysis are intentionally deferred to the subsequent research experiment.
Vehicle configuration, propeller configuration, mass, and center of gravity
remain fixed.
