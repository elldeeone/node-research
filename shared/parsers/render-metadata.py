#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
import os
import platform
import shutil
import socket
from pathlib import Path


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Render metadata.json for a capture run.")
    parser.add_argument("--output", required=True)
    parser.add_argument("--run-id", required=True)
    parser.add_argument("--run-state", default="unknown")
    parser.add_argument("--collector", default="operator-kit")
    parser.add_argument("--started-at-utc", required=True)
    parser.add_argument("--ended-at-utc", required=True)
    parser.add_argument("--version", default="unknown")
    parser.add_argument("--commit", default="unknown")
    parser.add_argument("--network", default="mainnet")
    parser.add_argument("--node-role", default="pruned")
    parser.add_argument("--utxoindex", action="store_true")
    parser.add_argument("--archival", action="store_true")
    parser.add_argument("--flag", action="append", default=[])
    parser.add_argument("--provider", default="unknown")
    parser.add_argument("--region", default="unknown")
    parser.add_argument("--instance-name")
    parser.add_argument("--cpu-model")
    parser.add_argument("--vcpu")
    parser.add_argument("--memory-gib")
    parser.add_argument("--disk-type", default="unknown")
    parser.add_argument("--disk-device", default="unknown")
    parser.add_argument("--disk-capacity-gib")
    parser.add_argument("--storage-path")
    parser.add_argument("--os")
    parser.add_argument("--load-source", default="unknown")
    parser.add_argument("--traffic-shape", default="unknown")
    parser.add_argument("--payload-profile", default="unknown")
    parser.add_argument("--estimated-tps")
    parser.add_argument("--estimated-bps")
    parser.add_argument("--load-notes", default="")
    parser.add_argument("--notes", default="")
    return parser.parse_args()


def detect_cpu_model() -> str:
    cpuinfo = Path("/proc/cpuinfo")
    if cpuinfo.exists():
        for line in cpuinfo.read_text(encoding="utf-8", errors="replace").splitlines():
            if line.startswith("model name"):
                parts = line.split(":", 1)
                if len(parts) == 2 and parts[1].strip():
                    return parts[1].strip()
    return platform.processor() or "unknown"


def detect_memory_gib() -> float | None:
    meminfo = Path("/proc/meminfo")
    if not meminfo.exists():
        return None
    for line in meminfo.read_text(encoding="utf-8", errors="replace").splitlines():
        if line.startswith("MemTotal:"):
            parts = line.split()
            if len(parts) >= 2:
                return round(int(parts[1]) * 1024 / (1024**3), 2)
    return None


def detect_os() -> str:
    os_release = Path("/etc/os-release")
    if os_release.exists():
        values: dict[str, str] = {}
        for line in os_release.read_text(encoding="utf-8", errors="replace").splitlines():
            if "=" not in line:
                continue
            key, value = line.split("=", 1)
            values[key] = value.strip().strip('"')
        for key in ("PRETTY_NAME", "NAME"):
            if values.get(key):
                return values[key]
    return platform.platform()


def detect_disk_capacity_gib(storage_path: str | None) -> float | None:
    if not storage_path:
        return None
    try:
        total = shutil.disk_usage(storage_path).total
    except FileNotFoundError:
        return None
    return round(total / (1024**3), 2)


def parse_float(value: str | None) -> float | None:
    if value is None or value == "":
        return None
    return float(value)


def parse_int(value: str | None) -> int | None:
    if value is None or value == "":
        return None
    return int(value)


def main() -> None:
    args = parse_args()
    output = Path(args.output)
    output.parent.mkdir(parents=True, exist_ok=True)

    vcpu = parse_int(args.vcpu)
    memory_gib = parse_float(args.memory_gib)
    disk_capacity_gib = parse_float(args.disk_capacity_gib)
    estimated_tps = parse_float(args.estimated_tps)
    estimated_bps = parse_float(args.estimated_bps)

    metadata = {
        "run_id": args.run_id,
        "run_state": args.run_state,
        "collector": args.collector,
        "started_at_utc": args.started_at_utc,
        "ended_at_utc": args.ended_at_utc,
        "node": {
            "version": args.version,
            "commit": args.commit,
            "network": args.network,
            "node_role": args.node_role,
            "utxoindex": args.utxoindex,
            "archival": args.archival,
            "flags": args.flag,
        },
        "host": {
            "provider": args.provider,
            "region": args.region,
            "instance_name": args.instance_name or socket.gethostname(),
            "cpu_model": args.cpu_model or detect_cpu_model(),
            "vcpu": vcpu if vcpu is not None else (os.cpu_count() or 0),
            "memory_gib": memory_gib if memory_gib is not None else detect_memory_gib(),
            "disk_type": args.disk_type,
            "disk_device": args.disk_device,
            "disk_capacity_gib": disk_capacity_gib if disk_capacity_gib is not None else detect_disk_capacity_gib(args.storage_path),
            "os": args.os or detect_os(),
        },
        "load": {
            "source": args.load_source,
            "traffic_shape": args.traffic_shape,
            "payload_profile": args.payload_profile,
            "estimated_tps": estimated_tps,
            "estimated_bps": estimated_bps,
            "notes": args.load_notes,
        },
        "notes": args.notes,
    }

    output.write_text(json.dumps(metadata, indent=2) + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
