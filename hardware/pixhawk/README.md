# Pixhawk and PX4

PX4 remains responsible for sensor drivers, state estimation, rate and attitude
stabilization, actuator output, arming, and failsafes.

VECTRA is responsible for:

- validating connection and operator authority;
- selecting a versioned experiment profile;
- issuing high-level test phases only after safety gates pass;
- associating ULog files with VECTRA run IDs;
- importing telemetry for offline normalization and analysis;
- retaining exported PX4 parameter snapshots for reproducibility.

Actual aircraft commands require manual operator confirmation and a tested
manual override. Unattended automated tests are restricted to simulation.
