#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  collect-host-stats.sh --pid PID --disk-device DEVICE --storage-path PATH --out FILE [--interval-sec N] [--duration-sec N]

Notes:
  - Linux only
  - samples host and process counters at fixed cadence
  - stops when duration elapses, the process exits, or SIGINT/SIGTERM arrives
EOF
}

PID=""
DISK_DEVICE=""
STORAGE_PATH=""
OUT_FILE=""
INTERVAL_SEC=1
DURATION_SEC=0
STOP=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --pid)
      PID="$2"
      shift 2
      ;;
    --disk-device)
      DISK_DEVICE="$2"
      shift 2
      ;;
    --storage-path)
      STORAGE_PATH="$2"
      shift 2
      ;;
    --out)
      OUT_FILE="$2"
      shift 2
      ;;
    --interval-sec)
      INTERVAL_SEC="$2"
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

if [[ -z "$PID" || -z "$DISK_DEVICE" || -z "$STORAGE_PATH" || -z "$OUT_FILE" ]]; then
  usage >&2
  exit 1
fi

if [[ "$(uname -s)" != "Linux" ]]; then
  echo "collect-host-stats.sh supports Linux only" >&2
  exit 1
fi

if [[ ! -d "/proc/$PID" ]]; then
  echo "pid $PID is not running" >&2
  exit 1
fi

if ! awk -v device="$DISK_DEVICE" '$3 == device { found = 1 } END { exit(found ? 0 : 1) }' /proc/diskstats; then
  echo "disk device $DISK_DEVICE not found in /proc/diskstats" >&2
  exit 1
fi

mkdir -p "$(dirname "$OUT_FILE")"
trap 'STOP=1' INT TERM

disk_stats() {
  awk -v device="$DISK_DEVICE" '
    $3 == device {
      reads_completed = ($4 == "" ? 0 : $4);
      reads_merged = ($5 == "" ? 0 : $5);
      read_sectors = ($6 == "" ? 0 : $6);
      read_ms = ($7 == "" ? 0 : $7);
      writes_completed = ($8 == "" ? 0 : $8);
      writes_merged = ($9 == "" ? 0 : $9);
      write_sectors = ($10 == "" ? 0 : $10);
      write_ms = ($11 == "" ? 0 : $11);
      io_in_progress = ($12 == "" ? 0 : $12);
      io_ms = ($13 == "" ? 0 : $13);
      io_ms_weighted = ($14 == "" ? 0 : $14);
      discards_completed = ($15 == "" ? 0 : $15);
      discards_merged = ($16 == "" ? 0 : $16);
      discard_sectors = ($17 == "" ? 0 : $17);
      discard_ms = ($18 == "" ? 0 : $18);
      flushes_completed = ($19 == "" ? 0 : $19);
      flush_ms = ($20 == "" ? 0 : $20);
      print reads_completed "," reads_merged "," read_sectors "," read_ms "," writes_completed "," writes_merged "," write_sectors "," write_ms "," io_in_progress "," io_ms "," io_ms_weighted "," discards_completed "," discards_merged "," discard_sectors "," discard_ms "," flushes_completed "," flush_ms;
      exit;
    }
  ' /proc/diskstats
}

meminfo_value() {
  local key="$1"
  awk -v key="$key" '$1 == key ":" { print $2 * 1024; exit }' /proc/meminfo
}

net_bytes() {
  awk '
    NR > 2 {
      gsub(":", "", $1);
      if ($1 != "lo") {
        rx += $2;
        tx += $10;
      }
    }
    END {
      print rx + 0 "," tx + 0;
    }
  ' /proc/net/dev
}

proc_status_value() {
  local key="$1"
  if [[ ! -r "/proc/$PID/status" ]]; then
    echo 0
    return
  fi
  awk -v key="$key" '$1 == key ":" { print $2 * 1024; exit }' "/proc/$PID/status"
}

proc_threads() {
  if [[ ! -r "/proc/$PID/status" ]]; then
    echo 0
    return
  fi
  awk '$1 == "Threads:" { print $2; exit }' "/proc/$PID/status"
}

proc_fd_count() {
  if [[ ! -d "/proc/$PID/fd" ]]; then
    echo 0
    return
  fi
  ls -1 "/proc/$PID/fd" 2>/dev/null | wc -l | tr -d ' '
}

proc_io_value() {
  local key="$1"
  if [[ ! -r "/proc/$PID/io" ]]; then
    echo 0
    return
  fi
  awk -v key="$key" '$1 == key ":" { print $2; exit }' "/proc/$PID/io"
}

storage_used_bytes() {
  df -B1 --output=used "$STORAGE_PATH" | tail -n 1 | tr -d ' '
}

