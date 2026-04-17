#!/usr/bin/env python3
from __future__ import annotations

import argparse
import csv
import json
import math
from datetime import datetime, timezone
from pathlib import Path
from statistics import mean

NODE_COLUMNS = [
    "resident_set_size",
    "virtual_memory_size",
    "fd_num",
    "cpu_usage",
    "disk_io_read_bytes",
    "disk_io_write_bytes",
    "disk_io_read_per_sec",
    "disk_io_write_per_sec",
]

RPC_COLUMNS = [
    "is_synced",
    "info_mempool_size",
    "network_mempool_size",
    "active_peers",
    "node_database_blocks_count",
    "node_database_headers_count",
    "network_tip_hashes_count",
    "network_virtual_parent_hashes_count",
    "network_virtual_daa_score",
    "node_headers_processed_per_sec",
    "node_bodies_processed_per_sec",
    "node_transactions_processed_per_sec",
    "node_mass_processed_per_sec",
    "p2p_bytes_tx_per_sec",
    "p2p_bytes_rx_per_sec",
    "grpc_bytes_tx_per_sec",
    "grpc_bytes_rx_per_sec",
]

RPC_GAUGE_COLUMNS = [
    "is_synced",
    "info_mempool_size",
    "network_mempool_size",
    "active_peers",
    "node_database_blocks_count",
    "node_database_headers_count",
    "network_tip_hashes_count",
    "network_virtual_parent_hashes_count",
    "network_virtual_daa_score",
]

RPC_RATE_COLUMNS = [
    "node_headers_processed_per_sec",
    "node_bodies_processed_per_sec",
    "node_transactions_processed_per_sec",
    "node_mass_processed_per_sec",
    "p2p_bytes_tx_per_sec",
    "p2p_bytes_rx_per_sec",
    "grpc_bytes_tx_per_sec",
    "grpc_bytes_rx_per_sec",
]

RPC_COUNTER_COLUMNS = [
    "node_headers_processed_count",
    "node_bodies_processed_count",
    "node_transactions_processed_count",
    "node_mass_processed_count",
    "p2p_bytes_tx",
    "p2p_bytes_rx",
    "grpc_bytes_tx",
    "grpc_bytes_rx",
]

IOSTAT_COLUMNS = [
    "cpu_iowait_pct",
    "r_s",
    "w_s",
    "rkB_s",
    "wkB_s",
    "r_await_ms",
    "w_await_ms",
    "aqu_sz",
    "util_pct",
]


def parse_timestamp(value: str) -> datetime | None:
    if not value:
        return None
    value = value.strip().replace("Z", "+00:00")
    try:
        ts = datetime.fromisoformat(value)
        if ts.tzinfo is None:
            return ts.replace(tzinfo=timezone.utc)
        return ts
    except ValueError:
        return None


