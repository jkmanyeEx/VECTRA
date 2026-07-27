# Preflight checklist

## Configuration

- Confirm the physical geometry ID and measured cant angles.
- Confirm the PX4 parameter snapshot and firmware version.
- Confirm the correct propellers and motor spin directions.
- Confirm vehicle mass, center of mass, battery, and payload.

## Safety

- Establish a controlled test area and designated operator.
- Verify manual override and disarm behavior.
- Verify geofence, altitude limit, and communication-loss failsafe.
- Verify battery warning and critical thresholds.
- Verify the flight-test plan has an explicit abort condition.

## Instrumentation

- Start the independent wind logger.
- Check sensor time synchronization.
- Confirm Pixhawk SD-card logging.
- Record test ID and environmental notes.

## Authorization

- The operator confirms the aircraft is safe to arm.
- The software reports all flight-authority gates as passing.
- The first test after a configuration change is a restricted low-energy test.
