# PX4 Live Telemetry Logging and Operator GUI Plan

Status: implemented on 2026-07-27. Its paid UAV Toolbox receive adapter was
superseded the same day by
[`toolbox-free-pymavlink-plan.md`](toolbox-free-pymavlink-plan.md).

## 1. Objective

Add a passive, research-grade PX4 telemetry path and a MATLAB operator GUI to
VECTRA. The first release will:

- receive live MAVLink 2 telemetry over UDP without commanding the aircraft;
- preserve timestamped source messages as immutable raw evidence;
- normalize supported values into the VECTRA data conventions;
- show connection, recording, data-quality, and required-channel status live;
- make missing or stale measurements explicit instead of fabricating values;
- support a clearly labeled simulated source for repeatable tests and GUI QA.

PX4 remains responsible for stabilization, estimation, arming, actuator output,
and failsafes. This GUI will not arm, change flight mode, upload missions, write
parameters, or request actuator output.

## 2. Confirmed platform and integration boundary

VECTRA is a MATLAB R2026a project and already uses UAV Toolbox for ULog import.
The implementation will therefore use the official UAV Toolbox MAVLink
interfaces:

- `mavlinkio` for the local MAVLink client;
- a UDP connection for a PX4, QGroundControl, router, SITL, or HITL stream;
- `mavlinksub` subscriptions and receive callbacks for live messages.

The initial transport will be UDP only. Direct flight-controller serial
transport is deferred because `mavlinkio` exposes UDP connectivity and a serial
bridge would add a separate hardware-specific reliability boundary.

The GUI will call VECTRA service objects. It will contain no MAVLink parsing,
file-format, coordinate-conversion, or metric logic.

## 3. Required and supplemental live data

### 3.1 Required acquisition channels

| VECTRA need | Preferred MAVLink message | Live fields | Availability rule |
|---|---|---|---|
| Link and vehicle status | `HEARTBEAT` | system/component, type, autopilot, mode, system status | Required before the source is considered connected |
| Attitude and body rates | `ATTITUDE` | roll, pitch, yaw, roll/pitch/yaw rates | Required |
| Local position and velocity | `LOCAL_POSITION_NED` | north/east/down position and velocity | Required |
| Battery | `BATTERY_STATUS` | voltage, current, consumed charge, remaining percentage | Required |
| Motor/actuator demand | `ACTUATOR_OUTPUT_STATUS` | active outputs and normalized actuator values | Required for motor-command analysis |
| GPS health | `GPS_RAW_INT` | fix, satellites, accuracy, coordinates, velocity | Required for outdoor flight, optional for indoor/HITL |

### 3.2 Conditional research channels

| VECTRA need | MAVLink/source | Rule |
|---|---|---|
| Motor RPM | `ESC_TELEMETRY_1_TO_4` and additional ESC groups when emitted | Record measured ESC RPM only; never derive RPM from throttle and label it measured |
| Attitude target | `ATTITUDE_TARGET` | Record as a supplemental controller target; do not relabel it as a pilot command |
| Estimator wind | `WIND_COV` | Supplemental only; it does not replace the independently calibrated wind sensor required by the research protocol |
| Independent wind | external sensor adapter, later phase | Keep a separate source identity and synchronization status |
| Cant angle | resolved VECTRA geometry | Static run metadata; keep nominal and measured values distinct |
| Rotor force and moment | VECTRA model/analysis | Derived data, not direct PX4 telemetry; do not present it as measured live telemetry |

### 3.3 Coordinate and unit rules

- Preserve every received MAVLink payload and its native units/frames in the raw
  event log.
- Normalize attitude and rates to radians and radians per second.
- Preserve `LOCAL_POSITION_NED` as explicitly named NED source columns.
- Publish VECTRA inertial `X_m = North`, `Y_m = East`, and `Z_m = -Down`.
- Do not populate body-frame `U_mps`, `V_mps`, or `W_mps` unless attitude and
  frame validity allow an explicit documented NED-to-body transformation.
- Convert battery millivolts and centiamps to volts and amperes while retaining
  original source fields.
