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
  --admin-wan-cidr required
  --bootstrap-rpc-port 16610
  --node-p2p-port 16611
  --without-private-network

Profiles:
  baseline     bootstrap + relay
  txgen1       dedicated txgen host only
  leaf1        leaf1 only
  single       bootstrap + relay + leaf1
  eight        bootstrap + relay + leaf1..leaf8
  calibration  alias for baseline

Modes:
  plan         print the commands only
  create       create servers and reconcile managed firewalls
  destroy      delete the matching servers and managed firewalls

Flags:
  --tier SLUG
  --profile NAME
  --mode plan|create|destroy
  --apply                         actually run the commands instead of printing them
  --location NAME
  --type NAME
  --image NAME
  --ssh-key NAME
  --admin-wan-cidr CIDR           allowlist this WAN CIDR to reach every server
  --bootstrap-rpc-port PORT       bootstrap public gRPC port (default: 16610)
  --node-p2p-port PORT            node P2P port shared by bootstrap/relay/leaves (default: 16611)
  --bootstrap-firewall-name NAME  override managed bootstrap peer firewall name
  --relay-firewall-name NAME      override managed relay peer firewall name
  --leaf-firewall-name NAME       override managed leaf peer firewall name
  --admin-firewall-name NAME      override managed admin firewall name
  --with-private-network          also attach servers to a Hetzner private network
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
    txgen1)
      printf '%s\n' "nbs-${tier}-txgen-01"
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

all_tier_server_names() {
  local tier="$1"
  local i

  printf '%s\n' "nbs-${tier}-bootstrap-01" "nbs-${tier}-relay-01" "nbs-${tier}-txgen-01"
  for i in $(seq 1 8); do
    printf 'nbs-%s-leaf-%02d\n' "$tier" "$i"
  done
}

server_exists() {
  hcloud server describe "$1" >/dev/null 2>&1
}

server_public_ipv4() {
  local name="$1"
  hcloud server describe "$name" -o json | python3 -c 'import json,sys; print(json.load(sys.stdin)["public_net"]["ipv4"]["ip"])'
}

firewall_id() {
  local name="$1"
  hcloud firewall describe "$name" -o json | python3 -c 'import json,sys; print(json.load(sys.stdin)["id"])'
}

server_has_firewall() {
  local server_name="$1"
  local firewall_name="$2"
  local firewall_id_value

  firewall_id_value="$(firewall_id "$firewall_name")"

  hcloud server describe "$server_name" -o json | python3 -c '
import json
import sys

firewall_id = int(sys.argv[1])
data = json.load(sys.stdin)
firewalls = data.get("public_net", {}).get("firewalls", [])
sys.exit(0 if any(item.get("id") == firewall_id for item in firewalls) else 1)
' "$firewall_id_value"
}

existing_tier_server_names() {
  local tier="$1"
  local name

  while IFS= read -r name; do
    if server_exists "$name"; then
      printf '%s\n' "$name"
    fi
  done < <(all_tier_server_names "$tier")
}

role_from_server_name() {
  local name="$1"

  if [[ "$name" == *"bootstrap"* ]]; then
    printf 'bootstrap\n'
  elif [[ "$name" == *"relay"* ]]; then
    printf 'relay\n'
  elif [[ "$name" == *"txgen"* ]]; then
    printf 'txgen\n'
  else
    printf 'leaf\n'
  fi
}

firewall_name_for_tier() {
  local tier="$1"
  local kind="$2"

  case "$kind" in
    admin)
      printf 'nbs-%s-admin-wan\n' "$tier"
      ;;
    bootstrap)
      printf 'nbs-%s-bootstrap-peers\n' "$tier"
      ;;
    relay)
      printf 'nbs-%s-relay-peers\n' "$tier"
      ;;
    leaf)
      printf 'nbs-%s-leaf-peers\n' "$tier"
      ;;
    *)
      fail "unknown firewall kind: $kind"
      ;;
  esac
}

recreate_managed_firewall() {
  local name="$1"
  local role_label="$2"
  shift 2
  local servers=("$@")

  if hcloud firewall describe "$name" >/dev/null 2>&1; then
    local server_name
    for server_name in "${servers[@]}"; do
      if server_has_firewall "$server_name" "$name"; then
        run_or_print \
          hcloud firewall remove-from-resource \
          --type server \
          --server "$server_name" \
          "$name"
      fi
    done
    run_or_print hcloud firewall delete "$name"
  fi

  run_or_print \
    hcloud firewall create \
    --name "$name" \
    --label "investigation=node-bps-scaling" \
    --label "tier=$TIER" \
    --label "role=$role_label"
}

apply_firewall_if_needed() {
  local firewall_name="$1"
  local server_name="$2"

  if ! server_has_firewall "$server_name" "$firewall_name"; then
    run_or_print \
      hcloud firewall apply-to-resource \
      --type server \
      --server "$server_name" \
      "$firewall_name"
  fi
}

