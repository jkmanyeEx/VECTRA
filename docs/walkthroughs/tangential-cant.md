# Tangential Cant for Yaw Authority

## Geometry

The active tangential research profile uses a 10-degree cant magnitude. Cant is
measured from body `+Z`; the sign selects one of the two local tangential
directions.

| Motor | Position | Tangential cant |
|---|---:|---:|
| M1 | `+X` | `-10 deg` |
| M2 | `+Y` | `+10 deg` |
| M3 | `-X` | `-10 deg` |
| M4 | `-Y` | `+10 deg` |

The signs align the arm-generated yaw moment with the existing reaction-torque
signs `[-1, +1, -1, +1]`.

For motor `i`, with radial position `r_i`, local positive tangent `e_t,i`, and
signed cant `theta_i`, the thrust axis is

```text
u_i = sin(theta_i) e_t,i + cos(theta_i) body_Z.
```

The yaw effectiveness per squared RPM contains both the tangential arm moment
and the tilted rotor reaction torque:

```text
B_yaw,i = d CT_i sin(theta_i)
          + reactionTorqueSign_i CQ_i cos(theta_i).
```

With the approved sign pattern, equal motor commands cancel total yaw moment,
while differential motor commands receive greater yaw effectiveness than the
zero-cant reaction-torque term alone.

## Why all motors do not use the same sign

Four equal, same-direction tangential angles would make every arm-generated yaw
term point the same way. The vehicle would then have a collective-thrust-driven
yaw bias during hover, and the allocator would need continuous differential
motor demand to oppose it.

Alternating the signs preserves a balanced equal-thrust hover and makes the
tangential contribution useful for commanded yaw.

## Active profile

The machine-readable configuration is:

```text
config/geometries/cant_tangential_10.json
```

The original radial profile remains available as historical validation
evidence. It is not silently relabeled as tangential.

## Verification entry points

From a configured MATLAB R2026a session at the VECTRA root:

```matlab
run("startup.m")
validateProject
results = runAllTests
report = validateCantImplementation
```

The validation checks:

- zero-cant agreement with the pinned upstream QuadSim baseline;
- unit rotor axes and the signed tangential directions;
- zero equal-command horizontal force and body moment;
- `cos(10 deg)` vertical-force scaling;
- alternating yaw signs and increased yaw coefficient magnitude;
- rank-four control allocation;
- feasible steady-hover allocation without negative or over-speed demand;
- finite simulation output and motor-limit compliance.

## Verified result

MATLAB R2026a verification completed on 2026-07-28:

| Check | Result |
|---|---:|
| Project validation | Passed |
| Automated tests | 19 passed, 0 failed |
| Zero-cant upstream regression | Passed |
| Tangential 10-degree simulation | Passed |
| Resolved motor angles | `[-10, 10, -10, 10] deg` |
| Yaw coefficients | `[-8.6175e-09, 8.6175e-09, -8.6175e-09, 8.6175e-09] N m / rpm^2` |
| Yaw-authority gain | `2.9461` |
| Allocation rank | `4` |
| Steady-hover allocation | Feasible |
| Allocation residual norm | `5.3560e-19` |
| Vertical-force scale | `0.984807753012` |
| Hover-RPM ratio | `1.00813363051` |
| Motor-limit exceeded | No |

No physical flight safety or PX4 validation is implied by simulation success.
SITL and HITL remain required before a propeller-off actuator check or flight.
