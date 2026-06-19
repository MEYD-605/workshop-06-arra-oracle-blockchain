#!/bin/bash
# sync-chain.sh — Sync OP Stack L2 (Chain ID 20260619) from Nova sequencer
# No.88 Sombo · Workshop-06 · Oracle School
#
# Prerequisites:
#   - op-geth and op-node binaries (see BUILD section below)
#   - genesis.json from Nova:
#       scp oracle-school@natz-ai-03:/home/oracle-school/nova-opstack-l2/genesis-l2-20260619.json genesis.json
#   - rollup.json from Nova:
#       scp oracle-school@natz-ai-03:/home/oracle-school/nova-opstack-l2/rollup.json rollup.json
#
# BUILD (if binaries not present):
#   op-geth: git clone https://github.com/ethereum-optimism/op-geth && cd op-geth && go run build/ci.go install ./cmd/geth && mv build/bin/geth ../op-geth
#   op-node: git clone https://github.com/ethereum-optimism/optimism && cd optimism/op-node && go build -o ../../op-node ./cmd/

set -e

# -- Config ----------------------------------------------------------------
NOVA_PEER_ADDR="141.11.156.4"
NOVA_P2P_PORT="9222"
NOVA_PEER_ID="16Uiu2HAmTZ9fjqstMoCxriM2mmHennreqjmoHhg3fLYYAyyRBeVm"

L1_RPC="${L1_RPC:-https://ethereum-sepolia-rpc.publicnode.com}"
L1_BEACON="${L1_BEACON:-https://ethereum-sepolia-beacon-api.publicnode.com}"
DATA_DIR="${DATA_DIR:-./op-geth-data}"
OP_GETH="${OP_GETH:-./op-geth}"
OP_NODE="${OP_NODE:-./op-node}"
HTTP_PORT="${HTTP_PORT:-8545}"
AUTHRPC_PORT="${AUTHRPC_PORT:-8551}"
P2P_PORT="${P2P_PORT:-9000}"
NODE_RPC_PORT="${NODE_RPC_PORT:-8547}"
# --------------------------------------------------------------------------

echo "=== Sombo OP Stack L2 Sync Node ==="
echo "Chain ID:   20260619 (L2 OP Stack)"
echo "L1:         Sepolia (11155111)"
echo "Sequencer:  $NOVA_PEER_ADDR (Nova)"
echo ""

# Check required files
for f in genesis.json rollup.json; do
    if [ ! -f "$f" ]; then
        echo "ERROR: $f not found."
        echo "  scp oracle-school@natz-ai-03:/home/oracle-school/nova-opstack-l2/genesis-l2-20260619.json genesis.json"
        echo "  scp oracle-school@natz-ai-03:/home/oracle-school/nova-opstack-l2/rollup.json rollup.json"
        exit 1
    fi
done

# Check binaries
for bin in "$OP_GETH" "$OP_NODE"; do
    if ! command -v "$bin" &>/dev/null && [ ! -x "$bin" ]; then
        echo "ERROR: $bin not found. See BUILD instructions at top of script."
        exit 1
    fi
done

# Generate JWT (shared secret between op-geth and op-node)
if [ ! -f jwt.txt ]; then
    echo "[1/4] Generating JWT secret..."
    openssl rand -hex 32 > jwt.txt && chmod 600 jwt.txt
    echo "  ✓ jwt.txt"
fi

# Init op-geth from genesis
if [ ! -d "$DATA_DIR/geth" ]; then
    echo "[2/4] Initializing op-geth from genesis..."
    "$OP_GETH" init --datadir "$DATA_DIR" genesis.json
    echo "  ✓ genesis hash: 0xd5fff5ddf838f0a4dcc0ff35e679aa7d79a34ec01e3f7e2b9f23ce621373ac2d"
fi

# Kill any leftover processes on our ports
lsof -ti:$HTTP_PORT 2>/dev/null | xargs kill -9 2>/dev/null || true
lsof -ti:$AUTHRPC_PORT 2>/dev/null | xargs kill -9 2>/dev/null || true