configure_admin_firewall() {
  local name="$1"
  shift
  local servers=("$@")

  recreate_managed_firewall "$name" "admin-firewall" "${servers[@]}"

  run_or_print \
    hcloud firewall add-rule \
    --description "all tcp from operator WAN" \
    --direction in \
    --source-ips "$ADMIN_WAN_CIDR" \
    --protocol tcp \
    --port 1-65535 \
    "$name"

  run_or_print \
    hcloud firewall add-rule \
    --description "all udp from operator WAN" \
    --direction in \
    --source-ips "$ADMIN_WAN_CIDR" \
    --protocol udp \
    --port 1-65535 \
    "$name"

  run_or_print \
    hcloud firewall add-rule \
    --description "icmp from operator WAN" \
    --direction in \
    --source-ips "$ADMIN_WAN_CIDR" \
    --protocol icmp \
    "$name"

  local server_name
  for server_name in "${servers[@]}"; do
    apply_firewall_if_needed "$name" "$server_name"
  done
}

configure_bootstrap_firewall() {
  local name="$1"
  local bootstrap_name="$2"
  local relay_ip="$3"
  local txgen_ip="$4"

  recreate_managed_firewall "$name" "bootstrap-firewall" "$bootstrap_name"

  if [[ -n "$relay_ip" ]]; then
    run_or_print \
      hcloud firewall add-rule \
      --description "relay p2p to bootstrap" \
      --direction in \
      --source-ips "${relay_ip}/32" \
      --protocol tcp \
      --port "$NODE_P2P_PORT" \
      "$name"
  fi

  if [[ -n "$txgen_ip" ]]; then
    run_or_print \
      hcloud firewall add-rule \
      --description "dedicated txgen grpc to bootstrap" \
      --direction in \
      --source-ips "${txgen_ip}/32" \
      --protocol tcp \
      --port "$BOOTSTRAP_RPC_PORT" \
      "$name"
  fi

  apply_firewall_if_needed "$name" "$bootstrap_name"
}

configure_relay_firewall() {
  local name="$1"
  local relay_name="$2"
  local bootstrap_ip="$3"
  shift 3

  recreate_managed_firewall "$name" "relay-firewall" "$relay_name"

  if [[ -n "$bootstrap_ip" ]]; then
    run_or_print \
      hcloud firewall add-rule \
      --description "bootstrap p2p to relay" \
      --direction in \
      --source-ips "${bootstrap_ip}/32" \
      --protocol tcp \
      --port "$NODE_P2P_PORT" \
      "$name"
  fi

  if [[ "$#" -gt 0 ]]; then
    local leaf_ip
    for leaf_ip in "$@"; do
      run_or_print \
        hcloud firewall add-rule \
        --description "leaf p2p to relay" \
        --direction in \
        --source-ips "${leaf_ip}/32" \
        --protocol tcp \
        --port "$NODE_P2P_PORT" \
        "$name"
    done
  fi

  apply_firewall_if_needed "$name" "$relay_name"
}

configure_leaf_firewall() {
  local name="$1"
  local relay_ip="$2"
  shift 2
  local leaf_names=("$@")

  [[ "${#leaf_names[@]}" -gt 0 ]] || return 0

  recreate_managed_firewall "$name" "leaf-firewall" "${leaf_names[@]}"

  if [[ -n "$relay_ip" ]]; then
    run_or_print \
      hcloud firewall add-rule \
      --description "relay p2p to leaves" \
      --direction in \
      --source-ips "${relay_ip}/32" \
      --protocol tcp \
      --port "$NODE_P2P_PORT" \
      "$name"
  fi

  local leaf_name
  for leaf_name in "${leaf_names[@]}"; do
    apply_firewall_if_needed "$name" "$leaf_name"
  done
}

reconcile_firewalls() {
  local existing_servers=()
  local existing_leaves=()
  local bootstrap_name=""
  local relay_name=""
  local txgen_name=""
  local bootstrap_ip=""
  local relay_ip=""
  local txgen_ip=""
  local leaf_ips=()
  local name
  local role

  while IFS= read -r name; do
    existing_servers+=("$name")
    role="$(role_from_server_name "$name")"
    case "$role" in
      bootstrap)
        bootstrap_name="$name"
        bootstrap_ip="$(server_public_ipv4 "$name")"
        ;;
      relay)
        relay_name="$name"
        relay_ip="$(server_public_ipv4 "$name")"
        ;;
      txgen)
        txgen_name="$name"
        txgen_ip="$(server_public_ipv4 "$name")"
        ;;
      leaf)
        existing_leaves+=("$name")
        leaf_ips+=("$(server_public_ipv4 "$name")")
        ;;
    esac
  done < <(existing_tier_server_names "$TIER")

  if [[ "${#existing_servers[@]}" -eq 0 ]]; then
    note "no existing tier servers found for firewall reconciliation"
    return 0
  fi

  configure_admin_firewall "$ADMIN_FIREWALL_NAME" "${existing_servers[@]}"

  if [[ -n "$bootstrap_name" ]]; then
    configure_bootstrap_firewall "$BOOTSTRAP_FIREWALL_NAME" "$bootstrap_name" "$relay_ip" "$txgen_ip"
  fi

  if [[ -n "$relay_name" ]]; then
    if [[ "${#leaf_ips[@]}" -gt 0 ]]; then
      configure_relay_firewall "$RELAY_FIREWALL_NAME" "$relay_name" "$bootstrap_ip" "${leaf_ips[@]}"
    else
      configure_relay_firewall "$RELAY_FIREWALL_NAME" "$relay_name" "$bootstrap_ip"
    fi
  fi

  if [[ "${#existing_leaves[@]}" -gt 0 ]]; then
    configure_leaf_firewall "$LEAF_FIREWALL_NAME" "$relay_ip" "${existing_leaves[@]}"
  fi
}

