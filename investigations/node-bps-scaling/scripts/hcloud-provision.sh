#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Usage:
  investigations/node-bps-scaling/scripts/hcloud-provision.sh [options]

Purpose:
  Print or execute hcloud provisioning commands for node-bps-scaling.

Defaults:
  --mode plan
  --profile calibration
  --tier 20bps
  --type cpx42
  --location hel1
  --image ubuntu-24.04
  --ssh-key luke-mbp-id-ed25519
  --network-name node-bps-scaling
  --network-range 10.80.0.0/16
  --subnet-range 10.80.0.0/24
  --network-zone eu-central

Profiles:
  baseline     bootstrap + relay
  leaf1        leaf1 only
  single       bootstrap + relay + leaf1
  eight        bootstrap + relay + leaf1..leaf8
  calibration  alias for baseline

Modes:
  plan         print the commands only
  create       create network and servers
  destroy      delete the matching servers

Flags:
  --tier SLUG
  --profile NAME
  --mode plan|create|destroy
  --apply                      actually run the commands instead of printing them
  --location NAME
  --type NAME
  --image NAME
  --ssh-key NAME
  --network-name NAME
  --network-range CIDR
  --subnet-range CIDR
  --network-zone NAME
  -h, --help
EOF
}

fail() {
  printf 'hcloud-provision: %s\n' "$*" >&2
  exit 1
}

note() {
  printf 'hcloud-provision: %s\n' "$*"
}

run_or_print() {
  if [[ "$APPLY" -eq 1 ]]; then
    note "running: $*"
    "$@"
  else
    printf '%q ' "$@"
    printf '\n'
  fi
}

server_names_for_profile() {
  local tier="$1"
  local profile="$2"

  case "$profile" in
    baseline|calibration)
      printf '%s\n' "nbs-${tier}-bootstrap-01" "nbs-${tier}-relay-01"
      ;;
    leaf1)
      printf '%s\n' "nbs-${tier}-leaf-01"
      ;;
    single)
      printf '%s\n' "nbs-${tier}-bootstrap-01" "nbs-${tier}-relay-01" "nbs-${tier}-leaf-01"
      ;;
    eight)
      printf '%s\n' "nbs-${tier}-bootstrap-01" "nbs-${tier}-relay-01"
      local i
      for i in $(seq 1 8); do
        printf 'nbs-%s-leaf-%02d\n' "$tier" "$i"
      done
      ;;
    *)
      fail "unknown profile: $profile"
      ;;
  esac
}

TIER="20bps"
PROFILE="calibration"
MODE="plan"
APPLY=0
LOCATION="hel1"
SERVER_TYPE="cpx42"
IMAGE="ubuntu-24.04"
SSH_KEY="luke-mbp-id-ed25519"
NETWORK_NAME="node-bps-scaling"
NETWORK_RANGE="10.80.0.0/16"
SUBNET_RANGE="10.80.0.0/24"
NETWORK_ZONE="eu-central"

while [[ $# -gt 0 ]]; do
  case "$1" in
    --tier)
      TIER="${2:-}"
      shift 2
      ;;
    --profile)
      PROFILE="${2:-}"
      shift 2
      ;;
    --mode)
      MODE="${2:-}"
      shift 2
      ;;
    --apply)
      APPLY=1
      shift
      ;;
    --location)
      LOCATION="${2:-}"
      shift 2
      ;;
    --type)
      SERVER_TYPE="${2:-}"
      shift 2
      ;;
    --image)
      IMAGE="${2:-}"
      shift 2
      ;;
    --ssh-key)
      SSH_KEY="${2:-}"
      shift 2
      ;;
    --network-name)
      NETWORK_NAME="${2:-}"
      shift 2
      ;;
    --network-range)
      NETWORK_RANGE="${2:-}"
      shift 2
      ;;
    --subnet-range)
      SUBNET_RANGE="${2:-}"
      shift 2
      ;;
    --network-zone)
      NETWORK_ZONE="${2:-}"
      shift 2
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      fail "unknown argument: $1"
      ;;
  esac
done

case "$MODE" in
  plan|create|destroy)
    ;;
  *)
    fail "invalid mode: $MODE"
    ;;
esac

if [[ "$MODE" == "plan" && "$APPLY" -eq 1 ]]; then
  fail "--apply is only valid with --mode create or --mode destroy"
fi

SERVERS=()
while IFS= read -r line; do
  SERVERS+=("$line")
done < <(server_names_for_profile "$TIER" "$PROFILE")

if [[ "$MODE" == "plan" ]]; then
  note "plan only; no commands will be executed"
fi

if [[ "$MODE" == "destroy" ]]; then
  for name in "${SERVERS[@]}"; do
    run_or_print hcloud server delete "$name"
  done
  exit 0
fi

NETWORK_EXISTS=0
if hcloud network describe "$NETWORK_NAME" >/dev/null 2>&1; then
  NETWORK_EXISTS=1
fi

if [[ "$NETWORK_EXISTS" -eq 0 ]]; then
  run_or_print \
    hcloud network create \
    --name "$NETWORK_NAME" \
    --ip-range "$NETWORK_RANGE" \
    --label "investigation=node-bps-scaling"

  run_or_print \
    hcloud network add-subnet "$NETWORK_NAME" \
    --type cloud \
    --network-zone "$NETWORK_ZONE" \
    --ip-range "$SUBNET_RANGE"
fi

for name in "${SERVERS[@]}"; do
  role="${name##*-}"
  if [[ "$name" == *"bootstrap"* ]]; then
    role="bootstrap"
  elif [[ "$name" == *"relay"* ]]; then
    role="relay"
  elif [[ "$name" == *"leaf"* ]]; then
    role="leaf"
  fi

  if hcloud server describe "$name" >/dev/null 2>&1; then
    note "server already exists, skipping create: $name"
    continue
  fi

  run_or_print \
    hcloud server create \
    --name "$name" \
    --type "$SERVER_TYPE" \
    --image "$IMAGE" \
    --location "$LOCATION" \
    --ssh-key "$SSH_KEY" \
    --network "$NETWORK_NAME" \
    --label "investigation=node-bps-scaling" \
    --label "tier=$TIER" \
    --label "profile=$PROFILE" \
    --label "role=$role"
done
