#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  collect-rocksdb-logs.sh --db-root PATH --outdir DIR [--pid PID] [--duration-sec N]

Notes:
  - tails existing RocksDB LOG files under the db root
  - writes one output file per source LOG
  - stops when duration elapses, the tracked pid exits, or SIGINT/SIGTERM arrives
EOF
}

DB_ROOT=""
OUT_DIR=""
PID=""
DURATION_SEC=0
STOP=0
TAIL_PIDS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --db-root)
      DB_ROOT="$2"
      shift 2
      ;;
    --outdir)
      OUT_DIR="$2"
      shift 2
      ;;
    --pid)
      PID="$2"
      shift 2
      ;;
    --duration-sec)
      DURATION_SEC="$2"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "unknown arg: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

if [[ -z "$DB_ROOT" || -z "$OUT_DIR" ]]; then
  usage >&2
  exit 1
fi

if [[ ! -d "$DB_ROOT" ]]; then
  echo "db root not found: $DB_ROOT" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

cleanup() {
  STOP=1
  for tail_pid in "${TAIL_PIDS[@]:-}"; do
    if kill -0 "$tail_pid" 2>/dev/null; then
      kill "$tail_pid" 2>/dev/null || true
      wait "$tail_pid" 2>/dev/null || true
    fi
  done
}

trap cleanup INT TERM EXIT

manifest="$OUT_DIR/sources.csv"
printf 'source_path,output_name\n' >"$manifest"

mapfile -t log_files < <(find "$DB_ROOT" -maxdepth 3 -type f -name LOG | sort)
if [[ "${#log_files[@]}" -eq 0 ]]; then
  echo "no RocksDB LOG files found under $DB_ROOT" >&2
  exit 1
fi

for source_path in "${log_files[@]}"; do
  rel="${source_path#$DB_ROOT/}"
  safe_name="${rel//\//__}"
  out_file="$OUT_DIR/${safe_name}.log"
  printf '%s,%s\n' "$source_path" "${safe_name}.log" >>"$manifest"
  tail -n 0 -F "$source_path" >>"$out_file" &
  TAIL_PIDS+=("$!")
done

start_epoch="$(date +%s)"

while [[ "$STOP" -eq 0 ]]; do
  if [[ -n "$PID" && ! -d "/proc/$PID" ]]; then
    break
  fi

  if [[ "$DURATION_SEC" -gt 0 ]]; then
    now_epoch="$(date +%s)"
    elapsed_sec="$((now_epoch - start_epoch))"
    if [[ "$elapsed_sec" -ge "$DURATION_SEC" ]]; then
      break
    fi
  fi

  sleep 1
done
