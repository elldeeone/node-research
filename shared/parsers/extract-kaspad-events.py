#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import re
from pathlib import Path

TIMESTAMP_RE = re.compile(
    r"(?P<timestamp>"
    r"\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}(?:[.,]\d+)?(?:Z|[+-]\d{2}:\d{2})?"
    r")"
)

LOG_EVENTS = [
    ("IBD started with peer", "ibd_start", "auto: detected IBD start in kaspad log"),
    ("IBD with peer", "ibd_end", "auto: detected IBD completion in kaspad log"),
    ("Periodic pruning point movement", "pruning_start", "auto: detected pruning movement in kaspad log"),
    ("Updated the pruning point UTXO set", "pruning_end", "auto: detected pruning UTXO update in kaspad log"),
]


def extract_timestamp(line: str) -> str:
    match = TIMESTAMP_RE.search(line)
    if not match:
        return ""
    return match.group("timestamp").replace(" ", "T").replace(",", ".")


def read_csv_rows(path: Path) -> list[dict[str, str]]:
    if not path.exists():
        return []
    with path.open("r", newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def log_events(path: Path) -> list[dict[str, str]]:
    rows: list[dict[str, str]] = []
    with path.open("r", encoding="utf-8", errors="replace") as handle:
        for line in handle:
            timestamp = extract_timestamp(line)
            if not timestamp:
                continue
            for marker, event_type, note in LOG_EVENTS:
                if marker in line:
                    if event_type == "ibd_end" and "completed successfully" not in line:
                        continue
                    rows.append({"timestamp_utc": timestamp, "event_type": event_type, "notes": note})
    return rows


def rpc_events(path: Path) -> list[dict[str, str]]:
    rows = read_csv_rows(path)
    events: list[dict[str, str]] = []
    previous: str | None = None
    for row in rows:
        if row.get("rpc_ok", "").strip() != "1":
            continue
        is_synced = row.get("is_synced", "").strip()
        timestamp = row.get("timestamp_utc", "").strip()
        if not timestamp or is_synced not in {"0", "1"}:
            continue
        if previous is None:
            if is_synced == "1":
                events.append(
                    {
                        "timestamp_utc": timestamp,
                        "event_type": "synced_start",
                        "notes": "auto: first successful RPC sample was synced",
                    }
                )
        elif previous == "0" and is_synced == "1":
            events.append(
                {
                    "timestamp_utc": timestamp,
                    "event_type": "synced_start",
                    "notes": "auto: detected node becoming synced from RPC samples",
                }
            )
        elif previous == "1" and is_synced == "0":
            events.append(
                {
                    "timestamp_utc": timestamp,
                    "event_type": "synced_end",
                    "notes": "auto: detected node leaving synced state from RPC samples",
                }
            )
        previous = is_synced
    return events


def merge_events(existing: list[dict[str, str]], generated: list[dict[str, str]]) -> list[dict[str, str]]:
    merged: list[dict[str, str]] = []
    seen: set[tuple[str, str, str]] = set()
    for row in existing + generated:
        normalized = {
            "timestamp_utc": row.get("timestamp_utc", "").strip(),
            "event_type": row.get("event_type", "").strip(),
            "notes": row.get("notes", "").strip(),
        }
        key = (normalized["timestamp_utc"], normalized["event_type"], normalized["notes"])
        if not normalized["timestamp_utc"] or not normalized["event_type"] or key in seen:
            continue
        seen.add(key)
        merged.append(normalized)
    merged.sort(key=lambda row: (row["timestamp_utc"], row["event_type"], row["notes"]))
    return merged


def write_rows(path: Path, rows: list[dict[str, str]]) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=["timestamp_utc", "event_type", "notes"])
        writer.writeheader()
        writer.writerows(rows)


def main() -> None:
    parser = argparse.ArgumentParser(description="Seed events.csv from kaspad logs and optional RPC samples.")
    parser.add_argument("--log", required=True, help="Path to kaspad.log")
    parser.add_argument("--output", required=True, help="Path to events.csv")
    parser.add_argument("--rpc-metrics", help="Optional path to rpc-metrics.csv")
    parser.add_argument("--existing-events", help="Optional existing events.csv to merge with")
    args = parser.parse_args()

    output_path = Path(args.output)
    existing_path = Path(args.existing_events) if args.existing_events else output_path
    generated = log_events(Path(args.log))
    if args.rpc_metrics:
        generated.extend(rpc_events(Path(args.rpc_metrics)))
    merged = merge_events(read_csv_rows(existing_path), generated)
    write_rows(output_path, merged)


if __name__ == "__main__":
    main()