# Start op-geth (execution layer)
echo "[3/4] Starting op-geth..."
"$OP_GETH" \
    --datadir "$DATA_DIR" \
    --networkid 20260619 \
    --http --http.addr 0.0.0.0 --http.port "$HTTP_PORT" \
    --http.api eth,net,web3 \
    --authrpc.addr 127.0.0.1 --authrpc.port "$AUTHRPC_PORT" \
    --authrpc.jwtsecret jwt.txt \
    --authrpc.vhosts '*' \
    --port "$P2P_PORT" \
    --nodiscover --maxpeers 0 \
    --syncmode full \
    > op-geth.log 2>&1 &
GETH_PID=$!
echo "  op-geth PID: $GETH_PID (logs: op-geth.log)"

# Wait for op-geth engine RPC
echo "  Waiting for op-geth..."
for i in $(seq 1 30); do
    if curl -sf "http://127.0.0.1:$HTTP_PORT" \
        -H 'Content-Type: application/json' \
        -d '{"jsonrpc":"2.0","method":"eth_chainId","params":[],"id":1}' \
        2>/dev/null | grep -q "135270b"; then
        echo "  ✓ op-geth ready (chain 0x135270b = 20260619)"
        break
    fi
    sleep 2
done

# Start op-node (rollup consensus layer)
# --syncmode=consensus-layer    : receive blocks via P2P gossip + req-resp
# --syncmode.req-resp            : pull historical blocks from sequencer via libp2p req-resp
# --p2p.static                   : always connect to Nova sequencer peer
# --l1.rpc-max-batch-size/rate-limit: avoid public Sepolia RPC 429 rate-limits
echo "[4/4] Starting op-node..."
"$OP_NODE" \
    --l2="http://127.0.0.1:$AUTHRPC_PORT" \
    --l2.jwt-secret=jwt.txt \
    --l2.enginekind=geth \
    --l1="$L1_RPC" \
    --l1.beacon="$L1_BEACON" \
    --l1.trustrpc \
    --l1.rpckind=standard \
    --l1.rpc-max-batch-size=10 \
    --l1.rpc-rate-limit=10 \
    --l1.max-concurrency=10 \
    --rollup.config=rollup.json \
    --rpc.addr=0.0.0.0 --rpc.port="$NODE_RPC_PORT" \
    --p2p.listen.tcp="$((NODE_RPC_PORT + 200))" \
    --p2p.listen.udp="$((NODE_RPC_PORT + 200))" \
    --p2p.static="/ip4/$NOVA_PEER_ADDR/tcp/$NOVA_P2P_PORT/p2p/$NOVA_PEER_ID" \
    --syncmode=consensus-layer \
    --syncmode.req-resp \
    > op-node.log 2>&1 &
NODE_PID=$!
echo "  op-node PID: $NODE_PID (logs: op-node.log)"

sleep 5

# Status check
BLOCK=$(curl -sf -X POST "http://127.0.0.1:$HTTP_PORT" \
    -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
    2>/dev/null | python3 -c "import sys,json; print(int(json.load(sys.stdin)['result'],16))" 2>/dev/null || echo "?")

SYNC=$(curl -sf -X POST "http://127.0.0.1:$NODE_RPC_PORT" \
    -H 'Content-Type: application/json' \
    -d '{"jsonrpc":"2.0","method":"optimism_syncStatus","params":[],"id":1}' \
    2>/dev/null | python3 -c "
import sys,json
d=json.load(sys.stdin).get('result',{})
print('unsafe_l2:', d.get('unsafe_l2',{}).get('number','?'))
" 2>/dev/null || echo "starting...")

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Chain ID    : 20260619 (OP Stack L2)"
echo " Block       : $BLOCK"
echo " Sync status : $SYNC"
echo " op-geth RPC : http://localhost:$HTTP_PORT"
echo " op-node RPC : http://localhost:$NODE_RPC_PORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Monitor sync:"
echo "   curl -s -X POST http://localhost:$NODE_RPC_PORT \\"
echo "     -H 'Content-Type: application/json' \\"
echo "     -d '{\"jsonrpc\":\"2.0\",\"method\":\"optimism_syncStatus\",\"params\":[],\"id\":1}'"
echo " Check block number:"
echo "   cast block-number --rpc-url http://localhost:$HTTP_PORT"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
