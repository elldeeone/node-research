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
  --bootstrap-rpc-port 16110
  --bootstrap-p2p-port 16111

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
  --bootstrap-wan-cidr CIDR      allowlist this WAN CIDR to reach bootstrap SSH and gRPC
  --bootstrap-rpc-port PORT      bootstrap public gRPC port to allowlist (default: 16110)
  --bootstrap-p2p-port PORT      bootstrap P2P port to allow from the Hetzner private network (default: 16111)
  --bootstrap-firewall-name NAME override the managed bootstrap firewall name
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

bootstrap_firewall_name_for_tier() {
  local tier="$1"
  printf 'nbs-%s-bootstrap-public-rpc\n' "$tier"
}

profile_includes_bootstrap() {
  local profile="$1"

  case "$profile" in
    baseline|calibration|single|eight)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
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
BOOTSTRAP_WAN_CIDR=""
BOOTSTRAP_RPC_PORT="16110"
BOOTSTRAP_P2P_PORT="16111"
BOOTSTRAP_FIREWALL_NAME=""

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
    --bootstrap-wan-cidr)
      BOOTSTRAP_WAN_CIDR="${2:-}"
      shift 2
      ;;
    --bootstrap-rpc-port)
      BOOTSTRAP_RPC_PORT="${2:-}"
      shift 2
      ;;
    --bootstrap-p2p-port)
      BOOTSTRAP_P2P_PORT="${2:-}"
      shift 2
      ;;
    --bootstrap-firewall-name)
      BOOTSTRAP_FIREWALL_NAME="${2:-}"
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

if [[ -z "$BOOTSTRAP_FIREWALL_NAME" ]]; then
  BOOTSTRAP_FIREWALL_NAME="$(bootstrap_firewall_name_for_tier "$TIER")"
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
  if [[ -n "$BOOTSTRAP_WAN_CIDR" ]] && profile_includes_bootstrap "$PROFILE"; then
    run_or_print hcloud firewall delete "$BOOTSTRAP_FIREWALL_NAME"
  fi
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

if [[ -n "$BOOTSTRAP_WAN_CIDR" ]] && profile_includes_bootstrap "$PROFILE"; then
  if hcloud firewall describe "$BOOTSTRAP_FIREWALL_NAME" >/dev/null 2>&1; then
    note "bootstrap firewall already exists, skipping create: $BOOTSTRAP_FIREWALL_NAME"
  else
    run_or_print \
      hcloud firewall create \
      --name "$BOOTSTRAP_FIREWALL_NAME" \
      --label "investigation=node-bps-scaling" \
      --label "tier=$TIER" \
      --label "role=bootstrap-firewall"

    run_or_print \
      hcloud firewall add-rule \
      --description "admin ssh from allowlisted WAN" \
      --direction in \
      --source-ips "$BOOTSTRAP_WAN_CIDR" \
      --protocol tcp \
      --port 22 \
      "$BOOTSTRAP_FIREWALL_NAME"

    run_or_print \
      hcloud firewall add-rule \
      --description "bootstrap gRPC from allowlisted WAN" \
      --direction in \
      --source-ips "$BOOTSTRAP_WAN_CIDR" \
      --protocol tcp \
      --port "$BOOTSTRAP_RPC_PORT" \
      "$BOOTSTRAP_FIREWALL_NAME"

    run_or_print \
      hcloud firewall add-rule \
      --description "bootstrap P2P from Hetzner private network" \
      --direction in \
      --source-ips "$NETWORK_RANGE" \
      --protocol tcp \
      --port "$BOOTSTRAP_P2P_PORT" \
      "$BOOTSTRAP_FIREWALL_NAME"
  fi
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
    if [[ -n "$BOOTSTRAP_WAN_CIDR" && "$role" == "bootstrap" ]]; then
      run_or_print \
        hcloud firewall apply-to-resource \
        --type server \
        --server "$name" \
        "$BOOTSTRAP_FIREWALL_NAME"
    fi
    continue
  fi

  create_cmd=(
    hcloud server create
    --name "$name"
    --type "$SERVER_TYPE"
    --image "$IMAGE"
    --location "$LOCATION"
    --ssh-key "$SSH_KEY"
    --network "$NETWORK_NAME"
    --label "investigation=node-bps-scaling"
    --label "tier=$TIER"
    --label "profile=$PROFILE"
    --label "role=$role"
  )

  if [[ -n "$BOOTSTRAP_WAN_CIDR" && "$role" == "bootstrap" ]]; then
    create_cmd+=(--firewall "$BOOTSTRAP_FIREWALL_NAME")
  fi

  run_or_print "${create_cmd[@]}"
done
