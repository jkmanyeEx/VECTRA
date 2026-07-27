# Architecture

VECTRA separates safety-critical flight control from research orchestration and
analysis.

```text
Configuration profiles
        |
        v
Resolved run configuration
        |
        +-------------------+
        |                   |
        v                   v
QuadSim adapter        PX4/Pixhawk boundary
        |                   |
        v                   v
Simulation data        ULog + sensor logs
        |                   |
        +---------+---------+
                  |
                  v
          Canonical timetables
                  |
                  v
       Metrics, comparison, reports
```

## Dependency rule

Code may depend inward toward pure configuration and data utilities. Hardware,
simulation, and GUI adapters may call analysis interfaces, but analysis code
must not command hardware or alter raw logs.

## Source-of-truth rule

VECTRA configuration is authoritative for research metadata. QuadSim
`quadModel` structures, PX4 parameter snapshots, and GUI values are generated
or selected from resolved configuration rather than maintained as competing
manual copies.

## Safety boundary

PX4 owns real-time stabilization and failsafes. VECTRA may prepare and monitor a
test, but it must not silently bypass arming checks or manual operator control.
