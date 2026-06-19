#!/bin/bash
DIR="/home/oracle-school/otterscan_dist"
pkill -f 'python3.*20618' 2>/dev/null || true
sleep 1
tmux new-session -d -s no10-otterscan "python3 -m http.server 20618 --directory $DIR"
echo "Otterscan launched on port 20618 using python3 http.server"