def read_csv(path: Path) -> list[dict[str, str]]:
    with path.open("r", newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def percentile(sorted_values: list[float], q: float) -> float:
    if not sorted_values:
        return 0.0
    index = max(0, math.ceil(q * len(sorted_values)) - 1)
    return sorted_values[index]


def summarize_series(values: list[float]) -> dict[str, float]:
    if not values:
        return {"samples": 0, "min": 0.0, "avg": 0.0, "p95": 0.0, "max": 0.0, "last": 0.0}
    ordered = sorted(values)
    return {
        "samples": float(len(values)),
        "min": min(values),
        "avg": mean(values),
        "p95": percentile(ordered, 0.95),
        "max": max(values),
        "last": values[-1],
    }


def num(row: dict[str, str], column: str) -> float:
    value = row.get(column, "").strip()
    return float(value) if value else 0.0


def floats(rows: list[dict[str, str]], column: str) -> list[float]:
    result: list[float] = []
    for row in rows:
        value = row.get(column, "").strip()
        if value:
            result.append(float(value))
    return result


def summarize_node(rows: list[dict[str, str]]) -> dict[str, dict[str, float]]:
    if not rows:
        return {}
    return {column: summarize_series(floats(rows, column)) for column in NODE_COLUMNS}


def host_derived_rows(rows: list[dict[str, str]]) -> list[dict[str, float]]:
    derived: list[dict[str, float]] = []
    for prev, curr in zip(rows, rows[1:]):
        prev_elapsed = num(prev, "elapsed_sec")
        curr_elapsed = num(curr, "elapsed_sec")
        dt = curr_elapsed - prev_elapsed
        if dt <= 0:
            continue

        prev_idle = num(prev, "cpu_idle_jiffies") + num(prev, "cpu_iowait_jiffies")
        curr_idle = num(curr, "cpu_idle_jiffies") + num(curr, "cpu_iowait_jiffies")
        prev_total = sum(num(prev, key) for key in [
            "cpu_user_jiffies",
            "cpu_nice_jiffies",
            "cpu_system_jiffies",
            "cpu_idle_jiffies",
            "cpu_iowait_jiffies",
            "cpu_irq_jiffies",
            "cpu_softirq_jiffies",
            "cpu_steal_jiffies",
        ])
        curr_total = sum(num(curr, key) for key in [
            "cpu_user_jiffies",
            "cpu_nice_jiffies",
            "cpu_system_jiffies",
            "cpu_idle_jiffies",
            "cpu_iowait_jiffies",
            "cpu_irq_jiffies",
            "cpu_softirq_jiffies",
            "cpu_steal_jiffies",
        ])

        total_delta = curr_total - prev_total
        idle_delta = curr_idle - prev_idle
        cpu_util = 0.0 if total_delta <= 0 else 100.0 * (total_delta - idle_delta) / total_delta
        cpu_iowait_pct = 0.0 if total_delta <= 0 else 100.0 * (num(curr, "cpu_iowait_jiffies") - num(prev, "cpu_iowait_jiffies")) / total_delta
        read_bytes_delta = (num(curr, "disk_read_sectors") - num(prev, "disk_read_sectors")) * 512.0
        write_bytes_delta = (num(curr, "disk_write_sectors") - num(prev, "disk_write_sectors")) * 512.0
        read_ops_delta = num(curr, "disk_reads_completed") - num(prev, "disk_reads_completed")
        write_ops_delta = num(curr, "disk_writes_completed") - num(prev, "disk_writes_completed")
        read_merge_delta = num(curr, "disk_reads_merged") - num(prev, "disk_reads_merged")
        write_merge_delta = num(curr, "disk_writes_merged") - num(prev, "disk_writes_merged")
        read_ms_delta = num(curr, "disk_read_ms") - num(prev, "disk_read_ms")
        write_ms_delta = num(curr, "disk_write_ms") - num(prev, "disk_write_ms")
        io_ms_delta = num(curr, "disk_io_ms") - num(prev, "disk_io_ms")
        io_weighted_ms_delta = num(curr, "disk_io_ms_weighted") - num(prev, "disk_io_ms_weighted")
        discard_bytes_delta = (num(curr, "disk_discard_sectors") - num(prev, "disk_discard_sectors")) * 512.0
        discard_ops_delta = num(curr, "disk_discards_completed") - num(prev, "disk_discards_completed")
        flush_ops_delta = num(curr, "disk_flushes_completed") - num(prev, "disk_flushes_completed")
        discard_ms_delta = num(curr, "disk_discard_ms") - num(prev, "disk_discard_ms")
        flush_ms_delta = num(curr, "disk_flush_ms") - num(prev, "disk_flush_ms")

        derived.append(
            {
                "system_cpu_util_pct": cpu_util,
                "system_cpu_iowait_pct": cpu_iowait_pct,
                "disk_read_bytes_per_sec": read_bytes_delta / dt,
                "disk_write_bytes_per_sec": write_bytes_delta / dt,
                "disk_read_ops_per_sec": read_ops_delta / dt,
                "disk_write_ops_per_sec": write_ops_delta / dt,
                "disk_read_merges_per_sec": read_merge_delta / dt,
                "disk_write_merges_per_sec": write_merge_delta / dt,
                "disk_read_await_ms": 0.0 if read_ops_delta <= 0 else read_ms_delta / read_ops_delta,
                "disk_write_await_ms": 0.0 if write_ops_delta <= 0 else write_ms_delta / write_ops_delta,
                "disk_read_avg_request_bytes": 0.0 if read_ops_delta <= 0 else read_bytes_delta / read_ops_delta,
                "disk_write_avg_request_bytes": 0.0 if write_ops_delta <= 0 else write_bytes_delta / write_ops_delta,
                "disk_avg_queue_depth": io_weighted_ms_delta / (dt * 1000.0),
                "disk_busy_pct": 100.0 * io_ms_delta / (dt * 1000.0),
                "disk_in_flight": num(curr, "disk_io_in_progress"),
                "disk_discard_bytes_per_sec": discard_bytes_delta / dt,
                "disk_discard_ops_per_sec": discard_ops_delta / dt,
                "disk_flush_ops_per_sec": flush_ops_delta / dt,
                "disk_discard_await_ms": 0.0 if discard_ops_delta <= 0 else discard_ms_delta / discard_ops_delta,
                "disk_flush_await_ms": 0.0 if flush_ops_delta <= 0 else flush_ms_delta / flush_ops_delta,
                "net_rx_bytes_per_sec": (num(curr, "net_rx_bytes") - num(prev, "net_rx_bytes")) / dt,
                "net_tx_bytes_per_sec": (num(curr, "net_tx_bytes") - num(prev, "net_tx_bytes")) / dt,
                "proc_read_bytes_per_sec": (num(curr, "proc_read_bytes") - num(prev, "proc_read_bytes")) / dt,
                "proc_write_bytes_per_sec": (num(curr, "proc_write_bytes") - num(prev, "proc_write_bytes")) / dt,
                "storage_used_bytes": num(curr, "storage_used_bytes"),
                "proc_rss_bytes": num(curr, "proc_rss_bytes"),
                "proc_virtual_bytes": num(curr, "proc_virtual_bytes"),
                "proc_fd_count": num(curr, "proc_fd_count"),
                "proc_threads": num(curr, "proc_threads"),
            }
        )
    return derived


def summarize_host(rows: list[dict[str, str]]) -> dict[str, dict[str, float]]:
    derived = host_derived_rows(rows)
    if not derived:
        return {}
    columns = list(derived[0].keys())
    return {column: summarize_series([row[column] for row in derived]) for column in columns}


def successful_rpc_rows(rows: list[dict[str, str]]) -> list[dict[str, str]]:
    return [row for row in rows if row.get("rpc_ok", "").strip() == "1"]


def rpc_derived_rows(rows: list[dict[str, str]]) -> list[dict[str, float]]:
    derived: list[dict[str, float]] = []
    last_success: dict[str, str] | None = None
    for curr in rows:
        if curr.get("rpc_ok", "").strip() != "1":
            last_success = None
            continue

        if last_success is None:
            last_success = curr
            continue

        prev_elapsed = num(last_success, "elapsed_sec")
        curr_elapsed = num(curr, "elapsed_sec")
        dt = curr_elapsed - prev_elapsed
        if dt <= 0:
            last_success = curr
            continue

        if any(num(curr, column) < num(last_success, column) for column in RPC_COUNTER_COLUMNS):
            last_success = curr
            continue

        derived.append(
            {
                "is_synced": num(curr, "is_synced"),
                "info_mempool_size": num(curr, "info_mempool_size"),
                "network_mempool_size": num(curr, "network_mempool_size"),
                "active_peers": num(curr, "active_peers"),
                "node_database_blocks_count": num(curr, "node_database_blocks_count"),
                "node_database_headers_count": num(curr, "node_database_headers_count"),
                "network_tip_hashes_count": num(curr, "network_tip_hashes_count"),
                "network_virtual_parent_hashes_count": num(curr, "network_virtual_parent_hashes_count"),
                "network_virtual_daa_score": num(curr, "network_virtual_daa_score"),
                "node_headers_processed_per_sec": (num(curr, "node_headers_processed_count") - num(last_success, "node_headers_processed_count")) / dt,
                "node_bodies_processed_per_sec": (num(curr, "node_bodies_processed_count") - num(last_success, "node_bodies_processed_count")) / dt,
                "node_transactions_processed_per_sec": (num(curr, "node_transactions_processed_count") - num(last_success, "node_transactions_processed_count")) / dt,
                "node_mass_processed_per_sec": (num(curr, "node_mass_processed_count") - num(last_success, "node_mass_processed_count")) / dt,
                "p2p_bytes_tx_per_sec": (num(curr, "p2p_bytes_tx") - num(last_success, "p2p_bytes_tx")) / dt,
                "p2p_bytes_rx_per_sec": (num(curr, "p2p_bytes_rx") - num(last_success, "p2p_bytes_rx")) / dt,
                "grpc_bytes_tx_per_sec": (num(curr, "grpc_bytes_tx") - num(last_success, "grpc_bytes_tx")) / dt,
                "grpc_bytes_rx_per_sec": (num(curr, "grpc_bytes_rx") - num(last_success, "grpc_bytes_rx")) / dt,
            }
        )
        last_success = curr
    return derived


def summarize_rpc(rows: list[dict[str, str]]) -> dict[str, dict[str, float]]:
    successful_rows = successful_rpc_rows(rows)
    derived = rpc_derived_rows(rows)
    if not successful_rows and not derived:
        return {}

    summary: dict[str, dict[str, float]] = {}
    for column in RPC_GAUGE_COLUMNS:
        values = [num(row, column) for row in successful_rows]
        if values:
            summary[column] = summarize_series(values)
    for column in RPC_RATE_COLUMNS:
        values = [row[column] for row in derived]
        if values:
            summary[column] = summarize_series(values)
    return summary


def summarize_iostat(rows: list[dict[str, str]]) -> dict[str, object]:
    if not rows:
        return {}
    summary: dict[str, object] = {}
    devices = sorted({row.get("device", "").strip() for row in rows if row.get("device", "").strip()})
    if devices:
        summary["devices"] = devices
    for column in IOSTAT_COLUMNS:
        values = floats(rows, column)
        if values:
            summary[column] = summarize_series(values)
    return summary


def summarize_rocksdb(rows: list[dict[str, str]]) -> dict[str, object]:
    if not rows:
        return {}

    event_counts: dict[str, int] = {}
    db_event_counts: dict[str, dict[str, int]] = {}
    for row in rows:
        event_type = row.get("event_type", "").strip()
        db_name = row.get("db_name", "").strip()
        if event_type:
            event_counts[event_type] = event_counts.get(event_type, 0) + 1
            if db_name:
                db_counts = db_event_counts.setdefault(db_name, {})
                db_counts[event_type] = db_counts.get(event_type, 0) + 1

    summary: dict[str, object] = {
        "event_counts": event_counts,
        "db_event_counts": db_event_counts,
    }

    compaction_time_seconds = [num(row, "compaction_time_micros") / 1_000_000.0 for row in rows if row.get("compaction_time_micros", "").strip()]
    if compaction_time_seconds:
        summary["compaction_time_sec"] = summarize_series(compaction_time_seconds)

    compaction_cpu_time_seconds = [num(row, "compaction_time_cpu_micros") / 1_000_000.0 for row in rows if row.get("compaction_time_cpu_micros", "").strip()]
    if compaction_cpu_time_seconds:
        summary["compaction_cpu_time_sec"] = summarize_series(compaction_cpu_time_seconds)

    compaction_output_bytes = [num(row, "total_output_size") for row in rows if row.get("total_output_size", "").strip()]
    if compaction_output_bytes:
        summary["compaction_output_bytes"] = summarize_series(compaction_output_bytes)

    stall_seconds = [num(row, "stall_seconds") for row in rows if row.get("stall_seconds", "").strip()]
    if stall_seconds:
        summary["stall_seconds"] = summarize_series(stall_seconds)

    stall_percent = [num(row, "stall_percent") for row in rows if row.get("stall_percent", "").strip()]
    if stall_percent:
        summary["stall_percent"] = summarize_series(stall_percent)

    return summary


def event_windows(path: Path | None) -> dict[str, tuple[datetime, datetime]]:
    if path is None or not path.exists():
        return {}
    rows = read_csv(path)
    starts: dict[str, datetime] = {}
    counts: dict[str, int] = {}
    windows: dict[str, tuple[datetime, datetime]] = {}
    for row in rows:
        ts = parse_timestamp(row.get("timestamp_utc", ""))
        event_type = row.get("event_type", "")
        if ts is None or not event_type:
            continue
        if event_type.endswith("_start"):
            starts[event_type[:-6]] = ts
        elif event_type.endswith("_end"):
            key = event_type[:-4]
            start = starts.pop(key, None)
            if start is not None and start <= ts:
                counts[key] = counts.get(key, 0) + 1
                label = key if counts[key] == 1 else f"{key}_{counts[key]}"
                windows[label] = (start, ts)
    return windows


def filter_rows_by_window(rows: list[dict[str, str]], start: datetime, end: datetime) -> list[dict[str, str]]:
    filtered: list[dict[str, str]] = []
    for row in rows:
        ts = parse_timestamp(row.get("timestamp_utc", ""))
        if ts is not None and start <= ts <= end:
            filtered.append(row)
    return filtered


def gib(value: float) -> float:
    return value / (1024.0 ** 3)


def mbps(value: float) -> float:
    return value / 1_000_000.0


def kbps(value: float) -> float:
    return value / 1000.0


def load_metadata(path: Path) -> dict:
    return json.loads(path.read_text(encoding="utf-8"))


def write_outputs(outdir: Path, summary: dict) -> None:
    outdir.mkdir(parents=True, exist_ok=True)
    (outdir / "summary.json").write_text(json.dumps(summary, indent=2, sort_keys=True), encoding="utf-8")

    lines = [
        "# Node Resource Summary",
        "",
        f"- Run: `{summary['metadata'].get('run_id', 'unknown')}`",
        f"- Node samples: {summary['node_sample_count']}",
        f"- Host samples: {summary['host_sample_count']}",
        f"- RPC samples: {summary['rpc_sample_count']}",
        f"- Duration seconds: {summary['duration_sec']:.0f}",
        "",
    ]

    node = summary.get("node_metrics", {})
    if node:
        lines.extend(
            [
                "## Highlights",
                "",
                f"- Node RSS max: {gib(node['resident_set_size']['max']):.2f} GiB",
                f"- Node CPU p95/max: {node['cpu_usage']['p95']:.2f} / {node['cpu_usage']['max']:.2f}",
                f"- Node disk read p95/max: {mbps(node['disk_io_read_per_sec']['p95']):.2f} / {mbps(node['disk_io_read_per_sec']['max']):.2f} MB/s",
                f"- Node disk write p95/max: {mbps(node['disk_io_write_per_sec']['p95']):.2f} / {mbps(node['disk_io_write_per_sec']['max']):.2f} MB/s",
                f"- Node FD max: {node['fd_num']['max']:.0f}",
                "",
            ]
        )

    host = summary.get("host_metrics", {})
    if host:
        lines.extend(
            [
                "## Host Derived",
                "",
                f"- Host CPU util p95/max: {host['system_cpu_util_pct']['p95']:.2f}% / {host['system_cpu_util_pct']['max']:.2f}%",
                f"- Host CPU iowait p95/max: {host['system_cpu_iowait_pct']['p95']:.2f}% / {host['system_cpu_iowait_pct']['max']:.2f}%",
                f"- Host disk read p95/max: {mbps(host['disk_read_bytes_per_sec']['p95']):.2f} / {mbps(host['disk_read_bytes_per_sec']['max']):.2f} MB/s",
                f"- Host disk write p95/max: {mbps(host['disk_write_bytes_per_sec']['p95']):.2f} / {mbps(host['disk_write_bytes_per_sec']['max']):.2f} MB/s",
                f"- Host disk read ops p95/max: {host['disk_read_ops_per_sec']['p95']:.2f} / {host['disk_read_ops_per_sec']['max']:.2f} ops/s",
                f"- Host disk write ops p95/max: {host['disk_write_ops_per_sec']['p95']:.2f} / {host['disk_write_ops_per_sec']['max']:.2f} ops/s",
                f"- Host disk read await p95/max: {host['disk_read_await_ms']['p95']:.2f} / {host['disk_read_await_ms']['max']:.2f} ms",
                f"- Host disk write await p95/max: {host['disk_write_await_ms']['p95']:.2f} / {host['disk_write_await_ms']['max']:.2f} ms",
                f"- Host disk queue depth p95/max: {host['disk_avg_queue_depth']['p95']:.2f} / {host['disk_avg_queue_depth']['max']:.2f}",
                f"- Host disk busy p95/max: {host['disk_busy_pct']['p95']:.2f}% / {host['disk_busy_pct']['max']:.2f}%",
                f"- Storage used max: {gib(host['storage_used_bytes']['max']):.2f} GiB",
                "",
            ]
        )

    rpc = summary.get("rpc_metrics", {})
    if rpc:
        lines.append("## Workload")
        lines.append("")
        if "is_synced" in rpc:
            lines.append(f"- RPC synced p95/max: {rpc['is_synced']['p95']:.2f} / {rpc['is_synced']['max']:.2f}")
        if "network_mempool_size" in rpc:
            lines.append(f"- Network mempool p95/max: {rpc['network_mempool_size']['p95']:.2f} / {rpc['network_mempool_size']['max']:.2f}")
        if "active_peers" in rpc:
            lines.append(f"- Active peers p95/max: {rpc['active_peers']['p95']:.2f} / {rpc['active_peers']['max']:.2f}")
        if "node_transactions_processed_per_sec" in rpc:
            lines.append(
                f"- Node tx processed p95/max: {rpc['node_transactions_processed_per_sec']['p95']:.2f} / "
                f"{rpc['node_transactions_processed_per_sec']['max']:.2f} tx/s"
            )
        if "p2p_bytes_rx_per_sec" in rpc:
            lines.append(f"- P2P RX p95/max: {mbps(rpc['p2p_bytes_rx_per_sec']['p95']):.2f} / {mbps(rpc['p2p_bytes_rx_per_sec']['max']):.2f} MB/s")
        lines.append("")

    iostat = summary.get("iostat_metrics", {})
    if iostat:
        lines.extend(["## Iostat Derived", ""])
        if "util_pct" in iostat:
            lines.append(f"- Device util p95/max: {iostat['util_pct']['p95']:.2f}% / {iostat['util_pct']['max']:.2f}%")
        if "aqu_sz" in iostat:
            lines.append(f"- Device queue depth p95/max: {iostat['aqu_sz']['p95']:.2f} / {iostat['aqu_sz']['max']:.2f}")
        if "r_await_ms" in iostat:
            lines.append(f"- Device read await p95/max: {iostat['r_await_ms']['p95']:.2f} / {iostat['r_await_ms']['max']:.2f} ms")
        if "w_await_ms" in iostat:
            lines.append(f"- Device write await p95/max: {iostat['w_await_ms']['p95']:.2f} / {iostat['w_await_ms']['max']:.2f} ms")
        if "rkB_s" in iostat:
            lines.append(f"- Device read throughput p95/max: {kbps(iostat['rkB_s']['p95']):.2f} / {kbps(iostat['rkB_s']['max']):.2f} MB/s")
        if "wkB_s" in iostat:
            lines.append(f"- Device write throughput p95/max: {kbps(iostat['wkB_s']['p95']):.2f} / {kbps(iostat['wkB_s']['max']):.2f} MB/s")
        lines.append("")

    rocksdb = summary.get("rocksdb_metrics", {})
    if rocksdb:
        event_counts = rocksdb.get("event_counts", {})
        lines.extend(
            [
                "## RocksDB",
                "",
                f"- Event rows: {sum(event_counts.values())}",
                f"- Compactions: {event_counts.get('compaction_finished', 0)}",
                f"- Flush starts: {event_counts.get('flush_started', 0)}",
                f"- Flush finishes: {event_counts.get('flush_finished', 0)}",
                f"- Stall stats rows: {event_counts.get('stall_stats', 0)}",
                f"- Write stall rows: {event_counts.get('write_stall_counts', 0)}",
            ]
        )
        if "compaction_time_sec" in rocksdb:
            lines.append(
                f"- Compaction time p95/max: {rocksdb['compaction_time_sec']['p95']:.2f} / {rocksdb['compaction_time_sec']['max']:.2f} s"
            )
        if "stall_percent" in rocksdb:
            lines.append(
                f"- Stall percent p95/max: {rocksdb['stall_percent']['p95']:.2f} / {rocksdb['stall_percent']['max']:.2f}%"
            )
        lines.append("")

    if summary.get("window_metrics"):
        lines.append("## Event Windows")
        lines.append("")
        for name, values in summary["window_metrics"].items():
            window_parts: list[str] = []
            node_metrics = values.get("node", {})
            rpc_metrics = values.get("rpc", {})
            iostat_metrics = values.get("iostat", {})
            rocksdb_metrics = values.get("rocksdb", {})
            if node_metrics:
                window_parts.append(f"node disk write max {mbps(node_metrics['disk_io_write_per_sec']['max']):.2f} MB/s")
            if "util_pct" in iostat_metrics:
                window_parts.append(f"device util max {iostat_metrics['util_pct']['max']:.2f}%")
            if "node_transactions_processed_per_sec" in rpc_metrics:
                window_parts.append(f"tx processed max {rpc_metrics['node_transactions_processed_per_sec']['max']:.2f} tx/s")
            elif "network_mempool_size" in rpc_metrics:
                window_parts.append(f"mempool max {rpc_metrics['network_mempool_size']['max']:.2f}")
            if rocksdb_metrics:
                event_counts = rocksdb_metrics.get("event_counts", {})
                compactions = event_counts.get("compaction_finished", 0)
                stalls = event_counts.get("stall_stats", 0)
                if compactions or stalls:
                    window_parts.append(f"rocksdb compactions {compactions} stalls {stalls}")
            lines.append(f"- {name}: {'; '.join(window_parts)}")
        lines.append("")

    (outdir / "summary.md").write_text("\n".join(lines), encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Summarize node-resource-study CSV artifacts.")
    parser.add_argument("--metadata", required=True)
    parser.add_argument("--node-metrics", required=True)
    parser.add_argument("--host-metrics")
    parser.add_argument("--rpc-metrics")
    parser.add_argument("--iostat-metrics")
    parser.add_argument("--rocksdb-events")
    parser.add_argument("--events")
    parser.add_argument("--outdir", required=True)
    args = parser.parse_args()

    metadata = load_metadata(Path(args.metadata))
    node_rows = read_csv(Path(args.node_metrics))
    host_rows = read_csv(Path(args.host_metrics)) if args.host_metrics else []
    rpc_rows = read_csv(Path(args.rpc_metrics)) if args.rpc_metrics else []
    iostat_rows = read_csv(Path(args.iostat_metrics)) if args.iostat_metrics else []
    rocksdb_rows = read_csv(Path(args.rocksdb_events)) if args.rocksdb_events else []
    windows = event_windows(Path(args.events)) if args.events else {}

    node_metrics = summarize_node(node_rows)
    host_metrics = summarize_host(host_rows)
    rpc_metrics = summarize_rpc(rpc_rows)
    iostat_metrics = summarize_iostat(iostat_rows)
    rocksdb_metrics = summarize_rocksdb(rocksdb_rows)

    started_at = parse_timestamp(metadata.get("started_at_utc", ""))
    ended_at = parse_timestamp(metadata.get("ended_at_utc", ""))
    duration_sec = 0.0
    if started_at and ended_at:
        duration_sec = max(0.0, (ended_at - started_at).total_seconds())
    elif host_rows:
        duration_sec = float(host_rows[-1]["elapsed_sec"])

    window_metrics: dict[str, dict[str, dict[str, dict[str, float]]]] = {}
    for name, (start, end) in windows.items():
        node_window = filter_rows_by_window(node_rows, start, end)
        host_window = filter_rows_by_window(host_rows, start, end)
        rpc_window = filter_rows_by_window(rpc_rows, start, end)
        iostat_window = filter_rows_by_window(iostat_rows, start, end)
        rocksdb_window = filter_rows_by_window(rocksdb_rows, start, end)
        if not node_window and not host_window and not rpc_window and not iostat_window and not rocksdb_window:
            continue
        window_metrics[name] = {
            "node": summarize_node(node_window),
            "host": summarize_host(host_window),
            "rpc": summarize_rpc(rpc_window),
            "iostat": summarize_iostat(iostat_window),
            "rocksdb": summarize_rocksdb(rocksdb_window),
        }

    summary = {
        "generated_at_utc": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
        "metadata": metadata,
        "duration_sec": duration_sec,
        "node_sample_count": len(node_rows),
        "host_sample_count": len(host_rows),
        "rpc_sample_count": len(rpc_rows),
        "iostat_sample_count": len(iostat_rows),
        "rocksdb_event_count": len(rocksdb_rows),
        "node_metrics": node_metrics,
        "host_metrics": host_metrics,
        "rpc_metrics": rpc_metrics,
        "iostat_metrics": iostat_metrics,
        "rocksdb_metrics": rocksdb_metrics,
        "window_metrics": window_metrics,
    }

    write_outputs(Path(args.outdir), summary)


if __name__ == "__main__":
    main()
