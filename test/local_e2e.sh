#!/usr/bin/env bash
#
# Run the orb end to end inside a real CircleCI job container.
#
# `circleci local execute` runs the job in Docker using the same build agent
# CircleCI uses, so this exercises the orb itself -- <<include>> script
# injection, parameter substitution, executor resolution -- and not just the
# shell scripts. The packed orb is inlined into the generated config, so no
# published version is needed.
#
# Usage:
#   test/local_e2e.sh              # full run: install, start, verify, stop
#   test/local_e2e.sh install      # install only (no credentials needed)
#   test/local_e2e.sh nocreds      # assert start fails cleanly without credentials
#
# Credentials are read from TB_KEY/TB_SECRET, falling back to a "key:secret"
# line in ~/.testingbot. They are redacted from all output.

set -euo pipefail

SCENARIO="${1:-full}"
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="$(mktemp -d)"
trap 'rm -rf "$WORK_DIR"' EXIT

for tool in circleci docker; do
    if ! command -v "$tool" >/dev/null 2>&1; then
        echo "Required tool '$tool' not found in PATH." >&2
        exit 1
    fi
done

if ! docker info >/dev/null 2>&1; then
    echo "Docker does not appear to be running; start it and try again." >&2
    exit 1
fi

TB_KEY="${TB_KEY:-}"
TB_SECRET="${TB_SECRET:-}"

if [ -z "$TB_KEY" ] && [ -f "$HOME/.testingbot" ]; then
    TB_KEY="$(cut -d: -f1 "$HOME/.testingbot")"
    TB_SECRET="$(cut -d: -f2 "$HOME/.testingbot")"
fi

if [ "$SCENARIO" != "install" ] && [ "$SCENARIO" != "nocreds" ] && [ -z "$TB_KEY" ]; then
    echo "No TestingBot credentials found. Set TB_KEY and TB_SECRET, or run:" >&2
    echo "  test/local_e2e.sh install" >&2
    exit 1
fi

CONFIG="$WORK_DIR/config.yml"

{
    echo "version: 2.1"
    echo "orbs:"
    echo "  testingbot:"
    circleci orb pack "$REPO_ROOT/src" | sed 's/^/    /'
    echo "jobs:"
    echo "  e2e:"
    echo "    executor: testingbot/default"
    echo "    steps:"
    echo "      - testingbot/install_tunnel"

    if [ "$SCENARIO" = "nocreds" ]; then
        # Expected to fail: start_tunnel must exit non-zero with a clear message.
        echo "      - testingbot/start_tunnel"
    elif [ "$SCENARIO" != "install" ]; then
        echo "      - testingbot/start_tunnel:"
        echo "          tunnel_identifier: local-e2e-$$"
        # Emulated architectures make tunnel startup slower than on CircleCI.
        echo "          ready_timeout: 240"
        echo "      - run:"
        echo "          name: Verify local Selenium relay responds"
        echo "          command: |"
        echo "            curl --fail --silent --show-error --max-time 30 \\"
        echo "              http://localhost:4445/wd/hub/status | tee /tmp/status.json"
        echo "            grep -q '\"ready\":true' /tmp/status.json"
        echo "      - testingbot/stop_tunnel"
    fi

    echo "workflows:"
    echo "  e2e:"
    echo "    jobs:"
    echo "      - e2e"
} > "$CONFIG"

circleci config validate "$CONFIG" >/dev/null
echo "Generated config validated. Running scenario: $SCENARIO"

redact() {
    if [ -n "$TB_KEY" ]; then
        sed -e "s/$TB_KEY/***TB_KEY***/g" -e "s/$TB_SECRET/***TB_SECRET***/g"
    else
        cat
    fi
}

set +e
if [ "$SCENARIO" = "install" ] || [ "$SCENARIO" = "nocreds" ]; then
    circleci local execute e2e --config "$CONFIG" 2>&1 | redact
else
    circleci local execute e2e --config "$CONFIG" \
        -e TB_KEY="$TB_KEY" -e TB_SECRET="$TB_SECRET" 2>&1 | redact
fi
STATUS="${PIPESTATUS[0]}"
set -e

if [ "$SCENARIO" = "nocreds" ]; then
    if [ "$STATUS" -eq 0 ]; then
        echo "FAIL: start_tunnel succeeded without credentials; it should have failed." >&2
        exit 1
    fi
    echo "PASS: start_tunnel failed as expected without credentials."
    exit 0
fi

if [ "$STATUS" -ne 0 ]; then
    echo "FAIL: job exited with status $STATUS" >&2
    exit "$STATUS"
fi

echo "PASS: scenario '$SCENARIO' completed successfully."
