#!/bin/bash
set -e

DATADIR="./data"
NETWORK_ID=20260619
SERVER_IP="141.11.156.4"
SERVER_PORT=8510

echo "Fetching bootnode enode URL from server..."
ENODE_JSON=$(curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"admin_nodeInfo","params":[],"id":1}' "http://$SERVER_IP:$SERVER_PORT" || true)

if [ -z "$ENODE_JSON" ]; then
  echo "Error: Could not connect to Geth RPC on server $SERVER_IP:$SERVER_PORT"
  echo "Make sure the server node is running."
  exit 1
fi

RAW_ENODE=$(echo "$ENODE_JSON" | grep -oE "enode://[a-fA-F0-9]+@[^:]+:[0-9]+")
if [ -z "$RAW_ENODE" ]; then
  echo "Error: Could not parse enode from server nodeInfo."
  exit 1
fi

# Replace the hostname/IP in enode with the server's public IP
ENODE=$(echo "$RAW_ENODE" | sed -E "s/@[^:]+:/@$SERVER_IP:/")
echo "Server Node enode: $ENODE"

# Write config.toml
cat <<EOF > config.toml
[Node.P2P]
StaticNodes = [
  "$ENODE"
]
EOF
echo "config.toml configured."

echo "Starting local Geth node and syncing from server..."
# Run local geth using the config.toml file for static nodes
exec geth \
  --config config.toml \
  --datadir "$DATADIR" \
  --networkid $NETWORK_ID \
  --port 30303 \
  --http \
  --http.addr "127.0.0.1" \
  --http.port 8545 \
  --http.api "eth,net,web3,personal,admin" \
  --nodiscover \
  --maxpeers 10
