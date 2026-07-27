# Software and Hardware Requirements

## Required for local simulation

- MATLAB R2026a or a verified compatible release
- Simulink
- VECTRA's pinned QuadSim dependency

## Required for PX4 log analysis

- UAV Toolbox
- PX4 ULog files recorded by the supported flight controller

## Required for live PX4 telemetry GUI

- Python 3.11 or a verified compatible Python 3 release
- project-local PyMAVLink environment created by `installPymavlink`
- QGroundControl or another documented MAVLink router
- a one-way UDP MAVLink stream to the configured VECTRA listener
- default VECTRA endpoint `127.0.0.1:14551`

Live reception, the simulated source, GUI construction, normalization, and
logging do not require UAV Toolbox. UAV Toolbox remains optional for offline
`ulogreader` workflows.

## Required for deployment or HITL

- UAV Toolbox Support Package for PX4 Autopilots
- Simulink Coder
- Embedded Coder
- A MathWorks-supported Windows or Linux host
- A supported Pixhawk flight controller
- QGroundControl for PX4 setup and safety configuration

## Research instrumentation

- independently calibrated wind-speed measurement
- wind-direction measurement or controlled flow direction
- battery voltage and current measurement
- measured cant angle for each motor mount
- optional motor RPM measurement

The Mac workspace is appropriate for QuadSim development, data processing, and
analysis. PX4 deployment and HITL must use a currently supported host platform.
