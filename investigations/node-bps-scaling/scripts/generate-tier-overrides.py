#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
from dataclasses import dataclass
from pathlib import Path


# Candidate blockrate derivation for node-bps-scaling.
#
# These values are intentionally derived from current upstream blockrate formulas
# in rusty-kaspa's consensus/core config, while keeping the override minimal:
# we emit only the blockrate object and leave the rest of devnet unchanged.
#
# Source references used for this derivation:
# - consensus/core/src/config/bps.rs
# - consensus/core/src/config/constants.rs
# - consensus/core/src/config/params.rs
#
# Important caveat:
# Some nominal BPS values do not divide 1000 cleanly. For those tiers, the
# candidate override uses floor(1000 / nominal_bps) milliseconds because
# target_time_per_block is stored in whole milliseconds.


SCRIPT_DIR = Path(__file__).resolve().parent
INVESTIGATION_ROOT = SCRIPT_DIR.parent
CONFIG_ROOT = INVESTIGATION_ROOT / "configs"
GENERATED_ROOT = CONFIG_ROOT / "generated"
METADATA_PATH = CONFIG_ROOT / "tier-metadata.csv"
VALIDATION_REGISTER_PATH = INVESTIGATION_ROOT / "data" / "manifests" / "tier-validation-register.csv"

MERGE_DEPTH_DURATION = 3_600
FINALITY_DURATION = 43_200
PRUNING_DURATION = 108_000
PAST_MEDIAN_TIME_SAMPLE_INTERVAL = 10
DIFFICULTY_WINDOW_SAMPLE_INTERVAL = 4
COINBASE_MATURITY_SECONDS = 100

GHOSTDAG_K_TABLE = {
    1: 18,
    2: 31,
    3: 43,
    4: 55,
    5: 67,
    6: 79,
    7: 90,
    8: 102,
    9: 113,
    10: 124,
    11: 135,
    12: 146,
    13: 157,
    14: 168,
    15: 179,
    16: 190,
    17: 201,
    18: 212,
    19: 223,
    20: 234,
    21: 244,
    22: 255,
    23: 266,
    24: 277,
    25: 288,
    26: 298,
    27: 309,
    28: 320,
    29: 330,
    30: 341,
    31: 352,
    32: 362,
}


@dataclass(frozen=True)
class Tier:
    nominal_bps: int
    slug: str
    label: str
    is_provisional_max: bool = False


TIERS = [
    Tier(nominal_bps=20, slug="20bps", label="20 BPS"),
    Tier(nominal_bps=25, slug="25bps", label="25 BPS"),
    Tier(nominal_bps=32, slug="max-tier-32bps-31ms-candidate", label="Validated Max Tier Candidate", is_provisional_max=True),
]


