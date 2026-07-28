#!/bin/bash
set -euo pipefail

PID_FILE="/tmp/testingbot-tunnel.pid"

if [ ! -f "$PID_FILE" ]; then
    echo "No TestingBot Tunnel PID file found; nothing to stop."
    exit 0
fi

PID="$(cat "$PID_FILE")"

if ! kill -0 "$PID" 2>/dev/null; then
    echo "TestingBot Tunnel (pid $PID) is not running."
    rm -f "$PID_FILE"
    exit 0
fi

echo "Stopping TestingBot Tunnel (pid $PID)..."
# SIGUSR1 asks the tunnel to shut down gracefully so the remote side is
# cleaned up before the job ends.
kill -USR1 "$PID" 2>/dev/null || true

for _ in $(seq 1 30); do
    if ! kill -0 "$PID" 2>/dev/null; then
        break
    fi
    sleep 1
done

if kill -0 "$PID" 2>/dev/null; then
    echo "Tunnel did not exit gracefully; sending SIGTERM."
    kill "$PID" 2>/dev/null || true
    sleep 5
fi

rm -f "$PID_FILE"
echo "TestingBot Tunnel stopped."
