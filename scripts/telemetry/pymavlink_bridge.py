#!/usr/bin/env python3
"""Passive PX4 MAVLink-to-NDJSON bridge for VECTRA.

Stdout is a machine-readable NDJSON protocol. Diagnostics use stderr. This
module intentionally contains no MAVLink send, command, mission, parameter
write, or actuator APIs.
"""

from __future__ import annotations

import argparse
import importlib.metadata
import json
import math
import os
import signal
import sys
import time
from datetime import datetime, timezone
from typing import Any

os.environ.setdefault("MAVLINK20", "1")

from pymavlink import mavutil  # noqa: E402


SCHEMA_VERSION = "1.0.0"
_running = True


def utc_iso(unix_sec: float) -> str:
    """Return an ISO-8601 UTC timestamp with millisecond precision."""
    return (
        datetime.fromtimestamp(unix_sec, tz=timezone.utc)
        .isoformat(timespec="milliseconds")
        .replace("+00:00", "Z")
    )


def json_value(value: Any) -> Any:
    """Convert PyMAVLink and array scalar values to strict JSON values."""
    if value is None or isinstance(value, (str, bool, int)):
        return value
    if isinstance(value, float):
        return value if math.isfinite(value) else None
    if isinstance(value, bytes):
        return list(value)
    if isinstance(value, (list, tuple)):
        return [json_value(item) for item in value]
    if isinstance(value, dict):
        return {str(key): json_value(item) for key, item in value.items()}
    if hasattr(value, "item"):
        return json_value(value.item())
    return str(value)


def source_timestamp_us(payload: dict[str, Any]) -> float | None:
    """Extract a vehicle timestamp without pretending boot time is UTC."""
    if payload.get("time_usec") is not None:
        return float(payload["time_usec"])
    if payload.get("time_boot_ms") is not None:
        return float(payload["time_boot_ms"]) * 1000.0
    return None


def message_record(message: Any, received_unix_sec: float) -> dict[str, Any]:
    """Convert a decoded PyMAVLink message to the VECTRA event contract."""
    payload = dict(message.to_dict())
    payload.pop("mavpackettype", None)
    payload = json_value(payload)
    return {
        "RecordType": "event",
        "SchemaVersion": SCHEMA_VERSION,
        "MessageName": str(message.get_type()).upper(),
        "Payload": payload,
        "SystemID": int(message.get_srcSystem()),
        "ComponentID": int(message.get_srcComponent()),
        "Sequence": int(message.get_seq()),
        "ReceivedUnixSec": received_unix_sec,
        "ReceivedAtUtc": utc_iso(received_unix_sec),
        "SourceType": "physical",
        "SourceTimestampUs": source_timestamp_us(payload),
    }


def status_record(state: str, detail: str, **extra: Any) -> dict[str, Any]:
    """Build a status record for the MATLAB process adapter."""
    unix_sec = time.time()
    record = {
        "RecordType": "status",
        "SchemaVersion": SCHEMA_VERSION,
        "State": state,
        "Detail": detail,
        "UnixSec": unix_sec,
        "AtUtc": utc_iso(unix_sec),
    }
    record.update({key: json_value(value) for key, value in extra.items()})
    return record


def emit(record: dict[str, Any]) -> None:
    """Write exactly one compact JSON record to stdout."""
    sys.stdout.write(
        json.dumps(record, separators=(",", ":"), allow_nan=False) + "\n"
    )
    sys.stdout.flush()


def _stop(_signum: int, _frame: Any) -> None:
    global _running
    _running = False


def receive(args: argparse.Namespace) -> int:
    """Run the passive UDP receive loop."""
    version = importlib.metadata.version("pymavlink")
    emit(
        status_record(
            "starting",
            "PyMAVLink bridge starting",
            PyMavlinkVersion=version,
            Dialect=args.dialect,
            LocalPort=args.port,
        )
    )

    try:
        connection = mavutil.mavlink_connection(
            f"udpin:{args.bind}:{args.port}",
            dialect=args.dialect,
            source_system=255,
            source_component=190,
            autoreconnect=True,
            robust_parsing=True,
        )
    except Exception as exc:
        emit(status_record("error", f"Cannot open UDP listener: {exc}"))
        return 2

    emit(
        status_record(
            "listening",
            f"PyMAVLink listening on UDP {args.bind}:{args.port}",
            PyMavlinkVersion=version,
            Dialect=args.dialect,
            LocalPort=args.port,
        )
    )

    bad_data_count = 0
    try:
        while _running:
            try:
                message = connection.recv_match(blocking=True, timeout=0.5)
            except Exception as exc:
                emit(status_record("warning", f"MAVLink receive error: {exc}"))
                time.sleep(0.1)
                continue
            if message is None:
                continue
            if message.get_type() == "BAD_DATA":
                bad_data_count += 1
                if bad_data_count == 1 or bad_data_count % 100 == 0:
                    emit(
                        status_record(
                            "warning",
                            "Malformed or checksum-invalid MAVLink data ignored",
                            BadDataCount=bad_data_count,
                        )
                    )
                continue
            try:
                emit(message_record(message, time.time()))
            except Exception as exc:
                print(
                    f"Could not serialize {message.get_type()}: {exc}",
                    file=sys.stderr,
                    flush=True,
                )
    finally:
        try:
            connection.close()
        except Exception:
            pass

    emit(status_record("stopped", "PyMAVLink bridge stopped"))
    return 0


def parse_args(argv: list[str] | None = None) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Passive PX4 MAVLink-to-NDJSON bridge"
    )
    parser.add_argument("--bind", default="127.0.0.1")
    parser.add_argument("--port", type=int, default=14551)
    parser.add_argument("--dialect", default="common")
    parser.add_argument(
        "--version",
        action="store_true",
        help="Print the installed PyMAVLink version as JSON and exit",
    )
    return parser.parse_args(argv)


def main(argv: list[str] | None = None) -> int:
    args = parse_args(argv)
    if args.version:
        emit(
            status_record(
                "ready",
                "PyMAVLink import succeeded",
                PyMavlinkVersion=importlib.metadata.version("pymavlink"),
            )
        )
        return 0

    signal.signal(signal.SIGINT, _stop)
    signal.signal(signal.SIGTERM, _stop)
    return receive(args)


if __name__ == "__main__":
    raise SystemExit(main())
