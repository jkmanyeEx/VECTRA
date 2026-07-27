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
