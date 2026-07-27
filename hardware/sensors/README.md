# External sensors

External sensors provide evidence that is independent of PX4 state estimation.
Every sensor integration must document:

- model and firmware revision;
- physical location and orientation;
- unit and coordinate convention;
- sample rate and timestamp source;
- calibration date and uncertainty;
- missing-data behavior;
- file format and parser version.

The canonical wind parser accepts elapsed time, wind speed in metres per
second, and optional wind direction in degrees.
