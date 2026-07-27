# Cant-Angle Implementation Plan

Status: completed and validated on MATLAB R2026a on 2026-07-27

## Approved MVP scope

This implementation proves that the cant model follows the intended physics
without duplicating the later multi-factor research experiment. The required
verification is intentionally limited to:

1. zero-cant equivalence with the pinned upstream model;
2. per-motor force and moment sign checks;
3. a representative symmetric radial-outward 10-degree case;
4. the expected vertical-force loss and hover-RPM increase;
5. finite execution with visible allocation limits and saved configuration.

Full angle sweeps, mass variation, propeller variation, disk-loading analysis,
wind, and statistical sensitivity analysis belong to the subsequent research
experiment.

## 1. Objective

Extend the verified QuadSim attitude-control baseline so each rotor can have an
independent three-dimensional thrust axis. The implementation must:

- represent radial, tangential, inward, outward, and custom cant geometry;
- calculate force, arm moment, reaction torque, and rotor gyroscopic torque
  from the actual rotor axes;
- preserve the upstream zero-degree response within numerical tolerance;
- keep the upstream QuadSim submodule unchanged;
- expose allocation feasibility and actuator saturation as research evidence;
- remain callable through the VECTRA configuration and run pipeline.

The validated source model was initially copied to:

`models/quadsim/VECTRA_Cant_Quadcopter_Simulation.slx`

Before VECTRA edits, the source and copy shared SHA-256:

`f893ebd7d75ba55f632504edf83c4b2bcd21d96304eec40d4c1d0edfd70f7341`

The VECTRA copy now differs by design. The pinned source remains unchanged.

## 2. Evidence from the current model

The upstream model currently assumes:

- fixed `+` or `X` sign-based throttle mixing;
- all rotor thrust is aligned with positive body `z`;
- total force is `[0; 0; sum(CT * RPM^2)]`;
- rotor moments use the fixed `quadModel.dctcq` matrix;
- gyroscopic torque assumes every rotor axis is body `z`;
- external disturbances are a separate six-component input;
- motor commands are converted to RPM through `quadModel.cr`,
  `quadModel.b`, `quadModel.minThr`, and a first-order motor model.

The baseline `quadModel_+` moment matrix is:

```text
1.0e-7 *
    0        0.3304    0       -0.3304
   -0.3304   0         0.3304   0
   -0.0293   0.0293   -0.0293   0.0293
```

Therefore, changing only the vertical thrust by `cos(cantAngle)` would omit
horizontal force, arm moments, tilted reaction torque, tilted gyroscopic torque,
and the changed control effectiveness.

## 3. Coordinate and sign conventions

- Body axes follow the upstream QuadSim convention.
- Each motor has a body-frame position vector `r_i`.
- Each rotor has a body-frame unit thrust vector `u_i`.
- `rotorSpinSign_i` is `+1` for the upstream motor 1/3 convention and
  `-1` for motor 2/4.
- `reactionTorqueSign_i` is the opposite of `rotorSpinSign_i`. QuadSim's
  zero-cant yaw row is `[-CQ, +CQ, -CQ, +CQ]`.
- Positive radial-outward cant tilts `u_i` from body `+z` toward the motor's
  horizontal radial direction.
- Nominal and measured cant angles remain separate.
- All geometry and force calculations use SI units and radians internally.

Geometry creation must be explicit and testable. No motor order or sign may be
inferred solely from a drawing or GUI label.

## 4. Physical model

For motor `i`:

```text
T_i = CT_i * RPM_i^2
F_i = T_i * u_i
M_arm_i = r_i x F_i
M_reaction_i = reactionTorqueSign_i * CQ_i * RPM_i^2 * u_i
```

Total body force and propulsive moment:

```text
F_body = sum(F_i)
M_prop = sum(M_arm_i + M_reaction_i)
```

Generalized rotor gyroscopic torque:

```text
H_rotor = sum(rotorSpinSign_i * Jm_i * RPM_i * 2*pi/60 * u_i)
M_gyro = -omega_body x H_rotor
```

The state equations remain unchanged after `F_body` and total moment are
calculated. Rotor acceleration reaction torque, blade flapping, rotor wake
interaction, and frame drag are not added in this change because they require
separate evidence and validation.

## 5. Cant-aware control allocation

### 5.1 Effectiveness matrix

Use the existing VECTRA wrench convention:

```text
B = [Fx; Fy; Fz; Mx; My; Mz] per RPM^2
```

The active hover-control matrix is:

```text
B4 = B([Fz, Mx, My, Mz], :)
```

