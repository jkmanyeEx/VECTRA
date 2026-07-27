"""Tests for VECTRA's passive PyMAVLink bridge."""

from __future__ import annotations

import ast
import importlib.util
import json
import os
import selectors
import socket
import subprocess
import sys
import time
import unittest
from pathlib import Path

os.environ.setdefault("MAVLINK20", "1")

try:
    from pymavlink import mavutil
except ModuleNotFoundError:
    mavutil = None


PROJECT_ROOT = Path(__file__).resolve().parents[2]
BRIDGE_PATH = PROJECT_ROOT / "scripts" / "telemetry" / "pymavlink_bridge.py"


def load_bridge():
    spec = importlib.util.spec_from_file_location("vectra_bridge", BRIDGE_PATH)
    module = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(module)
    return module


def free_udp_port() -> int:
    with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as sock:
        sock.bind(("127.0.0.1", 0))
        return int(sock.getsockname()[1])


def read_record(process: subprocess.Popen[str], timeout: float = 5.0):
    selector = selectors.DefaultSelector()
    selector.register(process.stdout, selectors.EVENT_READ)
    deadline = time.monotonic() + timeout
    try:
        while time.monotonic() < deadline:
            events = selector.select(deadline - time.monotonic())
            if not events:
                break
            line = process.stdout.readline()
            if line:
                return json.loads(line)
            if process.poll() is not None:
                break
    finally:
        selector.close()
    raise TimeoutError("Timed out waiting for bridge NDJSON")


class FakeMessage:
    def to_dict(self):
        return {
            "mavpackettype": "ATTITUDE",
            "time_boot_ms": 1250,
            "roll": 0.25,
            "samples": (1, 2),
        }

    def get_type(self):
        return "ATTITUDE"

    def get_srcSystem(self):
        return 7

    def get_srcComponent(self):
        return 1

    def get_seq(self):
        return 42


class BridgeProtocolTests(unittest.TestCase):
    @unittest.skipUnless(mavutil is not None, "PyMAVLink is not installed")
    def test_message_record_matches_vectra_contract(self):
        bridge = load_bridge()
        record = bridge.message_record(FakeMessage(), 100.5)
        self.assertEqual(record["RecordType"], "event")
        self.assertEqual(record["MessageName"], "ATTITUDE")
        self.assertEqual(record["SystemID"], 7)
        self.assertEqual(record["Sequence"], 42)
        self.assertEqual(record["Payload"]["roll"], 0.25)
        self.assertEqual(record["Payload"]["samples"], [1, 2])
        self.assertEqual(record["SourceTimestampUs"], 1_250_000.0)

    def test_bridge_has_no_mavlink_send_calls(self):
        tree = ast.parse(BRIDGE_PATH.read_text(encoding="utf-8"))
        prohibited = []
        for node in ast.walk(tree):
            if isinstance(node, ast.Call):
                function = node.func
                if isinstance(function, ast.Attribute) and (
                    function.attr == "send" or function.attr.endswith("_send")
                ):
                    prohibited.append(function.attr)
        self.assertEqual(prohibited, [])

    @unittest.skipUnless(mavutil is not None, "PyMAVLink is not installed")
    def test_udp_heartbeat_loopback(self):
        port = free_udp_port()
        process = subprocess.Popen(
            [
                sys.executable,
                str(BRIDGE_PATH),
                "--bind",
                "127.0.0.1",
                "--port",
                str(port),
                "--dialect",
                "common",
            ],
            cwd=PROJECT_ROOT,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            bufsize=1,
        )
        self.addCleanup(self._stop_process, process)

        starting = read_record(process)
        listening = read_record(process)
        self.assertEqual(starting["State"], "starting")
        self.assertEqual(listening["State"], "listening")

        sender = mavutil.mavlink_connection(
            f"udpout:127.0.0.1:{port}",
            source_system=23,
            source_component=1,
            dialect="common",
        )
        self.addCleanup(sender.close)
        sender.mav.heartbeat_send(
            mavutil.mavlink.MAV_TYPE_QUADROTOR,
            mavutil.mavlink.MAV_AUTOPILOT_PX4,
            mavutil.mavlink.MAV_MODE_FLAG_SAFETY_ARMED,
            458752,
            mavutil.mavlink.MAV_STATE_ACTIVE,
        )

        record = read_record(process)
        self.assertEqual(record["RecordType"], "event")
        self.assertEqual(record["MessageName"], "HEARTBEAT")
        self.assertEqual(record["SystemID"], 23)
        self.assertEqual(record["ComponentID"], 1)
        self.assertEqual(record["Payload"]["custom_mode"], 458752)

    @staticmethod
    def _stop_process(process: subprocess.Popen[str]):
        if process.poll() is None:
            process.terminate()
            try:
                process.wait(timeout=3)
            except subprocess.TimeoutExpired:
                process.kill()
                process.wait(timeout=3)


if __name__ == "__main__":
    unittest.main()
