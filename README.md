# VECTRA

Vectored-thrust Experimental Control, Testing, Research & Analytics.

VECTRA is the research software workspace for comparing cant-angle-aware
quadcopter simulations with Pixhawk/PX4 flight tests. It keeps the simulation,
flight configuration, raw logs, normalized data, quantitative analysis, and
future operator GUI under one reproducible project structure.

## Core workflow

1. Define a static vehicle profile.
2. Select a cant geometry and experiment profile.
3. Run the QuadSim adapter or a PX4 flight test.
4. Preserve the raw run data and resolved configuration.
5. Normalize both sources into the VECTRA data schema.
6. Calculate comparable metrics and generate research outputs.

## Quick start

Open MATLAB in this directory and run:

```matlab
run("startup.m")
vectra.environment()
```

To attempt the unmodified QuadSim smoke simulation:

```matlab
run("scripts/runSmokeSimulation.m")
```

The smoke run is intentionally separate from the cant model. It first proves
that the pinned 2014 QuadSim dependency works with the installed MATLAB release.

To configure the VECTRA-owned Simulink copy and run the minimal cant checks:

```matlab
runCantValidationLogged()
```

The cant check compares the pinned upstream model with zero cant, then verifies
the expected force and hover-RPM direction for the symmetric 10-degree profile.
It is an implementation check, not the later mass/propeller/disk-loading
research sweep. The complete console transcript and machine-readable report are
saved under `results/reports/cant-validation/`.

The completed implementation and validation report is available in
[`docs/reports/cant-model-implementation-validation-report.pdf`](docs/reports/cant-model-implementation-validation-report.pdf),
with editable DOCX and Markdown source files in the same directory.

## Project boundaries

- `vendor/QuadSim` is an external dependency and must remain unmodified.
- `models/quadsim` is reserved for VECTRA-owned Simulink model variants.
- `data/raw` stores immutable source logs and is not committed.
- `data/processed` stores reproducible normalized data and is not committed.
- `results` stores generated figures, tables, and reports.
- Pixhawk safety-critical stabilization, sensor fusion, arming, and failsafes
  remain the responsibility of PX4.

See [implementation_plan.md](implementation_plan.md) and
[docs/architecture/README.md](docs/architecture/README.md) for the detailed
architecture.