Every configuration must have `rank(B4) == 4`. Singular values and a
row-scaled condition number are recorded. Rank-deficient geometry is rejected.
No flight-safety threshold is inferred from the condition number in this MVP.

### 5.2 Preserve the existing controller

The current attitude and altitude PID blocks remain unchanged in the first cant
implementation. The existing `+`/`X` mixer remains as the zero-degree reference
and produces reference motor commands `m_ref`.

The cant allocator performs:

1. Apply the existing throttle-to-RPM model to `m_ref`.
2. Convert reference RPM to squared speeds `q_ref`.
3. Calculate the desired zero-degree wrench:
   `w_des = B4_zero * q_ref`.
4. Solve the full-rank canted allocation:
   `q_requested = B4_cant \ w_des`.
5. Convert nonnegative `q_cant` back to throttle commands.
6. Pass commands through the existing motor saturation, cutoff, and dynamics.
7. Log negative-squared-speed demand, bounds violation, achieved wrench, and
   allocation residual.

At zero cant, `B4_cant == B4_zero`, so the allocator must reduce to the existing
motor commands within numerical tolerance.

If allocation requires negative squared speed or throttle above the existing
0--100 percent motor limit, the run is marked infeasible. The downstream
QuadSim saturation remains active, but requested and achieved values must not
be conflated. A bound-optimizing allocator is deferred until later experiments
actually require operation at actuator limits.

## 6. Configuration changes

Extend geometry configuration with:

- motor body-frame positions;
- motor horizontal azimuths;
- nominal and measured motor cant angles;
- cant direction or custom rotor-axis vectors;
- spin directions;
- geometry revision;
- measurement uncertainty.

Extend the resolved `quadModel` with:

```text
modelVersion
motorPositionsBodyM
rotorAxesBody
rotorSpinSigns
reactionTorqueSigns
ctPerMotor
cqPerMotor
jmPerMotor
wrenchMatrix
activeControlMatrix
allocationConditionNumber
```

For the first regression run, the adapter overlays zero-degree geometry on the
verified upstream `quadModel_+`. Measured VECTRA vehicle parameters remain
blocked until the vehicle profile is calibrated.

## 7. Implemented files

### New MATLAB functions

- `src/matlab/+vectra/+quadsim/buildRotorGeometry.m`
- `src/matlab/+vectra/+quadsim/extendQuadModel.m`
- `src/matlab/+vectra/+quadsim/buildControlAllocation.m`
- `src/matlab/+vectra/+quadsim/allocateMotorCommands.m`
- `src/matlab/+vectra/+quadsim/validateCantConfiguration.m`
- `src/matlab/+vectra/+quadsim/calculateGyroscopicMoment.m`
- `src/matlab/+vectra/+quadsim/throttleToTargetRpm.m`
- `src/matlab/+vectra/+quadsim/targetRpmToThrottle.m`
- `src/matlab/+vectra/+quadsim/runCant.m`

### New model-owned functions

- `models/quadsim/functions/vectraCantDynamicsSFunction.m`
- `models/quadsim/functions/vectraCantAllocatorSFunction.m`

### Modified VECTRA files

- `models/quadsim/VECTRA_Cant_Quadcopter_Simulation.slx`
- `config/schemas/geometry.schema.json`
- `config/geometries/cant_00.json`
- `config/geometries/cant_10.json`
- `src/matlab/+vectra/+quadsim/paths.m`
- `src/matlab/+vectra/+quadsim/setupPaths.m`
- `src/matlab/+vectra/+quadsim/normalizeOutput.m`
- `docs/data-dictionary/README.md`
- `scripts/validateCantImplementation.m`
- `scripts/runCantValidationLogged.m`

### Reproducible model-edit script

- `models/quadsim/scripts/configureCantModel.m`

The edit script records block paths and parameter changes so the binary
Simulink modification is auditable and can be reapplied to a fresh baseline.

## 8. Implementation sequence

### Phase A - Geometry and pure math

1. Extend the geometry schema.
2. Build motor positions and rotor axes from configuration.
3. Validate unit axes, motor order, spin signs, and symmetry.
4. Build `B`, `B4`, rank, and condition number.
5. Add unit tests before changing the Simulink model.

### Phase B - Cant dynamics

1. Copy the upstream S-function into the VECTRA model area under a new name.
2. Replace fixed `dctcq` and vertical-only force calculations.
3. Generalize gyroscopic torque.
4. Point only the VECTRA model's State Equations block to the new function.
5. Verify zero-degree open-loop force and moment equivalence.

