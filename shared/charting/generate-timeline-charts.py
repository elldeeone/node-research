#!/usr/bin/env python3
from __future__ import annotations

import argparse
import json
from pathlib import Path

import matplotlib.pyplot as plt
import pandas as pd
from matplotlib.patches import Patch


DEFAULT_PHASE_COLOURS = {
    "ibd": "#fde68a",
    "synced": "#bbf7d0",
    "pruning": "#fecaca",
}
PHASE_ALPHA = 0.35


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate timeline charts from an investigation config")
    parser.add_argument("--config", type=Path, required=True, help="JSON config path")
    parser.add_argument("--chart", action="append", default=[], help="Specific chart key to render; repeatable")
    parser.add_argument("--max-points", type=int, default=4000, help="Maximum downsampled points per panel")
    return parser.parse_args()


def read_config(path: Path) -> dict:
    with path.open("r", encoding="utf-8") as handle:
        return json.load(handle)


def resolve_path(base: Path, value: str) -> Path:
    path = Path(value)
    if path.is_absolute():
        return path
    return (base / path).resolve()


def parse_ts(value: str):
    try:
        return pd.to_datetime(value.strip(), utc=True)
    except Exception:
        return pd.NaT


def open_csv(path: Path) -> pd.DataFrame:
    if path.suffix == ".gz":
        return pd.read_csv(path, compression="gzip", low_memory=False)
    return pd.read_csv(path, low_memory=False)


def resolve_run_file(runs_root: Path, run_dir: str, basename: str) -> Path | None:
    run_path = runs_root / run_dir
    csv_path = run_path / basename
    gz_path = run_path / f"{basename}.gz"
    if csv_path.exists():
        return csv_path
    if gz_path.exists():
        return gz_path
    return None


def load_metric_csvs(runs_root: Path, dirs: list[str], basename: str) -> pd.DataFrame:
    frames: list[pd.DataFrame] = []
    for run_dir in dirs:
        path = resolve_run_file(runs_root, run_dir, basename)
        if path is None:
            continue
        df = open_csv(path)
        df["timestamp"] = pd.to_datetime(df["timestamp_utc"], utc=True)
        frames.append(df)

    if not frames:
        return pd.DataFrame()

    combined = pd.concat(frames, ignore_index=True)
    combined.sort_values("timestamp", inplace=True)
    combined.drop_duplicates(subset=["timestamp"], keep="first", inplace=True)
    return combined


def load_rpc_metrics(runs_root: Path, dirs: list[str]) -> pd.DataFrame:
    combined = load_metric_csvs(runs_root, dirs, "rpc-metrics.csv")
    if combined.empty:
        return combined

    if "node_transactions_processed_count" in combined.columns:
        dt = combined["timestamp"].diff().dt.total_seconds()
        dtx = combined["node_transactions_processed_count"].diff()
        combined["tps"] = (dtx / dt).clip(lower=0)
        combined.loc[combined.index[0], "tps"] = 0

    return combined


def load_rocksdb_stall(runs_root: Path, dirs: list[str]) -> pd.DataFrame:
    frames: list[pd.DataFrame] = []
    for run_dir in dirs:
        path = resolve_run_file(runs_root, run_dir, "rocksdb-events.csv")
        if path is None:
            continue
        df = open_csv(path)
        stall = df[(df["event_type"] == "stall_stats") & (df["stall_scope"] == "interval")].copy()
        if stall.empty:
            continue
        stall["timestamp"] = pd.to_datetime(stall["timestamp_utc"], utc=True)
        stall["stall_pct"] = pd.to_numeric(stall["stall_percent"], errors="coerce").fillna(0)
        frames.append(stall[["timestamp", "stall_pct"]])

    if not frames:
        return pd.DataFrame()

    combined = pd.concat(frames, ignore_index=True)
    combined.sort_values("timestamp", inplace=True)
    combined.drop_duplicates(subset=["timestamp"], keep="first", inplace=True)
    return combined


def load_events(runs_root: Path, dirs: list[str]) -> list[dict]:
    events: list[dict] = []
    for run_dir in dirs:
        path = resolve_run_file(runs_root, run_dir, "events.csv")
        if path is None:
            continue
        df = open_csv(path)
        for _, row in df.iterrows():
            timestamp = parse_ts(row["timestamp_utc"])
            if pd.notna(timestamp):
                events.append(
                    {
                        "timestamp": timestamp,
                        "event_type": row["event_type"],
                        "notes": row.get("notes", ""),
                    }
                )

    events.sort(key=lambda event: event["timestamp"])
    return events


