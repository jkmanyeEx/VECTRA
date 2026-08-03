# VECTRA PX4 Telemetry GUI — Usage Guide

This guide covers the passive VECTRA telemetry console. The console receives
MAVLink data, displays channel health, and writes run-scoped research logs. It
does not arm the vehicle, change modes, write parameters, upload missions, or
send actuator commands.

## 1. Prerequisites

Install or prepare:

1. MATLAB R2026a, or a verified compatible release.
2. Python 3.11, or a verified compatible Python 3 release.
3. The free, project-local PyMAVLink environment.
4. QGroundControl connected to the PX4/Pixhawk telemetry device.
5. A VECTRA vehicle, geometry, and experiment profile matching the test.

Create and verify the dependency from MATLAB:

```matlab
startup
environment = installPymavlink()
```

`environment.ready` must be true. This creates `.venv` inside VECTRA and
installs the version pinned in `config/telemetry/requirements.txt`. It does not
modify the global Python environment and does not require UAV Toolbox.

## 2. Configure QGroundControl forwarding

The connected QGroundControl process normally owns UDP port `14550`. VECTRA
therefore listens on `14551`.

In QGroundControl:

1. Open **Application Settings**.
2. Open **Telemetry** or **MAVLink**, depending on the QGroundControl version.
3. Enable **MAVLink forwarding**.
4. Set the forwarding destination to `127.0.0.1:14551`.
5. Keep the existing vehicle link and heartbeat settings enabled.

