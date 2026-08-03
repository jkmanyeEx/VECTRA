# Canonical data dictionary

All normalized values use SI units and elapsed time from the selected run
alignment event.

| Variable | Unit | Convention |
|---|---:|---|
| `Time` | s | elapsed duration |
| `P_radps` | rad/s | body roll rate |
| `Q_radps` | rad/s | body pitch rate |
| `R_radps` | rad/s | body yaw rate |
| `Roll_rad` | rad | body roll angle |
| `Pitch_rad` | rad | body pitch angle |
| `Yaw_rad` | rad | body yaw angle |
| `U_mps` | m/s | body-frame x velocity |
| `V_mps` | m/s | body-frame y velocity |
| `W_mps` | m/s | body-frame z velocity |
| `X_m` | m | normalized inertial x position |
| `Y_m` | m | normalized inertial y position |
| `Z_m` | m | normalized inertial z position |
| `MotorN_rpm` | rpm | measured or modeled rotor speed |
| `MotorN_throttle_pct` | % | normalized actuator command |
| `RollCmd_rad` | rad | roll command |
| `PitchCmd_rad` | rad | pitch command |
| `YawCmd_rad` | rad | yaw command |
| `ZCmd_m` | m | altitude or z command after conversion |
| `Fx_body_N` | N | total rotor force along QuadSim body x |
| `Fy_body_N` | N | total rotor force along QuadSim body y |
| `Fz_body_N` | N | total rotor force along QuadSim body +z |
| `Mx_body_Nm` | N·m | total arm and reaction moment about body x |
| `My_body_Nm` | N·m | total arm and reaction moment about body y |
| `Mz_body_Nm` | N·m | total arm and reaction moment about body z |
| `WindSpeed_mps` | m/s | independent measured wind speed |
| `WindDirection_deg` | deg | documented meteorological convention |
| `BatteryVoltage_V` | V | vehicle battery voltage |
| `BatteryCurrent_A` | A | vehicle battery current |

PX4 NED, QuadSim body/inertial frames, and any laboratory frame must be
explicitly transformed before data is marked canonical.

## Live telemetry source columns

The live logger preserves native source fields in `telemetry_events.jsonl` and
writes the following analysis-facing source columns to
`telemetry_samples.csv`:

| Variable | Unit | Source and conversion |
|---|---:|---|
| `ReceivedUnixSec` | s | local UTC POSIX receive time |
| `Elapsed_s` | s | elapsed recording time |
| `SystemID` | — | MAVLink source system |
| `ComponentID` | — | MAVLink source component |
| `IsSimulated` | bool | explicit source provenance |
| `North_m` | m | `LOCAL_POSITION_NED.x` |
| `East_m` | m | `LOCAL_POSITION_NED.y` |
| `Down_m` | m | `LOCAL_POSITION_NED.z` |
| `VNorth_mps` | m/s | `LOCAL_POSITION_NED.vx` |
| `VEast_mps` | m/s | `LOCAL_POSITION_NED.vy` |
| `VDown_mps` | m/s | `LOCAL_POSITION_NED.vz` |
| `X_m` | m | North |
| `Y_m` | m | East |
| `Z_m` | m | negative Down |
| `MotorN_output` | normalized | active `ACTUATOR_OUTPUT_STATUS.actuator[N]` |
| `MotorOutputPort` | — | `SERVO_OUTPUT_RAW.port`; Pixhawk uses 0 for MAIN and 1 for AUX |
| `MotorN_pwm_us` | µs | raw physical output from `SERVO_OUTPUT_RAW.servoN_raw` |
| `MotorN_rpm` | rpm | measured `ESC_TELEMETRY_1_TO_4.rpm[N]` only |

Every live channel also carries a source message, provenance category, update
rate, last receive time, and freshness state in the in-memory snapshot and
final manifest. MAVLink sentinel values are represented as missing values.
Raw PWM is never silently converted to normalized demand. Confirm the PX4
actuator assignment before interpreting output channels as motor numbers.

## Cant allocation diagnostics

The VECTRA Cant Simulink model records a six-value diagnostic signal separately
from the upstream-compatible 24-column `yout` array:

| Index | Meaning |
|---:|---|
| 1 | allocation feasible flag |
| 2 | negative squared-RPM demand flag |
| 3 | maximum-RPM demand flag |
| 4 | achieved active-wrench residual norm |
| 5 | minimum requested squared RPM |
| 6 | maximum requested RPM |

`rotorSpinSigns` describe rotor angular momentum. `reactionTorqueSigns` describe
the opposite torque applied to the vehicle body; they must not be conflated.
