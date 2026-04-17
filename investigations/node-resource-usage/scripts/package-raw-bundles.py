#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import hashlib
import tarfile
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
INVESTIGATION_ROOT = SCRIPT_DIR.parent
REPO_ROOT = INVESTIGATION_ROOT.parent.parent
DEFAULT_MANIFEST = INVESTIGATION_ROOT / "data" / "manifests" / "raw-bundles.csv"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Package raw run directories into release tarballs and update raw-bundles.csv"
    )
    parser.add_argument("--source-root", type=Path, required=True, help="Root directory containing per-run folders")
    parser.add_argument("--out-dir", type=Path, required=True, help="Directory to write tar.gz bundles into")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST, help="raw-bundles.csv path")
    parser.add_argument("--run-id", action="append", default=[], help="Specific run id to package; repeatable")
    parser.add_argument("--only-missing", action="store_true", help="Only package rows whose status is not local-bundle-ready/released")
    parser.add_argument("--dry-run", action="store_true", help="Show actions without writing bundles or manifest")
    return parser.parse_args()


def read_manifest(path: Path) -> tuple[list[dict[str, str]], list[str]]:
    with path.open("r", newline="", encoding="utf-8") as handle:
        reader = csv.DictReader(handle)
        rows = list(reader)
        fieldnames = reader.fieldnames or []
    return rows, fieldnames


def write_manifest(path: Path, rows: list[dict[str, str]], fieldnames: list[str]) -> None:
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)


def sha256sum(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        for chunk in iter(lambda: handle.read(1024 * 1024), b""):
            digest.update(chunk)
    return digest.hexdigest()


def should_select(row: dict[str, str], selected_runs: set[str], only_missing: bool) -> bool:
    run_id = row["run_id"]
    if selected_runs and run_id not in selected_runs:
        return False
    if not only_missing:
        return True
    return row.get("status", "") not in {"local-bundle-ready", "released"}


def repo_relative_or_absolute(path: Path) -> str:
    try:
        return str(path.resolve().relative_to(REPO_ROOT.resolve()))
    except ValueError:
        return str(path.resolve())


def build_bundle(source_dir: Path, bundle_path: Path) -> None:
    bundle_path.parent.mkdir(parents=True, exist_ok=True)
    with tarfile.open(bundle_path, "w:gz") as archive:
        archive.add(source_dir, arcname=source_dir.name)


def main() -> int:
    args = parse_args()
    rows, fieldnames = read_manifest(args.manifest)
    selected_runs = set(args.run_id)

    changed = False
    packaged = 0

    for row in rows:
        if not should_select(row, selected_runs, args.only_missing):
            continue

        run_id = row["run_id"]
        asset_name = row["asset_name"]
        source_dir = args.source_root / run_id
        bundle_path = args.out_dir / asset_name

        if not source_dir.is_dir():
            print(f"skip {run_id}: source dir missing at {source_dir}")
            continue

        print(f"package {run_id} -> {bundle_path}")

        if not args.dry_run:
            build_bundle(source_dir, bundle_path)
            row["local_source_path"] = repo_relative_or_absolute(bundle_path)
            row["sha256"] = sha256sum(bundle_path)
            row["size_bytes"] = str(bundle_path.stat().st_size)
            if row.get("status", "") != "released":
                row["status"] = "local-bundle-ready"
            if not row.get("notes"):
                row["notes"] = "local bundle exists but is not uploaded to Releases"
            changed = True
            packaged += 1

    if args.dry_run:
        return 0

    if changed:
        write_manifest(args.manifest, rows, fieldnames)
        print(f"updated manifest: {args.manifest}")
        print(f"packaged bundles: {packaged}")
    else:
        print("no manifest changes")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
