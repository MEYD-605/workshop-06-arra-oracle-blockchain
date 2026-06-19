#!/bin/bash
# sync-chain.sh — Sync Tokyo Chain (Chain ID 20260619) from server for No.6 Gemini
# Usage: bash sync-chain.sh
# Requires: Docker

set -e

CHAIN_ID=20260619
CONTAINER=oracle-chain-sync-no6
DATADIR="$HOME/.oracle-chain-data-no6"
GETH_IMAGE="ethereum/client-go:v1.13.15"
SERVER_ENODE="enode://977e5865fb597d1c30780c15eff2af222afa994d83bfc1a9e5c9c41f0491a9284e32fe43052e9014d809db94e2f38a85ccef857f87d470e060dc75d88d7fd4d2@141.11.156.4:30303"

GENESIS=$(cat <<'EOF'
{
  "config": {
    "chainId": 20260619,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "muirGlacierBlock": 0,
    "berlinBlock": 0,
    "londonBlock": 0,
    "arrowGlacierBlock": 0,
    "grayGlacierBlock": 0,
    "clique": { "period": 5, "epoch": 30000 }
  },
  "difficulty": "1",
  "gasLimit": "30000000",
  "extradata": "0x00000000000000000000000000000000000000000000000000000000000000000c849857250fb8cb3fc13e25580a13e7547c9b600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "alloc": {
    "0x0c849857250fb8cb3fc13e25580a13e7547c9b60": {
      "balance": "1000000000000000000000000000"
    }
  }
}
EOF
)

echo "[1/4] Preparing data dir..."
mkdir -p "$DATADIR/geth"
echo "$GENESIS" > /tmp/oracle-genesis.json

echo "$GENESIS" | python3 -c "
import sys, json
d = json.load(sys.stdin)
assert d['config']['chainId'] == 20260619
print('  genesis chainId:', d['config']['chainId'], '✓')
"

echo "[2/4] Init genesis (docker)..."
docker run --rm \
  -v "$DATADIR":/data \
  -v /tmp/oracle-genesis.json:/genesis.json \
  "$GETH_IMAGE" \
  --datadir /data init /genesis.json 2>&1 | grep -E 'hash|error|success|Wrote' | head -3

echo "[3/4] Writing static-nodes (bootnode)..."
cat > "$DATADIR/geth/static-nodes.json" << NODES
["$SERVER_ENODE"]
NODES

echo "[4/4] Starting sync container..."
docker rm -f "$CONTAINER" 2>/dev/null || true
docker run -d --name "$CONTAINER" \
  -v "$DATADIR":/data \
  -p 8545:8545 \
  "$GETH_IMAGE" \
  --datadir /data \
  --networkid $CHAIN_ID \
  --http --http.addr 0.0.0.0 --http.port 8545 --http.api "eth,net,admin" \
  --http.vhosts "*" \
  --port 30303 \
  --authrpc.port 8651 \
  --nodiscover \
  --syncmode full \
  > /dev/null

echo ""
echo "Waiting for sync..."
sleep 12

BLOCK=$(docker exec "$CONTAINER" geth attach --exec "eth.blockNumber" /data/geth.ipc 2>/dev/null || \
  curl -s -X POST http://localhost:8545 -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' | \
  python3 -c "import sys,json; print(int(json.load(sys.stdin)['result'],16))" 2>/dev/null || echo "0")

PEERS=$(curl -s -X POST http://localhost:8545 -H 'Content-Type: application/json' \
  -d '{"jsonrpc":"2.0","method":"net_peerCount","params":[],"id":1}' | \
  python3 -c "import sys,json; print(int(json.load(sys.stdin)['result'],16))" 2>/dev/null || echo "0")

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " Chain ID : 20260619"
echo " Block    : $BLOCK"
echo " Peers    : $PEERS"
echo " RPC      : http://localhost:8545"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " cast chain-id --rpc-url http://localhost:8545"
echo " cast block-number --rpc-url http://localhost:8545"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