QGroundControl forwarding is one-way from QGroundControl to VECTRA. This
matches the console's passive receive-only design. See the official
[QGroundControl Telemetry Settings](https://docs.qgroundcontrol.com/master/en/qgc-user-guide/settings_view/telemetry.html).

Do not configure VECTRA and QGroundControl to listen on the same local UDP port.

## 3. Launch the console

Open MATLAB in the VECTRA directory, then run:

```matlab
startup
app = launchTelemetryApp();
```

The default source is **PX4 Hardware**, and the default local port is `14551`.

To launch the deterministic simulated source:

```matlab
app = launchTelemetryApp( ...
    Source="simulated", ...
    AutoConnect=true);
```

Every simulated screen and recording shows `SIMULATED DATA`. Simulated output
must not be used as physical flight evidence.

## 4. Run the hardware check

Before connecting:

1. Select **PX4 Hardware**.
2. Confirm local UDP port `14551`.
3. Press **CHECK HARDWARE**.
4. Read the event log at the bottom.

The check reports:

- whether a USB serial telemetry device is visible to macOS;
- whether the VECTRA UDP port is available;
- whether the project Python interpreter, bridge, and PyMAVLink are ready.

A detected serial adapter only proves that the operating system can see the
device. A green/live heartbeat is required before VECTRA considers the PX4
source connected.

## 5. Connect and verify data

1. Select the vehicle, geometry, and experiment profiles.
2. Press **CONNECT LISTENER**.
3. Wait for `PX4 LIVE` and a system/component ID in the top rail.
4. Inspect **DATA QUALITY**.

Channel states:

| State | Meaning |
|---|---|
| `waiting` | No message has been received since connection |
| `live` | The message is arriving within its channel freshness limit |
| `stale` | Data arrived previously but has exceeded its freshness limit |
| `unsupported` | Reserved for a source that declares the channel unavailable |

The required physical channels are heartbeat, attitude/rates, local
position/velocity, battery, and actuator output. GPS is required for outdoor
flight but may remain unavailable during indoor or HITL work.

RPM appears only when PX4 emits measured `ESC_TELEMETRY_1_TO_4` data. VECTRA
does not estimate RPM from throttle. PX4 `WIND_COV` is estimator output and does
not replace the independent wind sensor required by the research protocol.

QGroundControl's
[MAVLink Inspector](https://docs.qgroundcontrol.com/master/en/qgc-user-guide/analyze_view/mavlink_inspector.html)
can be used to confirm whether a missing message is present on the vehicle link.

## 6. Record a run

After the source is connected:

1. Recheck the selected profiles.
2. Press **START RECORDING**.
3. For a physical source, confirm the run selection in the safety dialog.
4. Perform the test without closing MATLAB or disconnecting QGroundControl.
5. Press **STOP & FINALIZE**.

The run directory is shown in the left panel and is created under:

```text
data/raw/<run-id>/
```

It contains:

| File | Purpose |
|---|---|
| `resolved_config.json` | Exact vehicle, geometry, experiment, software, and telemetry configuration |
| `telemetry_events.jsonl` | Append-only decoded source-message journal |
| `telemetry_samples.csv` | Bounded-cadence normalized analysis table |
| `telemetry_manifest.json` | Counts, duration, stop reason, drop/gap statistics, and final channel completeness |

Raw run files must not be edited after the recording is finalized. Any
alignment, cleanup, or derived metric belongs under
`data/processed/<run-id>/`.

## 7. Recover an interrupted recording

If MATLAB or the computer stops before the manifest is written, keep the raw
journal unchanged and run:

```matlab
manifestFile = vectra.data.recoverTelemetryManifest( ...
    "data/raw/<run-id>");
```

The recovery function reads `telemetry_events.jsonl` and rebuilds
`telemetry_manifest.json`. It does not rewrite the source journal.

## 8. Coordinate and unit conventions

- MAVLink `LOCAL_POSITION_NED.x/y/z` is retained as
  `North_m/East_m/Down_m`.
- VECTRA inertial coordinates use `X_m = North_m`,
  `Y_m = East_m`, and `Z_m = -Down_m`.
- Body velocity `U_mps/V_mps/W_mps` is not populated unless a valid,
  documented frame conversion is available.
- Attitude and angular rates use radians and radians per second in files.
- Battery millivolts and centiamps are converted to volts and amperes.
- MAVLink unknown/sentinel values become missing values, never zero.

## 9. Troubleshooting

### “PyMAVLink is not installed in .venv”

Run:

```matlab
startup
installPymavlink()
```

If the installation is interrupted, remove no project data; rerunning the
function safely reuses `.venv` and completes the pinned package installation.

### “UDP port is already in use”

Do not use QGroundControl's `14550` listener. Keep QGroundControl on `14550`,
forward to `127.0.0.1:14551`, and keep VECTRA on `14551`. If another process
uses `14551`, choose a free port and update both forwarding and the VECTRA
field.

### Listener starts but heartbeat stays `waiting`

- Confirm QGroundControl shows the connected vehicle.
- Confirm MAVLink forwarding is enabled.
- Confirm the destination is `127.0.0.1` and the exact VECTRA port.
- Use QGroundControl's MAVLink Inspector to verify `HEARTBEAT`.
- Check local firewall rules without disabling system security.

### Heartbeat is live but every aircraft channel stays `waiting`

Older VECTRA builds could lock to QGroundControl's own
`SYS 255 / COMP 190` heartbeat when it arrived before the aircraft heartbeat.
The current monitor ignores that GCS heartbeat and waits for a heartbeat whose
autopilot field identifies PX4. The aircraft system ID is commonly `1`, but it
is not hardcoded.

Restart the listener after updating VECTRA. The vehicle badge must identify the
aircraft rather than remain on `SYS 255 / COMP 190`. If all other channels
still wait, verify in MAVLink Inspector that the forwarded stream contains the
corresponding aircraft messages.

### Attitude is live but actuator or RPM remains missing

The vehicle may not stream those message types on the active link. Confirm
`ACTUATOR_OUTPUT_STATUS`, `SERVO_OUTPUT_RAW`, or
`ESC_TELEMETRY_1_TO_4` in MAVLink Inspector. The output chart always displays
raw `SERVO_OUTPUT_RAW` PWM microseconds on a fixed scale; normalized
`ACTUATOR_OUTPUT_STATUS` values remain available in recorded data but never
change the chart mode. The chart labels physical output channels because
motor-to-output assignment is airframe configuration. VECTRA intentionally
does not send message-interval requests.

### GUI closes during recording

The app asks before closing and finalizes the manifest when possible. If the
process ended unexpectedly, use the recovery procedure in Section 7.

## 10. Safe test sequence

1. Verify the full workflow in **Simulated** mode.
2. Verify QGroundControl forwarding with the aircraft disarmed.
3. Verify with propellers removed.
4. Continue to SITL and HITL according to the VECTRA flight-test protocol.
5. Conduct a real flight only under the approved manual safety procedure.

The telemetry console is a research observer, not a flight controller.