start_epoch="$(date +%s)"

cat >"$OUT_FILE" <<'EOF'
timestamp_utc,elapsed_sec,node_running,cpu_user_jiffies,cpu_nice_jiffies,cpu_system_jiffies,cpu_idle_jiffies,cpu_iowait_jiffies,cpu_irq_jiffies,cpu_softirq_jiffies,cpu_steal_jiffies,mem_total_bytes,mem_available_bytes,swap_total_bytes,swap_free_bytes,net_rx_bytes,net_tx_bytes,disk_reads_completed,disk_reads_merged,disk_read_sectors,disk_read_ms,disk_writes_completed,disk_writes_merged,disk_write_sectors,disk_write_ms,disk_io_in_progress,disk_io_ms,disk_io_ms_weighted,disk_discards_completed,disk_discards_merged,disk_discard_sectors,disk_discard_ms,disk_flushes_completed,disk_flush_ms,storage_used_bytes,proc_rss_bytes,proc_virtual_bytes,proc_threads,proc_fd_count,proc_read_bytes,proc_write_bytes,proc_syscr,proc_syscw
EOF

while [[ "$STOP" -eq 0 ]]; do
  now="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
  epoch_now="$(date +%s)"
  elapsed_sec="$((epoch_now - start_epoch))"

  read -r cpu_user cpu_nice cpu_system cpu_idle cpu_iowait cpu_irq cpu_softirq cpu_steal _ < <(
    awk '/^cpu / { print $2, $3, $4, $5, $6, $7, $8, $9 }' /proc/stat
  )

  mem_total="$(meminfo_value MemTotal)"
  mem_available="$(meminfo_value MemAvailable)"
  swap_total="$(meminfo_value SwapTotal)"
  swap_free="$(meminfo_value SwapFree)"

  IFS=, read -r net_rx net_tx <<<"$(net_bytes)"
  IFS=, read -r \
    disk_reads_completed disk_reads_merged disk_read_sectors disk_read_ms \
    disk_writes_completed disk_writes_merged disk_write_sectors disk_write_ms \
    disk_io_in_progress disk_io_ms disk_io_ms_weighted \
    disk_discards_completed disk_discards_merged disk_discard_sectors disk_discard_ms \
    disk_flushes_completed disk_flush_ms <<<"$(disk_stats)"

  if [[ -d "/proc/$PID" ]]; then
    node_running=1
    proc_rss="$(proc_status_value VmRSS)"
    proc_virtual="$(proc_status_value VmSize)"
    proc_thread_count="$(proc_threads)"
    proc_fds="$(proc_fd_count)"
    proc_read_bytes="$(proc_io_value read_bytes)"
    proc_write_bytes="$(proc_io_value write_bytes)"
    proc_syscr="$(proc_io_value syscr)"
    proc_syscw="$(proc_io_value syscw)"
  else
    node_running=0
    proc_rss=0
    proc_virtual=0
    proc_thread_count=0
    proc_fds=0
    proc_read_bytes=0
    proc_write_bytes=0
    proc_syscr=0
    proc_syscw=0
  fi

  used_bytes="$(storage_used_bytes)"

  printf '%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n' \
    "$now" "$elapsed_sec" "$node_running" \
    "$cpu_user" "$cpu_nice" "$cpu_system" "$cpu_idle" "$cpu_iowait" "$cpu_irq" "$cpu_softirq" "$cpu_steal" \
    "$mem_total" "$mem_available" "$swap_total" "$swap_free" \
    "$net_rx" "$net_tx" \
    "$disk_reads_completed" "$disk_reads_merged" "$disk_read_sectors" "$disk_read_ms" \
    "$disk_writes_completed" "$disk_writes_merged" "$disk_write_sectors" "$disk_write_ms" \
    "$disk_io_in_progress" "$disk_io_ms" "$disk_io_ms_weighted" \
    "$disk_discards_completed" "$disk_discards_merged" "$disk_discard_sectors" "$disk_discard_ms" \
    "$disk_flushes_completed" "$disk_flush_ms" \
    "$used_bytes" \
    "$proc_rss" "$proc_virtual" "$proc_thread_count" "$proc_fds" \
    "$proc_read_bytes" "$proc_write_bytes" "$proc_syscr" "$proc_syscw" \
    >>"$OUT_FILE"

  if [[ "$node_running" -eq 0 ]]; then
    break
  fi

  if [[ "$DURATION_SEC" -gt 0 && "$elapsed_sec" -ge "$DURATION_SEC" ]]; then
    break
  fi

  sleep "$INTERVAL_SEC"
done
