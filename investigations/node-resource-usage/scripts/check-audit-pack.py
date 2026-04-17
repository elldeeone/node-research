#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
INVESTIGATION_ROOT = SCRIPT_DIR.parent
DEFAULT_MANIFEST = INVESTIGATION_ROOT / "data" / "manifests" / "run-register.csv"
DATA_ROOT = INVESTIGATION_ROOT / "data"

BASE_REQUIRED = [
    "metadata.json",
    "summary.md",
    "events.csv",
    "SHA256SUMS",
]

OPTIONAL_NOTES = [
    "summary.json",
    "findings.md",
    "failure-note.md",
    "oom-evidence.md",
    "oom-journal.txt",
]

TIMESERIES_REQUIRED = [
    "host-metrics.csv.gz",
    "node-metrics.csv.gz",
    "rpc-metrics.csv.gz",
    "iostat-metrics.csv.gz",
]


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Validate the investigation audit-pack layout")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST, help="run-register.csv path")
    return parser.parse_args()


def expected_dir(tier: str, run_id: str) -> Path:
    bucket = "runs" if tier == "report" else "supporting"
    return DATA_ROOT / bucket / run_id


def read_rows(path: Path) -> list[dict[str, str]]:
    with path.open("r", newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def main() -> int:
    args = parse_args()
    rows = read_rows(args.manifest)

    missing = False

    for row in rows:
        run_id = row["run_id"]
        tier = row["tier"]
        audit_pack = row["audit_pack"]
        run_dir = expected_dir(tier, run_id)

        if not run_dir.is_dir():
            print(f"missing dir: {run_dir}")
            missing = True
            continue

        required = list(BASE_REQUIRED)
        if audit_pack == "docs-plus-timeseries":
            required.extend(TIMESERIES_REQUIRED)

        for name in required:
            if not (run_dir / name).is_file():
                print(f"missing file: {run_dir / name}")
                missing = True

        if not (run_dir / "summary.json").is_file():
            print(f"note: summary.json absent: {run_dir / 'summary.json'}")

    if missing:
        return 1

    print("audit pack looks complete for the current manifest")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
