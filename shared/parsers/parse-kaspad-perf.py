#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

PROCESS_RE = re.compile(
    r"process metrics: RAM: (?P<resident_set_size>\d+) \([^)]+\), "
    r"VIRT: (?P<virtual_memory_size>\d+) \([^)]+\), "
    r"FD: (?P<fd_num>\d+), cores: (?P<core_num>\d+), total cpu usage: (?P<cpu_usage>[-+0-9.eE]+)"
)

IO_RE = re.compile(
    r"disk io metrics: read: (?P<disk_io_read_bytes>\d+) \([^)]+\), "
    r"write: (?P<disk_io_write_bytes>\d+) \([^)]+\), "
    r"read rate: (?P<disk_io_read_per_sec>[-+0-9.eE]+) \([^)]+\), "
    r"write rate: (?P<disk_io_write_per_sec>[-+0-9.eE]+) \([^)]+\)"
)

TIMESTAMP_RE = re.compile(
    r"(?P<timestamp>"
    r"\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}(?:[.,]\d+)?(?:Z|[+-]\d{2}:\d{2})?"
    r")"
)

FIELDS = [
    "sample_index",
    "timestamp_utc",
    "process_line_no",
    "io_line_no",
    "resident_set_size",
    "virtual_memory_size",
    "fd_num",
    "core_num",
    "cpu_usage",
    "disk_io_read_bytes",
    "disk_io_write_bytes",
    "disk_io_read_per_sec",
    "disk_io_write_per_sec",
]


def extract_timestamp(line: str) -> str:
    match = TIMESTAMP_RE.search(line)
    if not match:
        return ""
    return match.group("timestamp").replace(" ", "T").replace(",", ".")


def flush_row(rows: list[dict[str, str]], pending: dict[str, str] | None) -> None:
    if pending is None:
        return
    for field in FIELDS:
        pending.setdefault(field, "")
    rows.append(pending)


def parse_file(input_path: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    pending: dict[str, str] | None = None
    sample_index = 0

    with input_path.open("r", encoding="utf-8", errors="replace") as handle:
        for line_no, line in enumerate(handle, start=1):
            process_match = PROCESS_RE.search(line)
            if process_match:
                flush_row(rows, pending)
                sample_index += 1
                pending = {
                    "sample_index": str(sample_index),
                    "timestamp_utc": extract_timestamp(line),
                    "process_line_no": str(line_no),
                    **process_match.groupdict(),
                }
                continue

            io_match = IO_RE.search(line)
            if io_match:
                if pending is None:
                    sample_index += 1
                    pending = {
                        "sample_index": str(sample_index),
                        "timestamp_utc": extract_timestamp(line),
                    }
                pending["io_line_no"] = str(line_no)
                pending.update(io_match.groupdict())
                flush_row(rows, pending)
                pending = None

    flush_row(rows, pending)
    return rows


def write_rows(output_path: Path, rows: list[dict[str, str]]) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDS)
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description="Parse kaspad perf-monitor log lines into CSV.")
    parser.add_argument("--input", required=True, help="Path to kaspad log file")
    parser.add_argument("--output", required=True, help="Path to output CSV")
    args = parser.parse_args()

    rows = parse_file(Path(args.input))
    write_rows(Path(args.output), rows)


if __name__ == "__main__":
    main()
