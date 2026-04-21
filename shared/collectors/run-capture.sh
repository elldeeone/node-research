#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PARSERS_DIR="$REPO_ROOT/shared/parsers"
SCHEMAS_DIR="$REPO_ROOT/shared/schemas"
RUNS_DIR="$SCRIPT_DIR/runs"
BUNDLES_DIR="$SCRIPT_DIR/bundles"

MONITOR_FLAGS=(
  "--utxoindex"
  "--perf-metrics"
  "--perf-metrics-interval-sec=1"
  "--loglevel=info,kaspad_lib::daemon=debug,kaspa_mining::monitor=debug"
)

usage() {
  cat <<'EOF'
Usage:
  shared/collectors/run-capture.sh [options]

Purpose:
  operator-friendly wrapper around the node-resource-usage kit

Examples:
  shared/collectors/run-capture.sh \
    --journalctl-unit kaspad \
    --data-dir ~/.rusty-kaspa \
    --duration-sec 21600 \
    --provider hetzner \
    --region hel1 \
    --load-source kaspadrome \
    --traffic-shape "wallet churn"

  shared/collectors/run-capture.sh \
    --log-file /var/log/kaspad/kaspad.log \
    --data-dir ~/.rusty-kaspa

  shared/collectors/run-capture.sh --print-kaspad-flags

Required operator prep:
  1. run kaspad with the monitoring flags printed by --print-kaspad-flags
  2. usually nothing else; log source auto-detect tries systemd first, then common file paths

Options:
  --run-id ID                 run id; default capture-<utc timestamp>
  --run-state STATE           metadata only; default unknown
  --rpc-url URL               default grpc://127.0.0.1:16110
  --data-dir PATH             kaspad storage root; default ~/.rusty-kaspa
  --network NAME              metadata + db-root detection; default mainnet
  --pid PID                   kaspad pid; default auto-detect
  --disk-device DEVICE        block device for host stats; default auto-detect
  --db-root PATH              RocksDB root; default auto-detect from data dir
  --log-file PATH             tail kaspad log file for the capture window; default auto-detect
  --journalctl-unit UNIT      follow journald unit for the capture window; default auto-detect
  --duration-sec N            0 means run until Ctrl-C; default 0
  --sample-interval-sec N     host + RPC sampling cadence; default 1
  --provider NAME             metadata only; default unknown
  --region NAME               metadata only; default unknown
  --instance-name NAME        metadata only; default hostname
  --load-source NAME          metadata only; default unknown
  --traffic-shape TEXT        metadata only; default unknown
  --payload-profile TEXT      metadata only; default unknown
  --estimated-tps N           metadata only
  --estimated-bps N           metadata only
  --load-notes TEXT           metadata only
  --notes TEXT                metadata only
  --disk-type TYPE            metadata only; default unknown
  --archival                  metadata only; include --archival in flags
  --auto-rollover-on-sync     if current run reaches is_synced=1, close it and start a second run automatically
  --post-sync-run-state STATE rollover target run state; default synced-stress
  --post-sync-run-id ID       rollover target run id; default derived from current run id
  --auto-rollover-on-prune    if current run hits pruning_start in kaspad logs, close it and start a second run automatically
  --post-prune-run-state STATE rollover target run state; default synced-stress-pruning
  --post-prune-run-id ID      rollover target run id; default derived from current run id
  --no-iostat                 skip iostat collector even if available
  --no-rocksdb                skip RocksDB LOG collector
  --print-kaspad-flags        print required kaspad flags and exit
  -h, --help                  show help
EOF
}

print_monitor_flags() {
  printf '%s\n' "${MONITOR_FLAGS[*]}"
}

fail() {
  printf 'run-capture: %s\n' "$*" >&2
  exit 1
}

note() {
  printf 'run-capture: %s\n' "$*"
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing required command: $1"
}

resolve_rpc_poller_command() {
  local candidate
  local candidates=(
    "$SCRIPT_DIR/rpc-poller/target/debug/node-resource-rpc-poller"
    "$SCRIPT_DIR/rpc-poller/target/release/node-resource-rpc-poller"
  )

  if candidate="$(command -v node-resource-rpc-poller 2>/dev/null || true)"; then
    if [[ -n "$candidate" ]]; then
      candidates+=("$candidate")
    fi
  fi

  for candidate in "${candidates[@]}"; do
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
  done

  printf 'cargo\n'
}

resolve_path() {
  local path="$1"
  if [[ -d "$path" ]]; then
    (cd "$path" && pwd -P)
  else
    local parent
    parent="$(dirname "$path")"
    local base
    base="$(basename "$path")"
    (cd "$parent" && printf '%s/%s\n' "$(pwd -P)" "$base")
  fi
}

