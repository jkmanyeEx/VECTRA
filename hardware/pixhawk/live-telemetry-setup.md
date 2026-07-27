# PX4 live telemetry setup

VECTRA receives a one-way MAVLink copy from QGroundControl:

```text
PX4/Pixhawk telemetry link
          |
          v
  QGroundControl :14550
          |
          | one-way MAVLink forwarding
          v
  127.0.0.1:14551
          |
          v
  VECTRA passive listener
```

## Connection rules

- Keep QGroundControl attached to the physical serial telemetry device.
- Enable QGroundControl MAVLink forwarding to `127.0.0.1:14551`.
- Keep the VECTRA source set to **PX4 Hardware** and local port `14551`.
- Do not expose the VECTRA listener outside localhost unless the test network
  has an approved security and routing design.
- Do not place device serial numbers, network credentials, or signing keys in
  committed configuration.

## Readiness checks

In the GUI, press **CHECK HARDWARE** before **CONNECT LISTENER**. A physical run
requires:

- a visible USB telemetry adapter or another documented QGroundControl link;
- an available VECTRA UDP port;
- the project Python environment and PyMAVLink bridge;
- a current PX4 heartbeat after connecting;
- the approved preflight checklist.

QGroundControl forwarding is receive-only from VECTRA's perspective. The
PyMAVLink bridge and current app contain no MAVLink send or command path.
