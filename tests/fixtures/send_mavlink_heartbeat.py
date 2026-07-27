#!/usr/bin/env python3
"""Send one MAVLink 2 heartbeat to a local VECTRA test endpoint."""

import argparse
import os
import time

os.environ.setdefault("MAVLINK20", "1")

from pymavlink import mavutil


parser = argparse.ArgumentParser()
parser.add_argument("--port", type=int, required=True)
args = parser.parse_args()

connection = mavutil.mavlink_connection(
    f"udpout:127.0.0.1:{args.port}",
    source_system=31,
    source_component=1,
    dialect="common",
)
for _ in range(3):
    connection.mav.heartbeat_send(
        mavutil.mavlink.MAV_TYPE_QUADROTOR,
        mavutil.mavlink.MAV_AUTOPILOT_PX4,
        0,
        458752,
        mavutil.mavlink.MAV_STATE_STANDBY,
    )
    time.sleep(0.1)
connection.close()
