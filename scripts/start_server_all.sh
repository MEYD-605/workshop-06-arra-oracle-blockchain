#!/bin/bash
set -e

echo "=== Restarting Geth and Otterscan Proxy on Server ==="

# 1. Kill old sessions
echo "Stopping old sessions..."
tmux kill-session -t no10-chain 2>/dev/null || true
tmux kill-session -t no10-ots-proxy 2>/dev/null || true
pkill -f 'geth.*30310' 2>/dev/null || true
pkill -f 'python3.*ots_proxy.py' 2>/dev/null || true

sleep 2

# 2. Start Geth on port 8512 in tmux session 'no10-chain'
echo "Starting Geth node on port 8512..."
tmux new-session -d -s no10-chain "cd ~/workshop-06-arra-oracle-blockchain && ./scripts/run_server.sh > geth_run.log 2>&1"

sleep 3

# 3. Start Otterscan RPC Proxy on port 8510 in tmux session 'no10-ots-proxy'
echo "Starting Otterscan RPC Proxy on port 8510..."
./scripts/start_proxy.sh

echo "=== Spawn complete ==="
