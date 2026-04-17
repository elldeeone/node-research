#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
from pathlib import Path

FIELDNAMES = [
    "timestamp_utc",
    "device",
    "cpu_user_pct",
    "cpu_nice_pct",
    "cpu_system_pct",
    "cpu_iowait_pct",
    "cpu_steal_pct",
    "cpu_idle_pct",
    "r_s",
    "w_s",
    "d_s",
    "f_s",
    "rkB_s",
    "wkB_s",
    "dkB_s",
    "rrqm_s",
    "wrqm_s",
    "drqm_s",
    "rrqm_pct",
    "wrqm_pct",
    "drqm_pct",
    "r_await_ms",
    "w_await_ms",
    "d_await_ms",
    "f_await_ms",
    "rareq_sz_kB",
    "wareq_sz_kB",
    "dareq_sz_kB",
    "aqu_sz",
    "util_pct",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Parse JSONL output from collect-iostat.sh into CSV.")
    parser.add_argument("--input", required=True, help="Input JSONL file")
    parser.add_argument("--output", required=True, help="Output CSV path")
    return parser.parse_args()


def value_of(item: dict[str, object], key: str) -> str:
    value = item.get(key, "")
    return "" if value is None else str(value)


def main() -> None:
    args = parse_args()
    input_path = Path(args.input)
    output_path = Path(args.output)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    with input_path.open("r", encoding="utf-8") as src, output_path.open("w", newline="", encoding="utf-8") as dst:
        writer = csv.DictWriter(dst, fieldnames=FIELDNAMES)
        writer.writeheader()

        for line in src:
            line = line.rstrip("\n")
            if not line:
                continue
            timestamp_utc, payload = line.split("\t", 1)
            doc = json.loads(payload)
            for host in doc.get("sysstat", {}).get("hosts", []):
                for stats in host.get("statistics", []):
                    cpu = stats.get("avg-cpu", {})
                    for disk in stats.get("disk", []):
                        writer.writerow(
                            {
                                "timestamp_utc": timestamp_utc,
                                "device": value_of(disk, "disk_device"),
                                "cpu_user_pct": value_of(cpu, "user"),
                                "cpu_nice_pct": value_of(cpu, "nice"),
                                "cpu_system_pct": value_of(cpu, "system"),
                                "cpu_iowait_pct": value_of(cpu, "iowait"),
                                "cpu_steal_pct": value_of(cpu, "steal"),
                                "cpu_idle_pct": value_of(cpu, "idle"),
                                "r_s": value_of(disk, "r/s"),
                                "w_s": value_of(disk, "w/s"),
                                "d_s": value_of(disk, "d/s"),
                                "f_s": value_of(disk, "f/s"),
                                "rkB_s": value_of(disk, "rkB/s"),
                                "wkB_s": value_of(disk, "wkB/s"),
                                "dkB_s": value_of(disk, "dkB/s"),
                                "rrqm_s": value_of(disk, "rrqm/s"),
                                "wrqm_s": value_of(disk, "wrqm/s"),
                                "drqm_s": value_of(disk, "drqm/s"),
                                "rrqm_pct": value_of(disk, "rrqm"),
                                "wrqm_pct": value_of(disk, "wrqm"),
                                "drqm_pct": value_of(disk, "drqm"),
                                "r_await_ms": value_of(disk, "r_await"),
                                "w_await_ms": value_of(disk, "w_await"),
                                "d_await_ms": value_of(disk, "d_await"),
                                "f_await_ms": value_of(disk, "f_await"),
                                "rareq_sz_kB": value_of(disk, "rareq-sz"),
                                "wareq_sz_kB": value_of(disk, "wareq-sz"),
                                "dareq_sz_kB": value_of(disk, "dareq-sz"),
                                "aqu_sz": value_of(disk, "aqu-sz"),
                                "util_pct": value_of(disk, "util"),
                            }
                        )


if __name__ == "__main__":
    main()
