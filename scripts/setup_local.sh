#!/bin/bash
set -e

# Configuration
DATADIR="./data"
GENESIS_FILE="genesis.json"
SERVER_IP="141.11.156.4"
SERVER_USER="oracle-school"
SERVER_PATH="~/workshop-06-arra-oracle-blockchain/genesis.json"

echo "=== Initializing Local Synced Node ==="

# 1. Copy genesis.json from server
echo "Fetching genesis.json from server ($SERVER_IP)..."
scp -o ConnectTimeout=5 "$SERVER_USER@$SERVER_IP:$SERVER_PATH" "$GENESIS_FILE"
echo "genesis.json successfully copied from server."

# 2. Initialize Geth datadir
echo "Initializing Geth database locally..."
geth init --datadir "$DATADIR" "$GENESIS_FILE"

echo "=== Local Setup Complete ==="
