# VECTRA Operator Application

The operator application will be implemented after the command-line simulation,
PX4 logging, synchronization, and analysis paths pass integration tests.

Its approved responsibilities are:

- select validated vehicle, geometry, and experiment profiles;
- inspect dependency and Pixhawk connection status;
- run simulation jobs;
- display preflight gates without bypassing PX4 safety systems;
- associate ULog and external-sensor files with a run;
- visualize normalized simulation and flight data;
- export versioned analysis reports.

The GUI must call functions in `+vectra`; it must not duplicate simulation,
hardware, parsing, or analysis logic.
