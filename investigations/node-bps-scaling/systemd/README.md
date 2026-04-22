## Service Model

These unit templates capture the current working `20bps` layout:

- bootstrap node runs as `kaspa-bootstrap-20bps.service`
- bootstrap miner runs as `kaspa-bootstrap-miner.service`
- bootstrap txgen runs as `kaspa-bootstrap-txgen.service`
- relay node runs as `kaspa-relay-20bps.service`
- helper miner runs as `nbs-helper-miner.service`

The intended operating model is:

- bootstrap DB is preserved across restarts
- bootstrap RPC is public on `16610`
- bootstrap, relay, and leaves talk over public P2P on `16611`
- bootstrap hosts both the primary miner and txgen
- helper host `10.0.4.10` contributes supplementary mining only
- helper miner is intentionally capped with `CPUQuota=60%` for the validated `20bps` profile
- txgen is installed on bootstrap as a service and only started during active load windows

## Expected Env Files

Bootstrap node:

- `/opt/node-bps-scaling/secrets/kaspa-bootstrap-20bps.env`

Example:

```bash
OVERRIDE_FILE=/opt/node-bps-scaling/20bps.override.json
APPDIR=/var/lib/kaspa-bootstrap-20bps
P2P_PORT=16611
RPC_PORT=16610
KASPAD_EXTRA_ARGS=
```

Bootstrap miner:

- `/opt/node-bps-scaling/secrets/bootstrap-miner.env`

Example:

```bash
MINER_ADDRESS=kaspadev:...
RPC_HOST=127.0.0.1
RPC_PORT=16610
MINER_THREADS=2
```

Bootstrap txgen:

- `/opt/node-bps-scaling/secrets/bootstrap-txgen.env`

Example:

```bash
RPC_HOST=127.0.0.1
RPC_PORT=16610
TX_GEN_PRIVATE_KEY=...
TXGEN_TPS=6000
TXGEN_CLIENT_POOL_SIZE=32
TXGEN_MAX_INFLIGHT=3000
TXGEN_MEMPOOL_HIGH_WATERMARK=650000
TXGEN_MEMPOOL_RESUME_WATERMARK=450000
TXGEN_RPC_TIMEOUT_MS=15000
TXGEN_STARTUP_RPC_TIMEOUT_MS=300000
TXGEN_COINBASE_MATURITY=2000
TXGEN_TIMEOUT_COOLDOWN_MS=1000
TXGEN_TIMEOUT_COOLDOWN_THRESHOLD=64
```

Relay node:

- `/opt/node-bps-scaling/secrets/kaspa-relay-20bps.env`

Example:

```bash
OVERRIDE_FILE=/opt/node-bps-scaling/20bps.override.json
APPDIR=/var/lib/kaspa-relay-20bps
P2P_PORT=16611
RPC_PORT=16610
BOOTSTRAP_P2P=157.180.69.53:16611
KASPAD_EXTRA_ARGS=
```

Helper miner wallet:

- `~/node-bps-scaling/remote-miner-wallet.env`

Example:

```bash
MINER_ADDRESS=kaspadev:...
MINER_THREADS=1
```

Helper bootstrap endpoint:

- `~/node-bps-scaling/bootstrap-endpoint.env`

Example:

```bash
BOOTSTRAP_RPC_HOST=157.180.69.53
BOOTSTRAP_RPC_PORT=16610
BOOTSTRAP_P2P=157.180.69.53:16611
```

The checked-in helper miner unit also applies:

```bash
CPUQuota=60%
```

## Install Notes

Copy the appropriate service files onto the target host under `/etc/systemd/system/`, reload systemd, then enable the units you want active by default:

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now kaspa-bootstrap-20bps kaspa-bootstrap-miner
sudo systemctl enable kaspa-bootstrap-txgen
sudo systemctl enable --now kaspa-relay-20bps
sudo systemctl enable --now nbs-helper-miner
```

The bootstrap txgen unit is typically enabled but left stopped until the calibration or baseline load window begins.
