#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  collect-iostat.sh --device DEVICE --out FILE [--pid PID] [--duration-sec N]

Notes:
  - Linux only
  - requires iostat with JSON output support
  - writes one compact JSON document per line with a UTC timestamp prefix
EOF
}

DEVICE=""
OUT_FILE=""
PID=""
DURATION_SEC=0
STOP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --device)
      DEVICE="$2"
      shift 2
      ;;
    --out)
      OUT_FILE="$2"
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

if [[ -z "$DEVICE" || -z "$OUT_FILE" ]]; then
  usage >&2
  exit 1
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "collect-iostat.sh supports Linux only" >&2
  exit 1
fi

if ! command -v iostat >/dev/null 2>&1; then
  echo "iostat not found" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT_FILE")"
trap 'STOP=1' INT TERM
start_epoch="$(date +%s)"

while [[ "$STOP" -eq 0 ]]; do
  if [[ -n "$PID" && ! -d "/proc/$PID" ]]; then
    break
  fi

  timestamp_utc="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  json_payload="$(
    iostat -x -y -o JSON "$DEVICE" 1 1 |
      python3 -c 'import json, sys; print(json.dumps(json.load(sys.stdin), separators=(",", ":")))' 
  )"
  printf '%s\t%s\n' "$timestamp_utc" "$json_payload" >>"$OUT_FILE"

  if [[ "$DURATION_SEC" -gt 0 ]]; then
    now_epoch="$(date +%s)"
    elapsed_sec="$((now_epoch - start_epoch))"
    if [[ "$elapsed_sec" -ge "$DURATION_SEC" ]]; then
      break
    fi
  fi
done

