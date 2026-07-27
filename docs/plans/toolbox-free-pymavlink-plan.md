# Toolbox-Free PyMAVLink Telemetry Plan

Status: implemented on 2026-07-27; physical heartbeat validation remains a
bench-test gate

## Objective

Replace the paid UAV Toolbox runtime dependency in VECTRA's physical telemetry
path with the open-source PyMAVLink package while preserving the implemented
MATLAB GUI, data-quality monitor, raw journal, normalized CSV, manifest, and
simulated source.

## Architecture

```text
PX4 telemetry adapter
        |
        v
QGroundControl serial link and MAVLink forwarding
        |
        v
127.0.0.1:14551
        |
        v
Python PyMAVLink bridge
        |
        | newline-delimited JSON over process stdout
        v
MATLAB LiveTelemetrySource
        |
        +--------------------+
        v                    v
TelemetryMonitor     LiveTelemetryLogger
        |
        v
VectraTelemetryApp
```

## Dependency isolation

- Create a project-local `.venv`.
- Install `pymavlink` from PyPI into that environment.
- Ignore `.venv` in Git.
- Record the installed package versions in
  `config/telemetry/pymavlink-lock.json`.
- Do not require or modify the user's global Python environment.

## Python bridge

Add `scripts/telemetry/pymavlink_bridge.py`.

The bridge will:

- open a passive `udpin` endpoint on the configured local port;
- use PyMAVLink's dialect and checksum handling;
- emit one UTF-8 JSON object per received message;
- include message name, payload, system/component IDs, sequence, UTC receive
  time, and source timestamp when available;
- emit explicit startup, listening, warning, and stop status objects;
- never call MAVLink send, command, mission, parameter-write, or actuator APIs;
- handle malformed packets without terminating the stream;
- shut down cleanly on process termination.

Stdout is reserved for the NDJSON protocol. Diagnostic output goes to stderr.

## MATLAB source adapter

Refactor `LiveTelemetrySource` to:

- locate the project-local Python interpreter;
- verify that `pymavlink` imports before connecting;
- launch the bridge with Java `ProcessBuilder`;
- poll stdout on a bounded MATLAB timer without blocking the GUI;
- buffer partial lines and decode complete JSON objects;
- convert bridge events to the existing VECTRA telemetry event contract;
- expose bridge stderr and process exits as operator events;
- terminate the bridge and timers cleanly on disconnect or app close.

No parsing, file-format, or analysis logic will move into the GUI.

## Hardware check

The **CHECK HARDWARE** action will report:

- USB telemetry adapter presence;
- availability of UDP port `14551`;
- project Python interpreter availability;
- PyMAVLink import and version;
- QGroundControl/port guidance.

UAV Toolbox will no longer be a readiness requirement.

## Configuration

Extend the telemetry profile with:

- `decoder: "pymavlink"`;
- project-relative Python interpreter;
- project-relative bridge script;
- MAVLink dialect;
- process polling period.

The resolved run snapshot will retain these values and the installed PyMAVLink
version.

## Verification

### Python

- encode and send real MAVLink 2 heartbeat, attitude, local position, battery,
  actuator, GPS, ESC telemetry, target, and wind packets;
- verify bridge NDJSON schema, payload values, source IDs, and sequence;
- verify malformed-packet tolerance;
- verify that the bridge has no send path.

### MATLAB

- run all existing normalization and logger tests;
- update the live-source dependency test for PyMAVLink;
- run a Python UDP loopback through `LiveTelemetrySource` into
  `TelemetryMonitor`;
- run project validation;
- run the simulated GUI smoke test;
- run Code Analyzer, JSON parsing, diff checks, and sensitive-data scanning.

### Physical gate

The connected adapter is accepted only after:

- QGroundControl forwards to `127.0.0.1:14551`;
- the bridge reports listening;
- a current PX4 heartbeat locks the source system ID;
- required message rates and freshness are visible;
- a short disarmed, propeller-off recording finalizes successfully.

## Acceptance criteria

- Physical telemetry no longer requires UAV Toolbox.
- PyMAVLink is isolated to `.venv` and version-locked.
- The bridge validates MAVLink framing and checksum through PyMAVLink.
- MATLAB receives the existing event schema without GUI parsing.
- The full simulated and packet-loopback paths pass.
- No aircraft-command or message-send call exists in the bridge or MATLAB
  physical source.