- Treat MAVLink sentinel/unknown values as missing, not zero.

## 4. Runtime architecture

```text
PX4 / QGroundControl / SITL / HITL
                  |
                  v
       UDP MAVLink receive adapter
                  |
          +-------+-------+
          |               |
          v               v
 raw message journal   normalized sample state
          |               |
          v               v
 immutable run folder   GUI snapshots/charts
                          |
                          v
             channel freshness and quality
```

### 4.1 Source adapter

Add a PX4 live-source class under `src/matlab/+vectra/+px4` that owns the
MAVLink client, connection lifecycle, vehicle discovery, subscriptions, and
receive callbacks.

The adapter will:

- bind to a configurable local UDP port, defaulting to `14551` so it can
  coexist with QGroundControl's active `14550` listener;
- discover the first valid PX4 heartbeat and lock to its system/component IDs;
- reject or separately count messages from other systems;
- emit decoded message events without writing files or updating UI controls;
- track receive time, vehicle time when supplied, MAVLink sequence, message
  count, effective rate, age, gaps, and decode errors;
- disconnect cleanly and release callbacks and sockets.

### 4.2 Normalizer and live state

Add pure functions/classes that map decoded messages into a typed live snapshot.
Each value will carry:

- value and SI unit;
- source message and source field;
- source time and local receive time;
- freshness state: `waiting`, `live`, `stale`, or `unsupported`;
- measured, configured, or derived provenance.

This layer will be independently unit tested and will not depend on the GUI.

### 4.3 Streaming logger

Starting a recording will create a new run through VECTRA's resolved
configuration path. The logger will write:

- `resolved_config.json`;
- `telemetry_events.jsonl`, containing append-only decoded source messages,
  receive timestamps, source timestamps, system/component IDs, and sequence;
- `telemetry_samples.csv`, containing the normalized analysis-ready snapshot
  columns at a bounded logging cadence;
- `telemetry_manifest.json`, containing schema version, message counts, first
  and last timestamps, drop/gap counters, channel completeness, stop reason,
  VECTRA/MATLAB versions, and connection metadata.

Files will be flushed periodically and on normal stop. An interrupted session
will remain readable; a recovery function will rebuild the manifest from the
event journal without changing the journal.

Raw run directories remain immutable after recording closes. Reprocessing will
write only to `data/processed/<run-id>`.

### 4.4 Simulated source

A deterministic simulated source will implement the same event contract as the
PX4 adapter. It will provide:

- nominal changing telemetry for GUI development;
- deliberate stale-channel and message-gap scenarios;
- battery and actuator trends;
- an unmistakable `SIMULATED DATA` banner and metadata flag.

It will never be possible to label simulated recordings as physical flight.

## 5. GUI design

Implement a version-controlled MATLAB `uifigure` application in `apps/` with a
small launcher in `scripts/`. A programmatic app is preferred over committing a
binary `.mlapp` file because its behavior and review history remain inspectable.

### 5.1 Layout

- **Top status rail:** VECTRA identity, source type, PX4 link state, vehicle
  system ID, heartbeat age, recording state, and UTC/elapsed time.
- **Left run panel:** vehicle, geometry, and experiment profile selectors; UDP
  port; connect/disconnect; simulated-source toggle; start/stop recording; run
  ID and output location.
- **Center live workspace:** attitude horizon-style summary, roll/pitch/yaw and
  rate trends, local position/velocity trends, battery trend, and motor output
  bars/trends.
- **Right data-quality rail:** required-channel checklist with source, rate,
  age, completeness, and `live/stale/missing` state; GPS and external-wind
  distinctions remain visible.
- **Bottom event strip:** connection, recorder, gap, stale-channel, and error
  events with severity and time.

The visual direction will use a restrained dark flight-instrument surface,
high-contrast numeric telemetry, cyan for live data, amber for degraded data,
red only for actionable faults, and clear non-color status labels.

### 5.2 Interaction and safety

- Connection does not automatically start recording.
- Starting a physical recording requires explicit confirmation of the selected
  profiles and output run ID.
