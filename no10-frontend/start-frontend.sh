#!/bin/bash
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
pkill -f 'python3.*8085' 2>/dev/null || true
sleep 1
tmux new-session -d -s no10-frontend "python3 -m http.server 8085 --directory $DIR"
echo "Frontend launched on port 8085 using python3 http.server"