def build_blockrate(nominal_bps: int) -> dict[str, int]:
    if nominal_bps not in GHOSTDAG_K_TABLE:
        raise ValueError(f"unsupported nominal BPS: {nominal_bps}")

    k = GHOSTDAG_K_TABLE[nominal_bps]
    target_time_ms = int(1000.0 / nominal_bps)
    max_block_parents = max(10, min(16, k // 2))
    mergeset_size_limit = max(180, min(512, k * 2))
    merge_depth = nominal_bps * MERGE_DEPTH_DURATION
    finality_depth = nominal_bps * FINALITY_DURATION
    pruning_lower_bound = finality_depth + merge_depth * 2 + 4 * mergeset_size_limit * k + 2 * k + 2
    pruning_depth = max(pruning_lower_bound, nominal_bps * PRUNING_DURATION)

    return {
        "target_time_per_block": target_time_ms,
        "ghostdag_k": k,
        "past_median_time_sample_rate": nominal_bps * PAST_MEDIAN_TIME_SAMPLE_INTERVAL,
        "difficulty_sample_rate": nominal_bps * DIFFICULTY_WINDOW_SAMPLE_INTERVAL,
        "max_block_parents": max_block_parents,
        "mergeset_size_limit": mergeset_size_limit,
        "merge_depth": merge_depth,
        "finality_depth": finality_depth,
        "pruning_depth": pruning_depth,
        "coinbase_maturity": nominal_bps * COINBASE_MATURITY_SECONDS,
    }


def real_interval_bps(target_time_ms: int) -> float:
    return 1000.0 / target_time_ms


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate candidate blockrate override files for node-bps-scaling")
    parser.add_argument("--output-dir", type=Path, default=GENERATED_ROOT)
    parser.add_argument("--metadata-path", type=Path, default=METADATA_PATH)
    parser.add_argument("--validation-register-path", type=Path, default=VALIDATION_REGISTER_PATH)
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    args.output_dir.mkdir(parents=True, exist_ok=True)
    args.metadata_path.parent.mkdir(parents=True, exist_ok=True)
    args.validation_register_path.parent.mkdir(parents=True, exist_ok=True)

    metadata_rows: list[dict[str, str | int | float]] = []
    validation_rows: list[dict[str, str | int | float]] = []

    for tier in TIERS:
        blockrate = build_blockrate(tier.nominal_bps)
        target_time_ms = blockrate["target_time_per_block"]
        exact_ms_compatible = 1000 % tier.nominal_bps == 0
        override = {"blockrate": blockrate}
        output_path = args.output_dir / f"{tier.slug}.override.json"
        output_path.write_text(json.dumps(override, indent=2) + "\n", encoding="utf-8")

        metadata_rows.append(
            {
                "tier_slug": tier.slug,
                "tier_label": tier.label,
                "nominal_bps": tier.nominal_bps,
                "target_time_per_block_ms": target_time_ms,
                "integer_reported_bps": 1000 // target_time_ms,
                "real_interval_bps": f"{real_interval_bps(target_time_ms):.6f}",
                "exact_ms_compatible": "yes" if exact_ms_compatible else "no",
                "ghostdag_k": blockrate["ghostdag_k"],
                "past_median_time_sample_rate": blockrate["past_median_time_sample_rate"],
                "difficulty_sample_rate": blockrate["difficulty_sample_rate"],
                "max_block_parents": blockrate["max_block_parents"],
                "mergeset_size_limit": blockrate["mergeset_size_limit"],
                "merge_depth": blockrate["merge_depth"],
                "finality_depth": blockrate["finality_depth"],
                "pruning_depth": blockrate["pruning_depth"],
                "coinbase_maturity": blockrate["coinbase_maturity"],
                "is_provisional_max": "yes" if tier.is_provisional_max else "no",
            }
        )
        validation_rows.append(
            {
                "tier_slug": tier.slug,
                "tier_label": tier.label,
                "candidate_override_file": str(output_path.relative_to(INVESTIGATION_ROOT)),
                "validation_status": "planned",
                "nominal_bps": tier.nominal_bps,
                "target_time_per_block_ms": target_time_ms,
                "integer_reported_bps": 1000 // target_time_ms,
                "real_interval_bps": f"{real_interval_bps(target_time_ms):.6f}",
                "observed_block_rate": "",
                "observed_tps": "",
                "bootstrap_health": "",
                "relay_health": "",
                "single_downstream_smoke": "",
                "eight_downstream_smoke": "",
                "final_report_label": "",
                "notes": "",
            }
        )

    fieldnames = [
        "tier_slug",
        "tier_label",
        "nominal_bps",
        "target_time_per_block_ms",
        "integer_reported_bps",
        "real_interval_bps",
        "exact_ms_compatible",
        "ghostdag_k",
        "past_median_time_sample_rate",
        "difficulty_sample_rate",
        "max_block_parents",
        "mergeset_size_limit",
        "merge_depth",
        "finality_depth",
        "pruning_depth",
        "coinbase_maturity",
        "is_provisional_max",
    ]

    with args.metadata_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(metadata_rows)

    validation_fieldnames = [
        "tier_slug",
        "tier_label",
        "candidate_override_file",
        "validation_status",
        "nominal_bps",
        "target_time_per_block_ms",
        "integer_reported_bps",
        "real_interval_bps",
        "observed_block_rate",
        "observed_tps",
        "bootstrap_health",
        "relay_health",
        "single_downstream_smoke",
        "eight_downstream_smoke",
        "final_report_label",
        "notes",
    ]

    with args.validation_register_path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=validation_fieldnames)
        writer.writeheader()
        writer.writerows(validation_rows)


if __name__ == "__main__":
    main()
