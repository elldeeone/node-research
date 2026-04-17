#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import re
from datetime import datetime, timezone
from pathlib import Path

TIMESTAMP_RE = re.compile(r"^(\d{4}/\d{2}/\d{2}-\d{2}:\d{2}:\d{2}\.\d{6})")
STALL_RE = re.compile(r"^(Cumulative|Interval) stall:\s+(\d+):(\d+):(\d+\.\d+)\s+H:M:S,\s+([\d.]+)\s+percent$")
WRITE_STALL_RE = re.compile(r"^Write Stall \(count\):\s+(.*)$")

FIELDNAMES = [
    "timestamp_utc",
    "db_name",
    "source_file",
    "event_type",
    "job",
    "flush_reason",
    "output_level",
    "num_output_files",
    "total_output_size",
    "num_input_records",
    "num_output_records",
    "compaction_time_micros",
    "compaction_time_cpu_micros",
    "stall_scope",
    "stall_seconds",
    "stall_percent",
    "stall_counts_json",
    "lsm_state_json",
    "raw",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Parse tailed RocksDB LOG files into CSV events.")
    parser.add_argument("--input-dir", required=True, help="Directory produced by collect-rocksdb-logs.sh")
    parser.add_argument("--output", required=True, help="Output CSV path")
    return parser.parse_args()


def load_sources(input_dir: Path) -> dict[str, str]:
    manifest = input_dir / "sources.csv"
    if not manifest.exists():
        return {}
    with manifest.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        return {row["output_name"]: row["source_path"] for row in reader}


def format_timestamp(value: str) -> str:
    ts = datetime.strptime(value, "%Y/%m/%d-%H:%M:%S.%f").replace(tzinfo=timezone.utc)
    return ts.isoformat().replace("+00:00", "Z")


def db_name_for(source_path: str, fallback_name: str) -> str:
    if source_path:
        parts = Path(source_path).parts
        if "datadir" in parts:
            datadir_index = parts.index("datadir")
            tail = parts[datadir_index + 1 : -1]
            if tail:
                return "/".join(tail)
    stem = fallback_name[:-4] if fallback_name.endswith(".log") else fallback_name
    return stem.replace("__", "/")


def parse_stall_counts(value: str) -> str:
    counts: dict[str, int] = {}
    for item in value.split(","):
        item = item.strip()
        if not item or ":" not in item:
            continue
        key, raw_value = item.split(":", 1)
        raw_value = raw_value.strip()
        try:
            counts[key.strip()] = int(raw_value)
        except ValueError:
            continue
    return json.dumps(counts, separators=(",", ":"), sort_keys=True)


def iter_log_files(input_dir: Path) -> list[Path]:
    return sorted(path for path in input_dir.iterdir() if path.is_file() and path.name.endswith(".log"))


def parse_file(path: Path, source_path: str) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    db_name = db_name_for(source_path, path.name)
    last_timestamp = ""

    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line in handle:
            raw = line.rstrip("\n")
            if not raw:
                continue

            timestamp_match = TIMESTAMP_RE.match(raw)
            line_body = raw
            row: dict[str, str] = {
                "timestamp_utc": "",
                "db_name": db_name,
                "source_file": path.name,
                "event_type": "",
                "job": "",
                "flush_reason": "",
                "output_level": "",
                "num_output_files": "",
                "total_output_size": "",
                "num_input_records": "",
                "num_output_records": "",
                "compaction_time_micros": "",
                "compaction_time_cpu_micros": "",
                "stall_scope": "",
                "stall_seconds": "",
                "stall_percent": "",
                "stall_counts_json": "",
                "lsm_state_json": "",
                "raw": raw,
            }

            if timestamp_match:
                last_timestamp = format_timestamp(timestamp_match.group(1))
                row["timestamp_utc"] = last_timestamp

            if "EVENT_LOG_v1" in raw:
                _, payload = raw.split("EVENT_LOG_v1", 1)
                event = json.loads(payload.strip())
                row["event_type"] = event.get("event", "event_log")
                row["job"] = str(event.get("job", ""))
                row["flush_reason"] = str(event.get("flush_reason", ""))
                row["output_level"] = str(event.get("output_level", ""))
                row["num_output_files"] = str(event.get("num_output_files", ""))
                row["total_output_size"] = str(event.get("total_output_size", ""))
                row["num_input_records"] = str(event.get("num_input_records", ""))
                row["num_output_records"] = str(event.get("num_output_records", ""))
                row["compaction_time_micros"] = str(event.get("compaction_time_micros", ""))
                row["compaction_time_cpu_micros"] = str(event.get("compaction_time_cpu_micros", ""))
                if "lsm_state" in event:
                    row["lsm_state_json"] = json.dumps(event["lsm_state"], separators=(",", ":"))
                rows.append(row)
                continue

            if not row["timestamp_utc"] and last_timestamp:
                row["timestamp_utc"] = last_timestamp

            stripped = line_body[timestamp_match.end():].strip() if timestamp_match else raw.strip()
            stall_match = STALL_RE.match(stripped)
            if stall_match:
                hours = int(stall_match.group(2))
                minutes = int(stall_match.group(3))
                seconds = float(stall_match.group(4))
                row["event_type"] = "stall_stats"
                row["stall_scope"] = stall_match.group(1).lower()
                row["stall_seconds"] = f"{hours * 3600 + minutes * 60 + seconds:.6f}"
                row["stall_percent"] = stall_match.group(5)
                rows.append(row)
                continue

            write_stall_match = WRITE_STALL_RE.match(stripped)
            if write_stall_match:
                row["event_type"] = "write_stall_counts"
                row["stall_counts_json"] = parse_stall_counts(write_stall_match.group(1))
                rows.append(row)
                continue

    return rows


def main() -> None:
    args = parse_args()
    input_dir = Path(args.input_dir)
    output = Path(args.output)
    sources = load_sources(input_dir)

    rows: list[dict[str, str]] = []
    for path in iter_log_files(input_dir):
        source_path = sources.get(path.name, "")
        rows.extend(parse_file(path, source_path))

    output.parent.mkdir(parents=True, exist_ok=True)
    with output.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=FIELDNAMES)
        writer.writeheader()
        writer.writerows(rows)


if __name__ == "__main__":
    main()
