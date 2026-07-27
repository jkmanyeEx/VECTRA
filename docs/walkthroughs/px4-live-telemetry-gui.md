# PX4 live telemetry GUI walkthrough

## Implemented flow

```text
PX4 / QGroundControl / SITL / HITL
                  |
                  v
     Python PyMAVLink bridge
                  |
                  v
        LiveTelemetrySource
                  |
                  v
          TelemetryMonitor
          /              \
         v                v
LiveTelemetryLogger   VectraTelemetryApp
```

- `pymavlink_bridge.py` is a passive MAVLink 2 UDP receiver. It validates and
  decodes MAVLink frames, then emits newline-delimited JSON to MATLAB.
- `LiveTelemetrySource` owns that child process and contains no message-send
  path.
- `SimulatedTelemetrySource` implements the same callback contract and marks
  every event as simulated.
- `TelemetryMonitor` locks to the first heartbeat system ID, filters other
  systems, tracks sequence gaps and rates, normalizes supported messages, and
  marks late channels stale.
- `LiveTelemetryLogger` writes the source journal continuously and samples the
  normalized state at a bounded cadence.
- `VectraTelemetryApp` renders state, channel quality, and recorder controls
  without containing parsing or file-format logic.

## GUI states exercised

MATLAB R2026a successfully completed:

```text
gui_construct_ok
gui_sim_ok
```

The construction check created and closed the complete programmatic GUI. The
simulated-source check ran live timers, normalized changing telemetry, refreshed
the UI, and shut down both timers cleanly.

The GUI includes:

- disconnected, listening, simulated, live, stale, and error link states;
- immutable source/run/profile selectors while connected;
- separate connect and recording actions;
- explicit physical-recording confirmation;
- close-during-recording finalization;
- required-channel source, update-rate, and age display;
- attitude, position, battery, and four-motor live plots;
- a visible `SIMULATED DATA` banner;
- a timestamped operational event log.

## Connected hardware check

Read-only host inspection on 2026-07-27 found:

- one FTDI FT231X USB UART telemetry adapter visible to macOS;
- QGroundControl holding the serial connection;
- QGroundControl already bound to UDP port `14550`.

This evidence changed the VECTRA default endpoint to `127.0.0.1:14551`.
QGroundControl must enable one-way MAVLink forwarding to that endpoint.

The MATLAB R2026a installation does not expose `mavlinkio` or `ulogreader`.
Live reception therefore uses the free project-local PyMAVLink bridge and does
not require UAV Toolbox. The app's **CHECK HARDWARE** action reports the Python
interpreter, bridge, installed PyMAVLink version, serial-device visibility, and
UDP-port availability before connection.

The project-local `.venv` contains PyMAVLink `2.4.49`, with resolved packages
recorded in `config/telemetry/pymavlink-lock.json`. No system-wide Python
packages were changed.

No device serial number or other unique hardware identifier is retained in the
repository.

## Automated coverage

The telemetry tests cover:

- first-heartbeat source locking;
- foreign-system rejection;
- sequence-gap counting;
- attitude, rate, NED position, altitude, battery, GPS, actuator, RPM, target,
  and estimator-wind normalization;
- sentinel-to-missing conversions;
- quaternion target conversion;
- live-to-stale transitions;
- append-only journal and normalized CSV creation;
- final manifest generation;
- interrupted-manifest recovery without rewriting the journal;
- existing-run overwrite refusal;
- explicit missing-PyMAVLink behavior;
- a real MAVLink 2 heartbeat loopback through the Python bridge when the
  project environment is installed;
- a static assertion that the bridge contains no MAVLink send calls.

MATLAB Code Analyzer reports no telemetry implementation errors or warnings,
and all new JSON files parse successfully. The bridge import/version check,
event-contract test, and no-send-path test pass. The real localhost UDP
heartbeat test is implemented, but execution from Codex remains blocked by the
desktop sandbox's socket restriction and its approval-service error.

## Visual evidence status

The GUI was constructed and exercised programmatically, but the automated
visible-window screenshot action was blocked by the desktop execution approval
layer and the Computer Use image capture service returned
`failedToCreateImageDestination`. No synthetic screenshot is substituted for
real UI evidence.

After visible MATLAB execution is permitted, generate the walkthrough image
with:

```matlab
app = launchTelemetryApp( ...
    Source="simulated", ...
    AutoConnect=true);
pause(3)
exportapp(app.Figure, ...
    "docs/walkthroughs/px4-telemetry-simulated.png")
```

The expected image location is:

```text
docs/walkthroughs/px4-telemetry-simulated.png
```

## Physical validation gate

Before a physical run is accepted:

1. run `installPymavlink` and confirm `environment.ready` is true;
2. enable QGroundControl forwarding to `127.0.0.1:14551`;
3. run **CHECK HARDWARE**;
4. verify `PX4 LIVE` while disarmed and with propellers removed;
5. confirm required channel rates and freshness;
6. record and finalize a short bench run;
7. inspect the raw journal, normalized CSV, and manifest.

SITL and HITL remain required before real flight.