### Phase C - Control allocation

1. Preserve the existing mixer as the zero-degree reference.
2. Add the cant allocation subsystem between the mixer and Motor Dynamics.
3. Add feasibility, saturation, and residual signals.
4. Confirm roll, pitch, yaw, and altitude pulse signs independently.
5. Confirm zero-degree closed-loop equivalence.

### Phase D - Pipeline and logging

1. Add `runCant` using `Simulink.SimulationInput`.
2. Save resolved geometry and model version with each result.
3. Add force, moment, allocation, and feasibility channels.
4. Normalize the added signals without changing the existing 24-column
   baseline contract.

### Phase E - Research validation

1. Run still-air hover at zero cant.
2. Run symmetric radial-outward configurations at approved angles.
3. Confirm predicted vertical-thrust loss and hover-RPM increase.
4. Confirm equal-RPM horizontal force cancellation.
5. Confirm no unexplained steady roll, pitch, or yaw moment.
6. Introduce wind only after the cant-only model passes.

## 9. Verification matrix

### Unit tests

- Every rotor axis has unit norm.
- Zero cant produces `[0; 0; 1]` for every rotor.
- Every zero-degree moment column matches `quadModel.dctcq`, including the
  reaction-torque sign.
- Equal RPM at symmetric radial cant cancels horizontal force.
- Vertical force equals `sum(CT_i * RPM_i^2 * cos(theta_i))`.
- Equal RPM produces the analytically expected net moment.
- Generalized gyro torque matches the upstream formula at zero cant.
- Allocation has rank four for qualified configurations.
- Zero-degree allocation returns the reference motor commands.
- Infeasible negative or over-speed demand is reported.

### MVP integration tests

- Upstream baseline remains `183 x 24` for the smoke profile.
- Zero-cant VECTRA states match upstream with absolute tolerance `1e-8` and
  relative tolerance `1e-7`.
- Zero-cant RPM and throttle traces match with absolute tolerance `1e-6`.
- The representative ten-degree run completes with finite output.
- The ten-degree run follows the predicted vertical-force and hover-RPM
  direction without exceeding the configured motor limit.
- The raw upstream submodule remains clean.

Independent roll, pitch, yaw, and altitude pulse campaigns and repeated-run
statistics are deferred to the later multi-factor experiment so they do not
duplicate that experiment.

### Physical sanity checks

- Required equal-motor hover RPM follows the `1/sqrt(cos(theta))` trend for a
  symmetric radial cant under the simplified thrust model.
- Hover feasibility fails when required RPM exceeds configured maximum RPM.
- Increased cant does not create net horizontal force at equal RPM for a
  symmetric radial geometry.
- A run with allocation saturation is labeled and excluded from unconstrained
  comparisons.

## 10. Acceptance criteria

The approved Cant MVP is complete only when:

- the VECTRA model never modifies upstream QuadSim files;
- the zero-degree simulation meets the trace tolerances above;
- force and moment calculations use motor-specific three-dimensional axes;
- the generalized gyro term passes its zero-degree regression;
- the allocator preserves the existing zero-degree mixer response;
- infeasible allocation and saturation are visible in saved results;
- all approved geometry, math, dynamics, allocation, and pipeline checks pass;
- documentation states the model limitations and coordinate conventions;
- the active MATLAB session successfully runs the cant smoke test.

## 11. Explicitly deferred work

- calibrated wind-drag and gust modeling;
- battery voltage sag and energy consumption modeling;
- blade flapping and rotor-to-rotor aerodynamic interaction;
- PX4 control-allocation deployment;
- bound-optimizing allocation at actuator limits;
- full cant-angle, mass, propeller, and disk-loading sweeps;
- App Designer GUI implementation;
- real-flight authorization.

These remain separate changes so cant geometry can be validated without
confounding model effects.

## 12. Completion record

The logged MATLAB R2026a run completed at `2026-07-27 13:00:43` with nine unit
tests passed and no unit-test failures.

Zero-cant regression:

```text
same time grid: true
maximum state error: 6.455877499256246e-13
maximum RPM error: 2.180968294851482e-9 rpm
maximum throttle error except final discontinuity sample: 1.733724275254645e-12 %
passed: true
```

Symmetric radial-outward ten-degree check:

```text
expected vertical-force scale: 0.9848077530122080
actual vertical-force scale:   0.9848077530122081
expected hover-RPM ratio:      1.0076837856618241
actual hover-RPM ratio:        1.0081336305103508
finite output: true
motor limit exceeded: false
passed: true
```

Overall result: `passed = true`.
