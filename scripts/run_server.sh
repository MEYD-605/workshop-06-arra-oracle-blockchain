#!/bin/bash
set -e

DATADIR="./data"
PASSWORD_FILE="password.txt"
NETWORK_ID=20260619

# Ensure geth is available
GETH_BIN="geth"
if [ -f "$HOME/bin/geth" ]; then
  GETH_BIN="$HOME/bin/geth"
fi

if [ ! -d "$DATADIR/keystore" ]; then
  echo "Keystore directory not found. Please run scripts/setup_server.sh first."
  exit 1
fi

# Extract address from keystore
KEY_FILE=$(ls "$DATADIR/keystore/" | head -n 1)
ADDRESS_NO_0X=$(echo "$KEY_FILE" | awk -F'--' '{print $NF}')
ADDRESS="0x$ADDRESS_NO_0X"
echo "Found signer account address: $ADDRESS"

echo "Starting server Geth node..."
echo "P2P port: 30310"
echo "HTTP port: 8510"

# Run Geth node
exec $GETH_BIN \
  --datadir "$DATADIR" \
  --networkid $NETWORK_ID \
  --port 30310 \
  --http \
  --http.addr "0.0.0.0" \
  --http.port 8510 \
  --http.api "eth,net,web3,personal,miner,clique,admin" \
  --http.corsdomain "*" \
  --mine \
  --miner.etherbase "$ADDRESS" \
  --unlock "$ADDRESS" \
  --password "$PASSWORD_FILE" \
  --allow-insecure-unlock \
  --nodiscover \
  --maxpeers 10
