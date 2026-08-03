# Apply Tangential Cant for Yaw Authority

Status: approved, implemented, and verified on 2026-07-28

## Objective

Replace the active radial-outward 10-degree research case with a tangential
cant geometry that increases yaw control effectiveness while preserving a
zero-yaw equal-thrust hover condition.

The cant magnitude keeps the agreed definition:

- `0 deg`: rotor thrust axis is parallel to body `+Z`;
- `90 deg`: rotor thrust axis is horizontal and tangential;
- positive/negative motor angles select the two opposite local tangential
  directions.

## Root cause

The geometry engine already implements a local tangential unit direction:

```text
e_t,i = [-sin(azimuth_i), cos(azimuth_i), 0]
u_i   = sin(theta_i) e_t,i + cos(theta_i) body_Z
```

However, the active `cant_10` profile still declares `radial-outward`, and the
current unit/integration validation only checks radial horizontal-force
cancellation and vertical-force loss. It does not verify tangential yaw
effectiveness or hover yaw balance.

For a motor at radius `d`, tangential cant adds this arm-generated yaw term:

```text
Mz_arm,i = d * CT_i * sin(theta_i) * rpm_i^2
```

The reaction-torque term remains:

```text
Mz_reaction,i = reactionTorqueSign_i * CQ_i
                * cos(theta_i) * rpm_i^2
```

If all four `theta_i` values have the same sign, equal hover thrust produces a
nonzero net yaw moment. The allocator must continuously oppose that bias and
may require negative or saturated motor demand.

## Geometry decision

Use alternating signed tangential cant aligned with the existing reaction
torque signs:

| Motor | Position | Reaction-torque sign | Tangential cant |
|---|---:|---:|---:|
| M1 | `+X` | `-1` | `-10 deg` |
| M2 | `+Y` | `+1` | `+10 deg` |
| M3 | `-X` | `-1` | `-10 deg` |
| M4 | `-Y` | `+1` | `+10 deg` |

This makes the tangential arm moment reinforce each motor's existing yaw
reaction-torque direction. With equal motor commands, the two positive and two
negative yaw contributions cancel. Differential motor commands then receive
greater yaw effectiveness.

The scalar `nominalCantAngleDeg` remains `10` as the physical cant magnitude;
`motorCantAnglesDeg` records the signed per-motor directions.

## Implementation scope

1. Add an explicit tangential geometry profile rather than rewriting the
   historical radial profile:
   - `config/geometries/cant_tangential_10.json`
   - geometry ID: `alternating-tangential-cant-10`
   - cant type: `tangential`
   - signed motor angles: `[-10, 10, -10, 10]`
2. Keep `cant_00` as the zero-degree upstream regression profile because
   radial and tangential directions are identical at zero cant.
3. Update the active validation entry point to use the tangential 10-degree
   profile while retaining the zero-cant upstream regression.
4. Replace radial-only assertions with tangential yaw assertions:
   - every rotor axis is unit length;
   - equal-command total horizontal force is zero;
   - equal-command total roll, pitch, and yaw moment is zero;
   - vertical force scale is `cos(10 deg)`;
   - each motor's yaw coefficient has the expected alternating sign;
   - tangential yaw coefficient magnitude exceeds the corresponding zero-cant
     reaction-torque magnitude;
   - the active `[Fz, Mx, My, Mz]` allocation remains rank four;
   - the hover run is finite, allocation-feasible, and below motor limits.
5. Add focused unit coverage in `tests/unit/TestQuadSimMath.m` for the signed
   tangential rotor axes and analytical yaw row.
6. Record the resolved `cantType` on the extended QuadSim model so run outputs
   expose the selected geometry convention directly.
7. Add a focused tangential-cant walkthrough with the equations, motor sign
   pattern, and verified results. Preserve the existing radial validation
   report as historical evidence instead of silently relabeling it.

## Files expected to change

- `config/geometries/cant_tangential_10.json` (new)
- `src/matlab/+vectra/+quadsim/extendQuadModel.m`
- `scripts/validateProject.m`
- `scripts/validateCantImplementation.m`
- `tests/unit/TestConfiguration.m`
- `tests/unit/TestQuadSimMath.m`
- `docs/walkthroughs/tangential-cant.md` (new)

The currently modified radial report files and disk-loading-removal edits will
not be reverted, overwritten, or folded into this change.

## Verification

1. Parse and schema-check the new geometry profile.
2. Run `validateProject`.
3. Run `tests/runAllTests.m`.
4. Run `validateCantImplementation` and save the reported zero-cant and
   tangential-cant gates.
5. Inspect the 10-degree wrench matrix numerically:
   - summed equal-command force and moment are zero except `Fz`;
   - yaw signs are `[-, +, -, +]`;
   - yaw magnitudes are greater than the zero-cant yaw magnitudes.
6. Confirm allocation rank, condition number, residual, negative demand,
   over-speed demand, and motor-limit status.
7. Compare the zero-cant VECTRA result with the pinned upstream QuadSim
   baseline at the existing state/RPM/throttle tolerances.
8. Inspect the final diff and scan it for credentials, generated results,
   sensitive device data, and unintended changes under `vendor/QuadSim`.

The MATLAB executable could not start inside the restricted execution layer
because its Qt runtime could not detect the required ARM processor feature.
Running the same official MATLAB R2026a executable on the host completed the
full verification; no test was waived.

## Verification record

- `validateProject`: passed
- `runAllTests`: 19 passed, 0 failed, 0 incomplete
- zero-cant upstream regression: passed
- alternating tangential 10-degree simulation: passed
- resolved angles: `[-10, 10, -10, 10]`
- yaw coefficients: `[-8.61745783543e-09, 8.61745783543e-09,
  -8.61745783543e-09, 8.61745783543e-09] N m / rpm^2`
- yaw-authority gain over zero cant: `2.94613943091`
- allocation rank: `4`
- steady-hover allocation: feasible
- steady-hover allocation residual norm: `5.35600615551e-19`
- vertical-force scale: `0.984807753012`
- hover-RPM ratio: `1.00813363051`
- motor-limit exceeded: false

## Approval record

Approved by the user on 2026-07-28.