delete_firewall_if_exists() {
  local name="$1"
  if hcloud firewall describe "$name" >/dev/null 2>&1; then
    run_or_print hcloud firewall delete "$name"
  fi
}

TIER="20bps"
PROFILE="calibration"
MODE="plan"
APPLY=0
LOCATION="hel1"
SERVER_TYPE="cpx42"
IMAGE="ubuntu-24.04"
SSH_KEY="luke-mbp-id-ed25519"
ADMIN_WAN_CIDR=""
BOOTSTRAP_RPC_PORT="16610"
NODE_P2P_PORT="16611"
WITH_PRIVATE_NETWORK=0
NETWORK_NAME="node-bps-scaling"
NETWORK_RANGE="10.80.0.0/16"
SUBNET_RANGE="10.80.0.0/24"
NETWORK_ZONE="eu-central"
ADMIN_FIREWALL_NAME=""
BOOTSTRAP_FIREWALL_NAME=""
RELAY_FIREWALL_NAME=""
LEAF_FIREWALL_NAME=""

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
    --admin-wan-cidr|--bootstrap-wan-cidr)
      ADMIN_WAN_CIDR="${2:-}"
      shift 2
      ;;
    --bootstrap-rpc-port)
      BOOTSTRAP_RPC_PORT="${2:-}"
      shift 2
      ;;
    --node-p2p-port|--bootstrap-p2p-port)
      NODE_P2P_PORT="${2:-}"
      shift 2
      ;;
    --admin-firewall-name)
      ADMIN_FIREWALL_NAME="${2:-}"
      shift 2
      ;;
    --bootstrap-firewall-name)
      BOOTSTRAP_FIREWALL_NAME="${2:-}"
      shift 2
      ;;
    --relay-firewall-name)
      RELAY_FIREWALL_NAME="${2:-}"
      shift 2
      ;;
    --leaf-firewall-name)
      LEAF_FIREWALL_NAME="${2:-}"
      shift 2
      ;;
    --with-private-network)
      WITH_PRIVATE_NETWORK=1
      shift
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

if [[ "$MODE" != "destroy" && -z "$ADMIN_WAN_CIDR" ]]; then
  fail "--admin-wan-cidr is required for plan/create"
fi

if [[ -z "$ADMIN_FIREWALL_NAME" ]]; then
  ADMIN_FIREWALL_NAME="$(firewall_name_for_tier "$TIER" admin)"
fi

if [[ -z "$BOOTSTRAP_FIREWALL_NAME" ]]; then
  BOOTSTRAP_FIREWALL_NAME="$(firewall_name_for_tier "$TIER" bootstrap)"
fi

if [[ -z "$RELAY_FIREWALL_NAME" ]]; then
  RELAY_FIREWALL_NAME="$(firewall_name_for_tier "$TIER" relay)"
fi

if [[ -z "$LEAF_FIREWALL_NAME" ]]; then
  LEAF_FIREWALL_NAME="$(firewall_name_for_tier "$TIER" leaf)"
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
  if [[ "$APPLY" -eq 1 ]]; then
    if [[ -n "$(existing_tier_server_names "$TIER")" ]]; then
      reconcile_firewalls
    else
      delete_firewall_if_exists "$LEAF_FIREWALL_NAME"
      delete_firewall_if_exists "$RELAY_FIREWALL_NAME"
      delete_firewall_if_exists "$BOOTSTRAP_FIREWALL_NAME"
      delete_firewall_if_exists "$ADMIN_FIREWALL_NAME"
    fi
  else
    note "destroy plan only; firewalls would be reconciled after server deletion"
  fi
  exit 0
fi

if [[ "$WITH_PRIVATE_NETWORK" -eq 1 ]]; then
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
fi

for name in "${SERVERS[@]}"; do
  role="$(role_from_server_name "$name")"

  if server_exists "$name"; then
    note "server already exists, skipping create: $name"
    continue
  fi

  create_cmd=(
    hcloud server create
    --name "$name"
    --type "$SERVER_TYPE"
    --image "$IMAGE"
    --location "$LOCATION"
    --ssh-key "$SSH_KEY"
    --label "investigation=node-bps-scaling"
    --label "tier=$TIER"
    --label "profile=$PROFILE"
    --label "role=$role"
  )

  if [[ "$WITH_PRIVATE_NETWORK" -eq 1 ]]; then
    create_cmd+=(--network "$NETWORK_NAME")
  fi

  run_or_print "${create_cmd[@]}"
done

if [[ "$APPLY" -eq 1 ]]; then
  reconcile_firewalls
else
  note "peer firewalls are rebuilt from the current servers' public IPs during --apply"
fi
