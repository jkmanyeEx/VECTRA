# VECTRA Operator Application

`VectraTelemetryApp.m` implements the passive PX4 live-telemetry and logging
console. Launch it through:

```matlab
app = launchTelemetryApp();
```

For a hardware-independent demonstration:

```matlab
app = launchTelemetryApp(Source="simulated", AutoConnect=true);
```

The current app can:

- select vehicle, geometry, and experiment profiles;
- inspect the USB adapter, UDP port, project Python, and PyMAVLink dependency;
- receive passive MAVLink 2 telemetry over UDP;
- display live state and channel freshness;
- record immutable source events and normalized samples;
- recover a manifest after an interrupted recording.

Simulation jobs, offline ULog association, external-sensor synchronization, and
analysis report export remain separate VECTRA workflows.

The GUI calls functions in `+vectra`; it does not duplicate simulation,
hardware, parsing, or analysis logic.

See [the usage guide](../docs/usage/px4-telemetry-gui.md).