def derive_phases(events: list[dict], t_start, t_end) -> list[tuple[float, float, str]]:
    phases: list[tuple[float, float, str]] = []
    first_synced = None
    prune_windows: list[dict[str, object]] = []

    for event in events:
        if event["event_type"] == "synced_start" and first_synced is None:
            first_synced = event["timestamp"]
        if event["event_type"] == "pruning_start":
            prune_windows.append({"start": event["timestamp"], "end": None})
        if event["event_type"] == "pruning_end" and prune_windows and prune_windows[-1]["end"] is None:
            prune_windows[-1]["end"] = event["timestamp"]

    for window in prune_windows:
        if window["end"] is None:
            window["end"] = t_end

    if first_synced and first_synced > t_start:
        phases.append((t_start, first_synced, "ibd"))

    synced_start = first_synced if first_synced else t_start
    for window in prune_windows:
        if window["start"] > synced_start:
            phases.append((synced_start, window["start"], "synced"))
        phases.append((window["start"], window["end"], "pruning"))
        synced_start = window["end"]

    if synced_start and synced_start < t_end:
        if not prune_windows or synced_start >= prune_windows[-1]["end"]:
            phases.append((synced_start, t_end, "synced"))

    return phases


def downsample(series: pd.Series, timestamps: pd.Series, max_points: int) -> tuple[pd.Series, pd.Series]:
    mask = series.notna()
    series = series[mask].reset_index(drop=True)
    timestamps = timestamps[mask].reset_index(drop=True)

    count = len(series)
    if count == 0:
        return pd.Series(dtype=float), pd.Series(dtype=float)
    if count <= max_points:
        return timestamps, series

    window = max(1, count // max(1, max_points // 2))
    ts_out: list[object] = []
    vals_out: list[float] = []
    for index in range(0, count, window):
        chunk = series.iloc[index : index + window]
        chunk_ts = timestamps.iloc[index : index + window]
        if chunk.empty:
            continue
        min_idx = chunk.values.argmin()
        max_idx = chunk.values.argmax()
        order = [min_idx, max_idx] if min_idx <= max_idx else [max_idx, min_idx]
        for item in order:
            ts_out.append(chunk_ts.iloc[item])
            vals_out.append(chunk.iloc[item])

    return pd.Series(ts_out), pd.Series(vals_out, dtype=float)


def panel_definitions(node: pd.DataFrame, iostat: pd.DataFrame, rpc: pd.DataFrame, rocksdb: pd.DataFrame) -> list[tuple[str, str, str, str | None]]:
    panels: list[tuple[str, str, str, str | None]] = []

    if not rpc.empty:
        panels.extend(
            [
                ("Processed tx/s", "tps", "#16a34a", "rpc"),
                ("Active peers", "active_peers", "#9333ea", "rpc"),
                ("Mempool size", "network_mempool_size", "#ca8a04", "rpc"),
            ]
        )

    panels.extend(
        [
            ("RSS (GiB)", "rss_gib", "#2563eb", None),
            ("CPU (cores)", "cpu_usage", "#dc2626", None),
            ("File descriptors", "fd_num", "#059669", None),
            ("Disk read (MB/s)", "read_mb_s", "#0284c7", None),
            ("Disk write (MB/s)", "write_mb_s", "#7c3aed", None),
        ]
    )

    if not iostat.empty:
        panels.extend(
            [
                ("CPU iowait (%)", "cpu_iowait_pct", "#b45309", "iostat"),
                ("Read await (ms)", "r_await_ms", "#0369a1", "iostat"),
                ("Write await (ms)", "w_await_ms", "#ea580c", "iostat"),
                ("Device util (%)", "util_pct", "#4f46e5", "iostat"),
                ("Device queue depth", "aqu_sz", "#0891b2", "iostat"),
            ]
        )

    if not rocksdb.empty:
        panels.append(("RocksDB stall (%)", "stall_pct", "#be123c", "rocksdb"))

    return panels


def source_for_panel(source: str | None, node: pd.DataFrame, iostat: pd.DataFrame, rpc: pd.DataFrame, rocksdb: pd.DataFrame) -> pd.DataFrame:
    if source == "iostat":
        return iostat
    if source == "rpc":
        return rpc
    if source == "rocksdb":
        return rocksdb
    return node


def generate_chart(
    chart: dict,
    runs_root: Path,
    figures_out: Path,
    charts_out: Path,
    phase_colours: dict[str, str],
    max_points: int,
) -> None:
    key = chart["key"]
    dirs = chart["dirs"]
    label = chart["label"]
    filename = chart["filename"]

    print(f"\nGenerating {key}...")

    node = load_metric_csvs(runs_root, dirs, "node-metrics.csv")
    iostat = load_metric_csvs(runs_root, dirs, "iostat-metrics.csv")
    rpc = load_rpc_metrics(runs_root, dirs)
    rocksdb = load_rocksdb_stall(runs_root, dirs)
    events = load_events(runs_root, dirs)

    if node.empty:
        print(f"  No node metrics found for {key}, skipping")
        return

    t_start = node["timestamp"].min()
    t_end = node["timestamp"].max()
    phases = derive_phases(events, t_start, t_end)

    node["rss_gib"] = node["resident_set_size"] / (1024**3)
    node["read_mb_s"] = node["disk_io_read_per_sec"] / (1024**2)
    node["write_mb_s"] = node["disk_io_write_per_sec"] / (1024**2)
    node["elapsed_h"] = (node["timestamp"] - t_start).dt.total_seconds() / 3600

    for frame in (iostat, rpc, rocksdb):
        if not frame.empty:
            frame["elapsed_h"] = (frame["timestamp"] - t_start).dt.total_seconds() / 3600

    panels = panel_definitions(node, iostat, rpc, rocksdb)
    fig, axes = plt.subplots(len(panels), 1, figsize=(14, 2.8 * len(panels)), sharex=True, dpi=150)
    if len(panels) == 1:
        axes = [axes]

    phase_bands = []
    for phase_start, phase_end, phase_name in phases:
        start_hours = (phase_start - t_start).total_seconds() / 3600
        end_hours = (phase_end - t_start).total_seconds() / 3600
        phase_bands.append((start_hours, end_hours, phase_name))

    for axis, (ylabel, column, colour, source) in zip(axes, panels):
        for start_hours, end_hours, phase_name in phase_bands:
            axis.axvspan(
                start_hours,
                end_hours,
                color=phase_colours.get(phase_name, "#e5e7eb"),
                alpha=PHASE_ALPHA,
                zorder=0,
            )

        source_frame = source_for_panel(source, node, iostat, rpc, rocksdb)
        if column not in source_frame.columns:
            axis.set_ylabel(ylabel, fontsize=9)
            axis.text(0.5, 0.5, "no data", transform=axis.transAxes, ha="center", va="center", fontsize=10, color="#9ca3af")
            continue

        elapsed, values = downsample(
            source_frame[column].reset_index(drop=True),
            source_frame["elapsed_h"].reset_index(drop=True),
            max_points=max_points,
        )
        axis.plot(elapsed, values, color=colour, linewidth=0.5, alpha=0.85)
        axis.set_ylabel(ylabel, fontsize=9)
        axis.tick_params(labelsize=8)
        axis.grid(True, alpha=0.2)

        if column == "tps":
            tps_cap = 10000
            raw_max = values.max() if len(values) > 0 else 0
            if raw_max > tps_cap:
                axis.set_ylim(0, tps_cap)
                axis.annotate(
                    f"IBD peak: {raw_max:,.0f} tx/s",
                    xy=(0.02, 0.92),
                    xycoords="axes fraction",
                    fontsize=7,
                    color="#666666",
                    bbox=dict(boxstyle="round,pad=0.3", facecolor="white", alpha=0.8),
                )

    total_hours = (t_end - t_start).total_seconds() / 3600
    axes[-1].set_xlabel(f"Elapsed time (hours) - total {total_hours:.1f}h", fontsize=9)
    axes[-1].set_xlim(0, total_hours)

    legend = [
        Patch(facecolor=phase_colours["ibd"], alpha=PHASE_ALPHA + 0.15, label="IBD"),
        Patch(facecolor=phase_colours["synced"], alpha=PHASE_ALPHA + 0.15, label="Synced"),
        Patch(facecolor=phase_colours["pruning"], alpha=PHASE_ALPHA + 0.15, label="Pruning"),
    ]
    axes[0].legend(handles=legend, loc="upper right", fontsize=8, framealpha=0.7, ncol=3)

    fig.suptitle(label, fontsize=11, fontweight="bold", y=0.995)
    fig.tight_layout(rect=[0, 0, 1, 0.985])

    figures_out.mkdir(parents=True, exist_ok=True)
    charts_out.mkdir(parents=True, exist_ok=True)

    png_out = figures_out / f"{filename}.png"
    svg_out = charts_out / f"{filename}.svg"
    fig.savefig(png_out, bbox_inches="tight")
    fig.savefig(svg_out, bbox_inches="tight")
    print(f"  Saved {png_out.name}")
    print(f"  Saved {svg_out.name}")
    plt.close(fig)


def main() -> int:
    args = parse_args()
    config_path = args.config.resolve()
    config_dir = config_path.parent
    config = read_config(config_path)

    runs_root = resolve_path(config_dir, config["runs_root"])
    figures_out = resolve_path(config_dir, config["figures_out"])
    charts_out = resolve_path(config_dir, config["charts_out"])
    phase_colours = dict(DEFAULT_PHASE_COLOURS)
    phase_colours.update(config.get("phase_colours", {}))

    chart_map = {chart["key"]: chart for chart in config["charts"]}
    selected = args.chart or list(chart_map)
    missing = [key for key in selected if key not in chart_map]
    if missing:
        raise SystemExit(f"unknown chart key(s): {', '.join(missing)}")

    for key in selected:
        generate_chart(chart_map[key], runs_root, figures_out, charts_out, phase_colours, args.max_points)

    print("\nDone.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
