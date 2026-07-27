# Configuration

Configuration is separated into three layers:

- `vehicles`: static physical and propulsion parameters.
- `geometries`: motor positions, spin directions, and cant geometry.
- `experiments`: run-specific commands and environmental conditions.

Every execution must resolve these layers and save a complete snapshot beside
the raw run data. Example values marked `calibrated: false` are structural
defaults only and must not be treated as measured vehicle parameters.
