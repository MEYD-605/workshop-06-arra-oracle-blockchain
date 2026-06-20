#!/bin/bash
# sync-chain.sh — Sync L2 OP Stack Rollup (Chain ID 20260619) for No.6 Gemini
# Usage: bash sync-chain.sh
# Requires: Docker, Docker Compose

set -e

# 1. Download canonical config files if missing
if [ ! -f genesis.json ]; then
    echo "📥 Downloading canonical genesis.json from sequencer..."
    curl -sSfL http://141.11.156.4:8181/genesis.json -o genesis.json || curl -sSfL http://141.11.156.4:8181/genesis-l2-20260619.json -o genesis.json
fi

if [ ! -f rollup.json ]; then
    echo "📥 Downloading canonical rollup.json from sequencer..."
    curl -sSfL http://141.11.156.4:8181/rollup.json -o rollup.json
fi

# 2. Generate JWT secret for Engine API if not exists
if [ ! -f jwt.txt ]; then
    echo "🔑 Generating JWT Secret..."
    openssl rand -hex 32 > jwt.txt
    chmod 600 jwt.txt
fi

# 3. Check and prepare default configuration files (.env)
if [ ! -f .env ]; then
    echo "📝 Creating default .env configuration..."
    cat << 'EOF' > .env
L1_RPC_URL=https://ethereum-sepolia-rpc.publicnode.com
L1_BEACON_URL=https://ethereum-sepolia-beacon-api.publicnode.com
EOF
fi

# 4. Create folder for Geth DB storage
mkdir -p geth-data

# 5. Initialize Geth database with genesis.json if not already initialized
if [ ! -d geth-data/geth ]; then
    echo "🧱 Initializing Geth database with genesis.json..."
    docker run --rm \
      -v "$(pwd)/geth-data:/db" \
      -v "$(pwd)/genesis.json:/config/genesis.json" \
      us-docker.pkg.dev/oplabs-tools-and-services/images/op-geth:latest \
      geth init --datadir=/db /config/genesis.json
fi

# 6. Start the Docker Compose services
echo "🚀 Starting OP Stack L2 Sync Node (op-geth + op-node)..."
docker compose up -d

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo " L2 Chain ID: 20260619 (Tokyo Chain)"
echo " RPC URL    : http://localhost:9545"
echo " WS URL     : ws://localhost:9546"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "To view logs, run: docker compose logs -f"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
