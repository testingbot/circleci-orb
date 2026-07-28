#!/bin/bash
set -euo pipefail

INSTALL_DIR="${TB_INSTALL_DIR/#\~/$HOME}"
JAR="$INSTALL_DIR/testingbot-tunnel.jar"
LOGFILE="${TB_LOGFILE/#\~/$HOME}"
READY_FILE="/tmp/testingbot-tunnel-ready"
PID_FILE="/tmp/testingbot-tunnel.pid"

if [ ! -f "$JAR" ]; then
    echo "TestingBot Tunnel is not installed at $JAR. Run the install_tunnel command first." >&2
    exit 1
fi

TESTINGBOT_KEY="${!TB_PARAM_KEY:-}"
TESTINGBOT_SECRET="${!TB_PARAM_SECRET:-}"

if [ -z "$TESTINGBOT_KEY" ] || [ -z "$TESTINGBOT_SECRET" ]; then
    echo "TestingBot credentials not found." >&2
    echo "Set the $TB_PARAM_KEY and $TB_PARAM_SECRET environment variables in your" >&2
    echo "CircleCI project settings or in a context." >&2
    echo "You can find your key and secret at https://testingbot.com/members/user/edit" >&2
    exit 1
fi

# The tunnel reads credentials from the environment, keeping them off the
# command line and out of `ps` output.
export TESTINGBOT_KEY TESTINGBOT_SECRET

dump_logs() {
    if [ -s "${CONSOLE_LOG:-}" ]; then
        echo "--- tunnel output ---" >&2
        cat "$CONSOLE_LOG" >&2
    fi
    if [ -s "$LOGFILE" ]; then
        echo "--- tunnel log ($LOGFILE) ---" >&2
        cat "$LOGFILE" >&2
    fi
}

rm -f "$READY_FILE"

ARGS=(-f "$READY_FILE" -P "$TB_SE_PORT" -l "$LOGFILE")

# Parameter values are literal (CircleCI does not expand shell variables in
# them), so fall back to TB_TUNNEL_IDENTIFIER from the environment. That lets
# callers build an identifier at runtime via BASH_ENV.
TUNNEL_ID="${TB_PARAM_TUNNEL_IDENTIFIER:-}"
if [ -z "$TUNNEL_ID" ]; then
    TUNNEL_ID="${TB_TUNNEL_IDENTIFIER:-}"
fi

if [ -n "$TUNNEL_ID" ]; then
    echo "Using tunnel identifier: $TUNNEL_ID"
    ARGS+=(-i "$TUNNEL_ID")
fi

if [ -n "${TB_EXTRA_ARGS:-}" ]; then
    # Intentional word splitting: extra_args is a space-separated flag list.
    # shellcheck disable=SC2206
    ARGS+=($TB_EXTRA_ARGS)
fi

# Keep the tunnel's own stdout/stderr: fatal errors (bad credentials, tunnel
# limit reached) are reported there before the log file is opened.
CONSOLE_LOG="${LOGFILE}.console"
nohup java -jar "$JAR" "${ARGS[@]}" > "$CONSOLE_LOG" 2>&1 &
TUNNEL_PID=$!
echo "$TUNNEL_PID" > "$PID_FILE"
echo "TestingBot Tunnel starting (pid $TUNNEL_PID), waiting up to ${TB_READY_TIMEOUT}s..."

ELAPSED=0
while [ ! -f "$READY_FILE" ]; do
    if ! kill -0 "$TUNNEL_PID" 2>/dev/null; then
        echo "TestingBot Tunnel exited before becoming ready." >&2
        dump_logs
        rm -f "$PID_FILE"
        exit 1
    fi
    if [ "$ELAPSED" -ge "$TB_READY_TIMEOUT" ]; then
        echo "TestingBot Tunnel did not become ready within ${TB_READY_TIMEOUT}s." >&2
        dump_logs
        kill "$TUNNEL_PID" 2>/dev/null || true
        rm -f "$PID_FILE"
        exit 1
    fi
    sleep 2
    ELAPSED=$((ELAPSED + 2))
done

echo "TestingBot Tunnel is ready."
echo "Point your tests at http://localhost:${TB_SE_PORT}/wd/hub"
