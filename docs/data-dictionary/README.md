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