- Closing the app while recording prompts for a controlled stop.
- No aircraft command controls are present.
- Plot refresh is rate-limited independently of the receive path so rendering
  cannot block telemetry capture.
- Charts use bounded rolling buffers; the logger retains the full session.

## 6. Configuration and documentation changes

- Add a live telemetry configuration schema and an initial local UDP profile.
- Extend the canonical data dictionary with source columns, provenance,
  freshness, and explicit NED-to-VECTRA conversion rules.
- Update `requirements.md` with the UAV Toolbox live-MAVLink dependency and UDP
  routing expectation.
- Update `apps/README.md` with the operator app boundary and launcher.
- Add a setup note for QGroundControl/PX4 UDP routing without embedding device
  identifiers or network credentials.

## 7. Planned files

The exact class split may be adjusted during implementation, but responsibilities
will remain separated:

```text
apps/
└── VectraTelemetryApp.m
config/
├── schemas/telemetry.schema.json
└── telemetry/local_udp.json
scripts/
└── launchTelemetryApp.m
src/matlab/+vectra/+px4/
├── LiveTelemetrySource.m
├── SimulatedTelemetrySource.m
├── normalizeTelemetryMessage.m
└── telemetryDefinitions.m
src/matlab/+vectra/+data/
├── LiveTelemetryLogger.m
└── recoverTelemetryManifest.m
tests/unit/
├── TestPX4Telemetry.m
└── TestLiveTelemetryLogger.m
tests/integration/
└── TestTelemetryLoopback.m
docs/walkthroughs/
└── px4-live-telemetry-gui.md
```

## 8. Verification plan

### 8.1 Automated

- Validate new JSON profiles and schema.
- Unit-test every supported MAVLink message mapping, sentinel value, unit
  conversion, timestamp, provenance, and coordinate conversion.
- Test foreign-system filtering, duplicate/out-of-order sequence handling,
  stale transitions, reconnect cleanup, and unsupported messages.
- Test logger start/stop, periodic flush, manifest counts, CSV consistency,
  interrupted-session recovery, and raw-directory immutability.
- Exercise a local loopback MAVLink stream without aircraft commands.
- Run `validateProject` and `tests/runAllTests.m`.
- Scan all changes for secrets, private device identifiers, and accidental raw
  flight data.

### 8.2 GUI

- Run with the deterministic simulated source and with a local loopback stream.
- Verify connect, disconnect, record, stop, close-during-recording, message-gap,
  stale-channel, and recovery flows.
- Confirm charts remain responsive under a telemetry rate higher than the UI
  refresh rate.
- Verify resizing and legibility at a practical laptop resolution.
- Produce `docs/walkthroughs/px4-live-telemetry-gui.md` with screenshots of:
  - disconnected state;
  - simulated live state;
  - physical-source connection state without arming;
  - active recording and run ID;
  - stale/missing required channel;
  - completed log files and automated test results.

Hardware-in-the-loop verification will be documented separately if no Pixhawk
is available during implementation. No propeller-on or free-flight test is part
of this change.

## 9. Acceptance criteria

- A user can connect to a PX4-compatible UDP MAVLink stream and see heartbeat,
  attitude, rates, local position/velocity, battery, actuator, and GPS status.
- A user can start and stop a run-scoped recording without losing the full raw
  event stream.
- Every displayed required value identifies its source and freshness.
- Missing RPM, independent wind, or other unavailable channels remain visibly
  missing and are never inferred as measurements.
- GUI rendering cannot block or own the receive/logging path.
- The app contains no arming, mode, mission, parameter-write, or actuator
  command path.
- Automated tests and the visual walkthrough pass.

## 10. Approval gate

Implementation begins after approval of this plan. The defaults requiring
approval are:

- MATLAB programmatic GUI rather than a web frontend;
- passive MAVLink 2 over UDP, local port `14551` after the connected-hardware
  check found QGroundControl already holding `14550`;
- immutable JSONL source journal plus normalized CSV and manifest;
- the data-channel mapping in Section 3;
- simulated-source mode for repeatable verification;
- no flight-control or PX4 configuration commands.
