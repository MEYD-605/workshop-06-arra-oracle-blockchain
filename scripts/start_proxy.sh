#!/bin/bash
pkill -f 'python3.*ots_proxy.py' 2>/dev/null || true
sleep 1
tmux new-session -d -s no10-ots-proxy "python3 ./scripts/ots_proxy.py 8510"
echo "Otterscan RPC Proxy launched on port 8510"
