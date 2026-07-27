# Simulation validation protocol

## Baseline

- Preserve the pinned upstream QuadSim output for the smoke-hover profile.
- Confirm the zero-cant VECTRA model reproduces the same state convention.
- Compare attitude, position, RPM, and throttle traces.
- Document any solver or MATLAB-release difference.

## Physical calibration

- Replace example mass and inertia values with measurements.
- Estimate throttle-to-RPM, thrust, torque, and motor time-constant parameters.
- Verify motor saturation and cutoff behavior.
- Record parameter uncertainty and calibration range.

## Cant validation

- Confirm every rotor axis is a unit vector.
- Confirm force directions at positive cant angles.
- Confirm arm moments and reaction torques independently.
- Confirm equal motor speeds produce the intended symmetric wrench.
- Confirm the zero-degree allocation exactly reduces to the baseline.

## Wind validation

- Use wind-relative velocity rather than inertial velocity.
- Document reference area, drag coefficient, air density, and frame convention.
- Test constant, step, gust, and directional cases separately.
- Reject conclusions outside the calibrated aerodynamic range.
