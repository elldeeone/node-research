#!/usr/bin/env bash
set -euo pipefail

BASE_DIR="${HOME}/node-bps-scaling"
BIN_PATH="${HOME}/kaspa-miner-musl"
ENV_FILE="${BASE_DIR}/remote-miner-wallet.env"
LOG_DIR="${BASE_DIR}/logs"
LOG_FILE="${LOG_DIR}/remote-miner-wallet.log"
PID_FILE="${BASE_DIR}/remote-miner-wallet.pid"
RPC_HOST="${RPC_HOST:-}"
RPC_PORT="${RPC_PORT:-16110}"
MINER_THREADS="${MINER_THREADS:-1}"

usage() {
  cat <<'EOF'
Usage:
  remote-miner-helper.sh start
  remote-miner-helper.sh stop
  remote-miner-helper.sh status

Environment:
  RPC_HOST        bootstrap public RPC host reachable from this helper (required)
  RPC_PORT        bootstrap public RPC port reachable from this helper (default: 16110)
  MINER_THREADS   miner thread count (default: 1)

Required env file:
  ~/node-bps-scaling/remote-miner-wallet.env
  with MINER_ADDRESS=<address>
EOF
}

require_rpc_target() {
  if [[ -z "${RPC_HOST}" ]]; then
    echo "RPC_HOST is required; point it at the bootstrap public IP or DNS name" >&2
    exit 1
  fi
}

require_env() {
  if [[ ! -f "${ENV_FILE}" ]]; then
    echo "missing env file: ${ENV_FILE}" >&2
    exit 1
  fi
  # shellcheck disable=SC1090
  source "${ENV_FILE}"
  if [[ -z "${MINER_ADDRESS:-}" ]]; then
    echo "MINER_ADDRESS is required in ${ENV_FILE}" >&2
    exit 1
  fi
}

is_running() {
  [[ -f "${PID_FILE}" ]] && kill -0 "$(cat "${PID_FILE}")" 2>/dev/null
}

start() {
  require_rpc_target
  require_env
  mkdir -p "${LOG_DIR}"
  if [[ ! -x "${BIN_PATH}" ]]; then
    echo "missing miner binary: ${BIN_PATH}" >&2
    exit 1
  fi
  if is_running; then
    echo "remote miner already running with pid $(cat "${PID_FILE}")"
    exit 0
  fi
  nohup "${BIN_PATH}" \
    --mine-when-not-synced \
    --mining-address "${MINER_ADDRESS}" \
    -s "${RPC_HOST}" \
    -p "${RPC_PORT}" \
    -t "${MINER_THREADS}" \
    --altlogs \
    >> "${LOG_FILE}" 2>&1 < /dev/null &
  echo $! > "${PID_FILE}"
  echo "started remote miner pid $(cat "${PID_FILE}") log ${LOG_FILE}"
}

stop() {
  if ! [[ -f "${PID_FILE}" ]]; then
    echo "remote miner not running"
    exit 0
  fi
  local pid
  pid="$(cat "${PID_FILE}")"
  if kill -0 "${pid}" 2>/dev/null; then
    kill "${pid}"
    echo "stopped remote miner pid ${pid}"
  else
    echo "stale remote miner pid ${pid}"
  fi
  rm -f "${PID_FILE}"
}

status() {
  if is_running; then
    ps -p "$(cat "${PID_FILE}")" -o pid=,etime=,%cpu=,%mem=,command=
  else
    echo "remote miner not running"
  fi
}

case "${1:-}" in
  start) start ;;
  stop) stop ;;
  status) status ;;
  *) usage; exit 1 ;;
esac