detect_kaspad_pid() {
  mapfile -t pids < <(pgrep -x kaspad || true)
  if [[ "${#pids[@]}" -eq 1 ]]; then
    printf '%s\n' "${pids[0]}"
    return
  fi
  if [[ "${#pids[@]}" -eq 0 ]]; then
    fail "could not auto-detect kaspad pid; pass --pid"
  fi
  fail "multiple kaspad pids found; pass --pid"
}

detect_disk_device() {
  local path="$1"
  local source_device
  source_device="$(df -P "$path" | awk 'NR==2 { print $1 }')"
  [[ -n "$source_device" ]] || fail "could not detect filesystem device for $path; pass --disk-device"
  if [[ "$source_device" != /dev/* ]]; then
    fail "filesystem source $source_device is not a block device; pass --disk-device"
  fi
  local parent_device
  parent_device="$(lsblk -no PKNAME "$source_device" 2>/dev/null | head -n 1 || true)"
  if [[ -n "$parent_device" ]]; then
    printf '%s\n' "$parent_device"
    return
  fi
  basename "$source_device"
}

detect_db_root() {
  local data_dir="$1"
  local network="$2"
  if [[ -d "$data_dir/kaspa-$network/datadir" ]]; then
    printf '%s\n' "$data_dir/kaspa-$network/datadir"
    return
  fi

  mapfile -t matches < <(find "$data_dir" -maxdepth 3 -type d -name datadir 2>/dev/null | sort)
  if [[ "${#matches[@]}" -eq 1 ]]; then
    printf '%s\n' "${matches[0]}"
    return
  fi
  printf '%s\n' ""
}

detect_log_file() {
  local data_dir="$1"
  local network="$2"
  local candidates=(
    "$data_dir/kaspa-$network/logs/rusty-kaspa.log"
    "$data_dir/kaspa-$network/logs/kaspad.log"
    "$data_dir/logs/rusty-kaspa.log"
    "$data_dir/logs/kaspad.log"
    "/var/log/kaspad/rusty-kaspa.log"
    "/var/log/kaspad/kaspad.log"
    "/var/log/rusty-kaspa.log"
    "/var/log/kaspad.log"
  )

  local candidate
  for candidate in "${candidates[@]}"; do
    if [[ -f "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return
    fi
  done

  printf '%s\n' ""
}

first_successful_rpc_field() {
  local csv_path="$1"
  local field="$2"
  python3 - "$csv_path" "$field" <<'PY'
import csv
import sys

path, field = sys.argv[1], sys.argv[2]
try:
    with open(path, newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            if row.get("rpc_ok", "").strip() == "1" and row.get(field, "").strip():
                print(row[field].strip())
                break
except FileNotFoundError:
    pass
PY
}

latest_successful_rpc_snapshot() {
  local csv_path="$1"
  python3 - "$csv_path" <<'PY'
import csv
import sys

path = sys.argv[1]
try:
    with open(path, newline="", encoding="utf-8") as handle:
        latest = None
        for row in csv.DictReader(handle):
            if row.get("rpc_ok", "").strip() == "1":
                latest = row
        if latest is not None:
            print(f"{latest.get('timestamp_utc', '').strip()},{latest.get('is_synced', '').strip()}")
except FileNotFoundError:
    pass
PY
}

derive_post_run_id() {
  local current_run_id="$1"
  local current_run_state="$2"
  local post_run_state="$3"
  if [[ -n "$current_run_state" && "$current_run_id" == *"$current_run_state"* ]]; then
    printf '%s\n' "${current_run_id/$current_run_state/$post_run_state}"
    return
  fi
  printf '%s\n' "${current_run_id}-${post_run_state}"
}

detect_log_marker_after_offset() {
  local log_path="$1"
  local start_offset="$2"
  local marker="$3"
  python3 - "$log_path" "$start_offset" "$marker" <<'PY'
import re
import sys
from pathlib import Path

TIMESTAMP_RE = re.compile(
    r"(?P<timestamp>"
    r"\d{4}-\d{2}-\d{2}[ T]\d{2}:\d{2}:\d{2}(?:[.,]\d+)?(?:Z|[+-]\d{2}:\d{2})?"
    r")"
)

path = Path(sys.argv[1])
start_offset = int(sys.argv[2])
marker = sys.argv[3]

try:
    with path.open("rb") as handle:
        handle.seek(start_offset)
        next_offset = start_offset
        timestamp = ""
        while True:
            raw_line = handle.readline()
            if not raw_line:
                break
            next_offset = handle.tell()
            line = raw_line.decode("utf-8", errors="replace")
            if marker not in line:
                continue
            match = TIMESTAMP_RE.search(line)
            if match:
                timestamp = match.group("timestamp").replace(" ", "T").replace(",", ".")
            break
        print(f"{timestamp},{next_offset}")
except FileNotFoundError:
    pass
PY
}

wait_for_rollover_capture_ready() {
  local run_dir="$1"
  local capture_pid="$2"
  local deadline_epoch="$(( $(date +%s) + 30 ))"
  while true; do
    if [[ -f "$run_dir/rpc-poller.log" || -f "$run_dir/host-metrics.csv" || -f "$run_dir/kaspad.log" ]]; then
      return 0
    fi
    if ! kill -0 "$capture_pid" 2>/dev/null; then
      return 1
    fi
    if [[ "$(date +%s)" -ge "$deadline_epoch" ]]; then
      return 1
    fi
    sleep 1
  done
}

finalize_run_artifacts() {
  note "parsing kaspad perf log"
  python3 "$PARSERS_DIR/parse-kaspad-perf.py" --input "$KASPAD_LOG" --output "$NODE_METRICS"

  if [[ -s "$IOSTAT_JSONL" ]]; then
    note "parsing iostat json"
    python3 "$PARSERS_DIR/parse-iostat-json.py" --input "$IOSTAT_JSONL" --output "$IOSTAT_METRICS"
  fi

  if [[ -d "$ROCKSDB_DIR" && -f "$ROCKSDB_DIR/sources.csv" ]]; then
    note "parsing RocksDB logs"
    python3 "$PARSERS_DIR/parse-rocksdb-logs.py" --input-dir "$ROCKSDB_DIR" --output "$ROCKSDB_EVENTS"
  fi

  note "extracting events"
  EVENT_ARGS=(
    --log "$KASPAD_LOG"
    --output "$RUN_DIR/events.csv"
  )
  if [[ -f "$RPC_METRICS" ]]; then
    EVENT_ARGS+=(--rpc-metrics "$RPC_METRICS")
  else
    note "rpc metrics missing; events will be log-only"
  fi
  python3 "$PARSERS_DIR/extract-kaspad-events.py" "${EVENT_ARGS[@]}"

  NODE_VERSION="$(first_successful_rpc_field "$RPC_METRICS" "server_version")"
  if [[ -z "$NODE_VERSION" ]]; then
    NODE_VERSION="unknown"
  fi

  GIT_COMMIT="$(git -C "$REPO_ROOT" rev-parse HEAD 2>/dev/null || true)"
  if [[ -z "$GIT_COMMIT" ]]; then
    GIT_COMMIT="unknown"
  fi

  NODE_ROLE="pruned"
  if [[ "$ARCHIVAL" -eq 1 ]]; then
    NODE_ROLE="archival"
  fi

  METADATA_ARGS=(
    --output "$METADATA_JSON"
    --run-id "$RUN_ID"
    --run-state "$RUN_STATE"
    --collector "operator-kit"
    --started-at-utc "$STARTED_AT_UTC"
    --ended-at-utc "$ENDED_AT_UTC"
    --version "$NODE_VERSION"
    --commit "$GIT_COMMIT"
    --network "$NETWORK"
    --node-role "$NODE_ROLE"
    --utxoindex
    --provider "$PROVIDER"
    --region "$REGION"
    --storage-path "$DATA_DIR"
    --disk-type "$DISK_TYPE"
    --disk-device "$DISK_DEVICE"
    --load-source "$LOAD_SOURCE"
    --traffic-shape "$TRAFFIC_SHAPE"
    --payload-profile "$PAYLOAD_PROFILE"
    --load-notes "$LOAD_NOTES"
    --notes "$NOTES"
  )

  if [[ -n "$INSTANCE_NAME" ]]; then
    METADATA_ARGS+=(--instance-name "$INSTANCE_NAME")
  fi
  if [[ -n "$ESTIMATED_TPS" ]]; then
    METADATA_ARGS+=(--estimated-tps "$ESTIMATED_TPS")
  fi
  if [[ -n "$ESTIMATED_BPS" ]]; then
    METADATA_ARGS+=(--estimated-bps "$ESTIMATED_BPS")
  fi
  if [[ "$ARCHIVAL" -eq 1 ]]; then
    METADATA_ARGS+=(--archival)
  fi
  for flag in "${MONITOR_FLAGS[@]}"; do
    METADATA_ARGS+=("--flag=$flag")
  done
  if [[ "$ARCHIVAL" -eq 1 ]]; then
    METADATA_ARGS+=("--flag=--archival")
  fi

  note "rendering metadata"
  python3 "$PARSERS_DIR/render-metadata.py" "${METADATA_ARGS[@]}"

  SUMMARY_ARGS=(
    --metadata "$METADATA_JSON"
    --node-metrics "$NODE_METRICS"
    --host-metrics "$HOST_METRICS"
    --events "$RUN_DIR/events.csv"
    --outdir "$RUN_DIR"
  )

  if [[ -f "$RPC_METRICS" ]]; then
    SUMMARY_ARGS+=(--rpc-metrics "$RPC_METRICS")
  else
    note "rpc metrics missing; summary will omit rpc section"
  fi
  if [[ -f "$IOSTAT_METRICS" ]]; then
    SUMMARY_ARGS+=(--iostat-metrics "$IOSTAT_METRICS")
  fi
  if [[ -f "$ROCKSDB_EVENTS" ]]; then
    SUMMARY_ARGS+=(--rocksdb-events "$ROCKSDB_EVENTS")
  fi

  note "summarizing run"
  python3 "$PARSERS_DIR/summarize-study.py" "${SUMMARY_ARGS[@]}"

  note "writing checksums"
  sha256_files "$RUN_DIR"

  note "building bundle"
  tar -C "$RUNS_DIR" -czf "$BUNDLE_PATH" "$RUN_ID"

  note "done"
  note "bundle: $BUNDLE_PATH"
  note "summary: $RUN_DIR/summary.md"
}

prepare_rollover_args() {
  NEXT_RUN_ID=""
  NEXT_RUN_STATE=""
  NEXT_ROLLOVER_NOTE=""
  NEXT_ARGS=()

  case "$ROLLOVER_REASON" in
    sync)
      NEXT_RUN_ID="$POST_SYNC_RUN_ID"
      NEXT_RUN_STATE="$POST_SYNC_RUN_STATE"
      NEXT_ROLLOVER_NOTE="auto-rolled from ${RUN_ID} on sync at ${ROLLOVER_AT_UTC}"
      ;;
    prune)
      NEXT_RUN_ID="$POST_PRUNE_RUN_ID"
      NEXT_RUN_STATE="$POST_PRUNE_RUN_STATE"
      NEXT_ROLLOVER_NOTE="auto-rolled from ${RUN_ID} on pruning_start at ${ROLLOVER_AT_UTC}"
      ;;
    *)
      fail "unknown rollover reason: ${ROLLOVER_REASON:-unset}"
      ;;
  esac
  if [[ -z "$NEXT_RUN_ID" ]]; then
    NEXT_RUN_ID="$(derive_post_run_id "$RUN_ID" "$RUN_STATE" "$NEXT_RUN_STATE")"
  fi

  NEXT_DURATION_SEC=0
  if [[ "$DURATION_SEC" -gt 0 ]]; then
    NEXT_DURATION_SEC="$((DURATION_SEC - ROLLOVER_ELAPSED_SEC))"
    if [[ "$NEXT_DURATION_SEC" -le 0 ]]; then
      note "no remaining duration for post-rollover run; skipping automatic rollover launch"
      return 1
    fi
  fi

  NEXT_NOTES="$NOTES"
  if [[ -n "$NEXT_NOTES" ]]; then
    NEXT_NOTES="$NEXT_NOTES "
  fi
  NEXT_NOTES="${NEXT_NOTES}${NEXT_ROLLOVER_NOTE}"

  NEXT_ARGS=(
    --run-id "$NEXT_RUN_ID"
    --run-state "$NEXT_RUN_STATE"
    --rpc-url "$RPC_URL"
    --data-dir "$DATA_DIR"
    --network "$NETWORK"
    --pid "$PID"
    --disk-device "$DISK_DEVICE"
    --duration-sec "$NEXT_DURATION_SEC"
    --sample-interval-sec "$SAMPLE_INTERVAL_SEC"
    --provider "$PROVIDER"
    --region "$REGION"
    --load-source "$LOAD_SOURCE"
    --traffic-shape "$TRAFFIC_SHAPE"
    --payload-profile "$PAYLOAD_PROFILE"
    --load-notes "$LOAD_NOTES"
    --notes "$NEXT_NOTES"
    --disk-type "$DISK_TYPE"
  )

  if [[ -n "$INSTANCE_NAME" ]]; then
    NEXT_ARGS+=(--instance-name "$INSTANCE_NAME")
  fi
  if [[ -n "$DB_ROOT" ]]; then
    NEXT_ARGS+=(--db-root "$DB_ROOT")
  fi
  if [[ -n "$LOG_FILE" ]]; then
    NEXT_ARGS+=(--log-file "$LOG_FILE")
  fi
  if [[ -n "$JOURNALCTL_UNIT" ]]; then
    NEXT_ARGS+=(--journalctl-unit "$JOURNALCTL_UNIT")
  fi
  if [[ -n "$ESTIMATED_TPS" ]]; then
    NEXT_ARGS+=(--estimated-tps "$ESTIMATED_TPS")
  fi
  if [[ -n "$ESTIMATED_BPS" ]]; then
    NEXT_ARGS+=(--estimated-bps "$ESTIMATED_BPS")
  fi
  if [[ "$ARCHIVAL" -eq 1 ]]; then
    NEXT_ARGS+=(--archival)
  fi
  if [[ "$ENABLE_IOSTAT" -eq 0 ]]; then
    NEXT_ARGS+=(--no-iostat)
  fi
  if [[ "$ENABLE_ROCKSDB" -eq 0 ]]; then
    NEXT_ARGS+=(--no-rocksdb)
  fi
  if [[ "$ROLLOVER_REASON" == "sync" && "$AUTO_ROLLOVER_ON_PRUNE" -eq 1 ]]; then
    NEXT_ARGS+=(--auto-rollover-on-prune --post-prune-run-state "$POST_PRUNE_RUN_STATE")
    if [[ -n "$POST_PRUNE_RUN_ID" ]]; then
      NEXT_ARGS+=(--post-prune-run-id "$POST_PRUNE_RUN_ID")
    fi
  fi

  return 0
}

sha256_files() {
  local target_dir="$1"
  (
    cd "$target_dir"
    : > SHA256SUMS
    while IFS= read -r rel_path; do
      sha256sum "$rel_path" >> SHA256SUMS
    done < <(find . -type f ! -name 'SHA256SUMS' -printf '%P\n' | sort)
  )
}

declare -a CHILD_PIDS=()
CLEANED_UP=0
STOP_REQUESTED=0

cleanup_children() {
  if [[ "$CLEANED_UP" -eq 1 ]]; then
    return
  fi
  CLEANED_UP=1
  for pid in "${CHILD_PIDS[@]:-}"; do
    if kill -0 "$pid" 2>/dev/null; then
      kill "$pid" 2>/dev/null || true
    fi
  done
  for pid in "${CHILD_PIDS[@]:-}"; do
    wait "$pid" 2>/dev/null || true
  done
}

trap 'STOP_REQUESTED=1' INT TERM
trap cleanup_children EXIT

RUN_ID="capture-$(date -u +%Y-%m-%dT%H-%M-%SZ)"
RUN_STATE="unknown"
RPC_URL="grpc://127.0.0.1:16110"
DATA_DIR="$HOME/.rusty-kaspa"
NETWORK="mainnet"
PID=""
DISK_DEVICE=""
DB_ROOT=""
LOG_FILE=""
JOURNALCTL_UNIT=""
DURATION_SEC=0
SAMPLE_INTERVAL_SEC=1
PROVIDER="unknown"
REGION="unknown"
INSTANCE_NAME=""
LOAD_SOURCE="unknown"
TRAFFIC_SHAPE="unknown"
PAYLOAD_PROFILE="unknown"
ESTIMATED_TPS=""
ESTIMATED_BPS=""
LOAD_NOTES=""
NOTES=""
DISK_TYPE="unknown"
ARCHIVAL=0
ENABLE_IOSTAT=1
ENABLE_ROCKSDB=1
AUTO_ROLLOVER_ON_SYNC=0
POST_SYNC_RUN_STATE="synced-stress"
POST_SYNC_RUN_ID=""
AUTO_ROLLOVER_ON_PRUNE=0
POST_PRUNE_RUN_STATE="synced-stress-pruning"
POST_PRUNE_RUN_ID=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --run-id)
      RUN_ID="$2"
      shift 2
      ;;
    --run-state)
      RUN_STATE="$2"
      shift 2
      ;;
    --rpc-url)
      RPC_URL="$2"
      shift 2
      ;;
    --data-dir)
      DATA_DIR="$2"
      shift 2
      ;;
    --network)
      NETWORK="$2"
      shift 2
      ;;
    --pid)
      PID="$2"
      shift 2
      ;;
    --disk-device)
      DISK_DEVICE="$2"
      shift 2
      ;;
    --db-root)
      DB_ROOT="$2"
      shift 2
      ;;
    --log-file)
      LOG_FILE="$2"
      shift 2
      ;;
    --journalctl-unit)
      JOURNALCTL_UNIT="$2"
      shift 2
      ;;
    --duration-sec)
      DURATION_SEC="$2"
      shift 2
      ;;
    --sample-interval-sec)
      SAMPLE_INTERVAL_SEC="$2"
      shift 2
      ;;
    --provider)
      PROVIDER="$2"
      shift 2
      ;;
    --region)
      REGION="$2"
      shift 2
      ;;
    --instance-name)
      INSTANCE_NAME="$2"
      shift 2
      ;;
    --load-source)
      LOAD_SOURCE="$2"
      shift 2
      ;;
    --traffic-shape)
      TRAFFIC_SHAPE="$2"
      shift 2
      ;;
    --payload-profile)
      PAYLOAD_PROFILE="$2"
      shift 2
      ;;
    --estimated-tps)
      ESTIMATED_TPS="$2"
      shift 2
      ;;
    --estimated-bps)
      ESTIMATED_BPS="$2"
      shift 2
      ;;
    --load-notes)
      LOAD_NOTES="$2"
      shift 2
      ;;
    --notes)
      NOTES="$2"
      shift 2
      ;;
    --disk-type)
      DISK_TYPE="$2"
      shift 2
      ;;
    --archival)
      ARCHIVAL=1
      shift
      ;;
    --auto-rollover-on-sync)
      AUTO_ROLLOVER_ON_SYNC=1
      shift
      ;;
    --post-sync-run-state)
      POST_SYNC_RUN_STATE="$2"
      shift 2
      ;;
    --post-sync-run-id)
      POST_SYNC_RUN_ID="$2"
      shift 2
      ;;
    --auto-rollover-on-prune)
      AUTO_ROLLOVER_ON_PRUNE=1
      shift
      ;;
    --post-prune-run-state)
      POST_PRUNE_RUN_STATE="$2"
      shift 2
      ;;
    --post-prune-run-id)
      POST_PRUNE_RUN_ID="$2"
      shift 2
      ;;
    --no-iostat)
      ENABLE_IOSTAT=0
      shift
      ;;
    --no-rocksdb)
      ENABLE_ROCKSDB=0
      shift
      ;;
    --print-kaspad-flags)
      print_monitor_flags
      exit 0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown arg: $1"
      ;;
  esac
done

[[ "$(uname -s)" == "Linux" ]] || fail "Linux only"
require_cmd python3
require_cmd cargo
require_cmd tar
require_cmd sha256sum
require_cmd pgrep
require_cmd df
require_cmd lsblk

DATA_DIR="$(resolve_path "$DATA_DIR")"
[[ -d "$DATA_DIR" ]] || fail "data dir not found: $DATA_DIR"

if [[ -n "$LOG_FILE" && -n "$JOURNALCTL_UNIT" ]]; then
  fail "pass only one of --log-file or --journalctl-unit"
fi

if [[ -z "$LOG_FILE" && -z "$JOURNALCTL_UNIT" ]]; then
  if command -v systemctl >/dev/null 2>&1 && command -v journalctl >/dev/null 2>&1; then
    if systemctl is-active --quiet kaspad 2>/dev/null; then
      JOURNALCTL_UNIT="kaspad"
    fi
  fi
fi

if [[ -z "$LOG_FILE" && -z "$JOURNALCTL_UNIT" ]]; then
  LOG_FILE="$(detect_log_file "$DATA_DIR" "$NETWORK")"
fi

if [[ -z "$LOG_FILE" && -z "$JOURNALCTL_UNIT" ]]; then
  fail "could not auto-detect journald or log file; pass --journalctl-unit or --log-file"
fi

if [[ -n "$JOURNALCTL_UNIT" ]]; then
  require_cmd journalctl
fi

if [[ -z "$PID" ]]; then
  PID="$(detect_kaspad_pid)"
fi

[[ -d "/proc/$PID" ]] || fail "pid $PID is not running"

if [[ -z "$DISK_DEVICE" ]]; then
  DISK_DEVICE="$(detect_disk_device "$DATA_DIR")"
fi

if [[ -z "$DB_ROOT" && "$ENABLE_ROCKSDB" -eq 1 ]]; then
  DB_ROOT="$(detect_db_root "$DATA_DIR" "$NETWORK")"
fi

mkdir -p "$RUNS_DIR" "$BUNDLES_DIR"
RUN_DIR="$RUNS_DIR/$RUN_ID"
mkdir -p "$RUN_DIR"

cp "$SCHEMAS_DIR/events.template.csv" "$RUN_DIR/events.csv"
printf '%s\n' "${MONITOR_FLAGS[@]}" > "$RUN_DIR/monitor-flags.txt"
if [[ "$ARCHIVAL" -eq 1 ]]; then
  printf '%s\n' "--archival" >> "$RUN_DIR/monitor-flags.txt"
fi

STARTED_AT_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
KASPAD_LOG="$RUN_DIR/kaspad.log"
HOST_METRICS="$RUN_DIR/host-metrics.csv"
RPC_METRICS="$RUN_DIR/rpc-metrics.csv"
IOSTAT_JSONL="$RUN_DIR/iostat.jsonl"
IOSTAT_METRICS="$RUN_DIR/iostat-metrics.csv"
ROCKSDB_DIR="$RUN_DIR/rocksdb-logs"
ROCKSDB_EVENTS="$RUN_DIR/rocksdb-events.csv"
NODE_METRICS="$RUN_DIR/node-metrics.csv"
METADATA_JSON="$RUN_DIR/metadata.json"
BUNDLE_PATH="$BUNDLES_DIR/$RUN_ID.tar.gz"

note "run dir: $RUN_DIR"
note "monitor flags: ${MONITOR_FLAGS[*]}"
note "kaspad pid: $PID"
note "disk device: $DISK_DEVICE"

if [[ -n "$LOG_FILE" ]]; then
  LOG_FILE="$(resolve_path "$LOG_FILE")"
  [[ -f "$LOG_FILE" ]] || fail "log file not found: $LOG_FILE"
  note "capturing log from file: $LOG_FILE"
  tail -n 0 -F "$LOG_FILE" >> "$KASPAD_LOG" &
  CHILD_PIDS+=("$!")
else
  note "capturing log from journald unit: $JOURNALCTL_UNIT"
  journalctl -u "$JOURNALCTL_UNIT" --since "$STARTED_AT_UTC" -f -o short-iso --no-pager >> "$KASPAD_LOG" &
  CHILD_PIDS+=("$!")
fi

note "starting host collector"
"$SCRIPT_DIR/collect-host-stats.sh" \
  --pid "$PID" \
  --disk-device "$DISK_DEVICE" \
  --storage-path "$DATA_DIR" \
  --out "$HOST_METRICS" \
  --interval-sec "$SAMPLE_INTERVAL_SEC" \
  --duration-sec "$DURATION_SEC" &
CHILD_PIDS+=("$!")

note "starting rpc collector"
RPC_POLLER_CMD="$(resolve_rpc_poller_command)"
if [[ "$RPC_POLLER_CMD" == "cargo" ]]; then
  cargo run --manifest-path "$SCRIPT_DIR/rpc-poller/Cargo.toml" -- \
    --url "$RPC_URL" \
    --out "$RPC_METRICS" \
    --interval-sec "$SAMPLE_INTERVAL_SEC" \
    --duration-sec "$DURATION_SEC" \
    >> "$RUN_DIR/rpc-poller.log" 2>&1 &
else
  note "using rpc poller binary: $RPC_POLLER_CMD"
  "$RPC_POLLER_CMD" \
    --url "$RPC_URL" \
    --out "$RPC_METRICS" \
    --interval-sec "$SAMPLE_INTERVAL_SEC" \
    --duration-sec "$DURATION_SEC" \
    >> "$RUN_DIR/rpc-poller.log" 2>&1 &
fi
CHILD_PIDS+=("$!")

if [[ "$ENABLE_IOSTAT" -eq 1 ]]; then
  if command -v iostat >/dev/null 2>&1; then
    note "starting iostat collector"
    "$SCRIPT_DIR/collect-iostat.sh" \
      --device "$DISK_DEVICE" \
      --pid "$PID" \
      --duration-sec "$DURATION_SEC" \
      --out "$IOSTAT_JSONL" &
    CHILD_PIDS+=("$!")
  else
    note "skipping iostat collector; iostat not installed"
  fi
fi

if [[ "$ENABLE_ROCKSDB" -eq 1 ]]; then
  if [[ -n "$DB_ROOT" && -d "$DB_ROOT" ]]; then
    note "starting RocksDB LOG collector: $DB_ROOT"
    "$SCRIPT_DIR/collect-rocksdb-logs.sh" \
      --db-root "$DB_ROOT" \
      --outdir "$ROCKSDB_DIR" \
      --pid "$PID" \
      --duration-sec "$DURATION_SEC" &
    CHILD_PIDS+=("$!")
  else
    note "skipping RocksDB LOG collector; db root not found"
  fi
fi

if [[ "$DURATION_SEC" -gt 0 ]]; then
  note "capture window: $DURATION_SEC seconds"
else
  note "capture window: until Ctrl-C"
fi

start_epoch="$(date +%s)"
ROLLOVER_TRIGGERED=0
ROLLOVER_AT_UTC=""
ROLLOVER_ELAPSED_SEC=0
last_rollover_probe_epoch="$start_epoch"
SYNC_ROLLOVER_ARMED=0
PRUNE_LOG_SCAN_OFFSET=0
PRUNING_START_MARKER="Periodic pruning point movement"
ROLLOVER_REASON=""
PRUNE_ROLLOVER_DISABLED=0
while [[ "$STOP_REQUESTED" -eq 0 ]]; do
  if [[ ! -d "/proc/$PID" ]]; then
    note "kaspad pid exited; stopping capture"
    break
  fi
  if [[ "$DURATION_SEC" -gt 0 ]]; then
    now_epoch="$(date +%s)"
    elapsed_sec="$((now_epoch - start_epoch))"
    if [[ "$elapsed_sec" -ge "$DURATION_SEC" ]]; then
      break
    fi
  fi
  now_epoch="$(date +%s)"
  if [[ $((now_epoch - last_rollover_probe_epoch)) -ge 5 ]]; then
    last_rollover_probe_epoch="$now_epoch"
    if [[ "$AUTO_ROLLOVER_ON_SYNC" -eq 1 && "$RUN_STATE" != "$POST_SYNC_RUN_STATE" ]]; then
      snapshot="$(latest_successful_rpc_snapshot "$RPC_METRICS" || true)"
      if [[ -n "$snapshot" ]]; then
        IFS=, read -r snapshot_ts snapshot_synced <<< "$snapshot"
        if [[ "$snapshot_synced" == "0" ]]; then
          SYNC_ROLLOVER_ARMED=1
        elif [[ "$snapshot_synced" == "1" && "$SYNC_ROLLOVER_ARMED" -eq 1 ]]; then
          note "detected sync transition at $snapshot_ts; closing $RUN_ID and rolling into $POST_SYNC_RUN_STATE"
          ROLLOVER_TRIGGERED=1
          ROLLOVER_REASON="sync"
          ROLLOVER_AT_UTC="$snapshot_ts"
          ROLLOVER_ELAPSED_SEC="$((now_epoch - start_epoch))"
          break
        fi
      fi
    fi
    if [[ "$AUTO_ROLLOVER_ON_PRUNE" -eq 1 && "$PRUNE_ROLLOVER_DISABLED" -eq 0 && "$RUN_STATE" != "$POST_PRUNE_RUN_STATE" ]]; then
      marker_snapshot="$(detect_log_marker_after_offset "$KASPAD_LOG" "$PRUNE_LOG_SCAN_OFFSET" "$PRUNING_START_MARKER" || true)"
      if [[ -n "$marker_snapshot" ]]; then
        IFS=, read -r marker_ts marker_offset <<< "$marker_snapshot"
        if [[ -n "$marker_offset" ]]; then
          PRUNE_LOG_SCAN_OFFSET="$marker_offset"
        fi
        if [[ -n "$marker_ts" ]]; then
          note "detected pruning_start at $marker_ts; closing $RUN_ID and rolling into $POST_PRUNE_RUN_STATE"
          ROLLOVER_TRIGGERED=1
          ROLLOVER_REASON="prune"
          ROLLOVER_AT_UTC="$marker_ts"
          ROLLOVER_ELAPSED_SEC="$((now_epoch - start_epoch))"
          if prepare_rollover_args; then
            note "starting post-prune capture before finalizing $RUN_ID: $NEXT_RUN_ID"
            "$SCRIPT_DIR/run-capture.sh" "${NEXT_ARGS[@]}" &
            NEXT_CAPTURE_PID="$!"
            if wait_for_rollover_capture_ready "$RUNS_DIR/$NEXT_RUN_ID" "$NEXT_CAPTURE_PID"; then
              cleanup_children
              ENDED_AT_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
              note "deferring finalization of $RUN_ID until $NEXT_RUN_ID ends"
              if wait "$NEXT_CAPTURE_PID"; then
                NEXT_CAPTURE_STATUS=0
              else
                NEXT_CAPTURE_STATUS="$?"
              fi
              finalize_run_artifacts
              exit "$NEXT_CAPTURE_STATUS"
            fi
            note "post-prune capture failed to become observable; keeping $RUN_ID capture live"
            if kill -0 "$NEXT_CAPTURE_PID" 2>/dev/null; then
              kill "$NEXT_CAPTURE_PID" 2>/dev/null || true
            fi
            wait "$NEXT_CAPTURE_PID" 2>/dev/null || true
            PRUNE_ROLLOVER_DISABLED=1
          fi
          ROLLOVER_TRIGGERED=0
          ROLLOVER_REASON=""
          ROLLOVER_AT_UTC=""
          ROLLOVER_ELAPSED_SEC=0
        fi
      fi
    fi
  fi
  sleep 1
done

cleanup_children
ENDED_AT_UTC="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
finalize_run_artifacts

if [[ "$ROLLOVER_TRIGGERED" -eq 1 ]]; then
  if prepare_rollover_args; then
    note "starting post-rollover capture: $NEXT_RUN_ID"
    "$SCRIPT_DIR/run-capture.sh" "${NEXT_ARGS[@]}"
  fi
fi
