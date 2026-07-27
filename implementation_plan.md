# VECTRA Research Software Scaffold Plan

Status: implemented and verified on 2026-07-27 using the active MATLAB R2026a
desktop session.

## Objective

Create a complete, maintainable project hierarchy for VECTRA: a research
framework that connects a cant-angle-aware QuadSim model, Pixhawk/PX4 flight
tests, synchronized sensor logging, quantitative comparison, and a future GUI.

The existing QuadSim clone remains unchanged under `vendor/QuadSim`.

## Architecture

```text
VECTRA/
├── README.md
├── implementation_plan.md
├── .gitignore
├── config/
│   ├── vehicles/
│   ├── geometries/
│   ├── experiments/
│   └── schemas/
├── models/
│   ├── quadsim/
│   └── generated/
├── src/
│   └── matlab/
│       └── +vectra/
│           ├── +config/
│           ├── +quadsim/
│           ├── +px4/
│           ├── +sensors/
│           ├── +data/
│           ├── +analysis/
│           ├── +report/
│           └── +util/
├── scripts/
├── apps/
├── tests/
│   ├── unit/
│   ├── integration/
│   └── fixtures/
├── data/
│   ├── raw/
│   ├── processed/
│   └── catalog/
├── results/
│   ├── figures/
│   ├── tables/
│   └── reports/
├── hardware/
│   ├── pixhawk/
│   ├── sensors/
│   └── mechanical/
├── docs/
│   ├── architecture/
│   ├── protocols/
│   ├── data-dictionary/
│   └── walkthroughs/
└── vendor/
    ├── README.md
    └── QuadSim/
```

## Initial Files

The scaffold will include small, functional starting files rather than only
empty directories:

- `README.md`: project purpose, component map, and safe entry points.
- `.gitignore`: excludes raw flight logs, generated models, results, MATLAB
  caches, and local machine state while retaining directory markers.
- `config/vehicles/main_quad.json`: initial static vehicle profile with values
  marked as uncalibrated rather than fabricated.
- `config/geometries/cant_00.json`: baseline zero-cant geometry.
- `config/experiments/smoke_hover.json`: minimal simulation smoke-test profile.
- `config/schemas/*.schema.json`: validation contracts for vehicle, geometry,
  experiment, and resolved run configurations.
- `scripts/setupVECTRA.m`: adds only VECTRA and required QuadSim paths.
- `scripts/runSmokeSimulation.m`: future baseline simulation entry point.
- MATLAB package entry points for configuration loading, QuadSim adaptation,
  PX4 log import, data normalization, metric calculation, and report creation.
- Component READMEs describing the responsibility and expected interfaces of
  the GUI, hardware, model, test, and documentation areas.
- `vendor/README.md`: records the QuadSim source URL and pinned commit.

## Data Rules

- `data/raw` is immutable source data such as PX4 ULog and wind-sensor logs.
- Every run receives a `resolved_config.json` snapshot.
- `data/processed` contains normalized, reproducible derivatives.
- Large logs and generated outputs are ignored by version control.
- No credentials, device identifiers, or personal data are committed.

## Implementation Sequence

1. Create the directory hierarchy and documentation files.
2. Add configuration examples and JSON schemas.
3. Add MATLAB package and script entry points for the approved initialization
   scope while keeping live hardware control and the cant-model change deferred.
4. Add runnable unit tests and documented integration-test acceptance criteria.
5. Verify the tree, JSON syntax, MATLAB package naming, ignored-data behavior,
   and that `vendor/QuadSim` is unchanged.

## Acceptance Criteria

- All planned directories and files exist under `VECTRA`.
- QuadSim's nested Git working tree remains clean.
- All JSON and JSON Schema files parse successfully.
- MATLAB entry points have valid function/file naming and no hidden dependency
  on the current working directory.
- Raw logs, generated files, MATLAB cache files, and local secrets are ignored.
- No fabricated physical parameters are presented as measured values.
- The scaffold clearly separates simulation, hardware control, logging,
  analysis, reporting, and GUI responsibilities.

## Deferred Work

This scaffold does not yet:

- modify the QuadSim dynamics or mixer for cant angle;
- connect to or command a Pixhawk;
- read real sensor hardware;
- run a real flight;
- create a finished App Designer GUI;
- claim validated vehicle parameters.

Those changes require separate implementation and verification after the
scaffold is approved.
