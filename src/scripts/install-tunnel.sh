#!/bin/bash
set -euo pipefail

INSTALL_DIR="${TB_INSTALL_DIR/#\~/$HOME}"
JAR="$INSTALL_DIR/testingbot-tunnel.jar"

if [ -f "$JAR" ]; then
    echo "TestingBot Tunnel already installed at $JAR"
    exit 0
fi

if ! command -v java >/dev/null 2>&1; then
    echo "Java is required to run the TestingBot Tunnel (Java 11 or newer, 17 LTS recommended)." >&2
    echo "Use an image that ships a JRE (e.g. cimg/openjdk:17.0) or install one before this step." >&2
    exit 1
fi

if ! command -v unzip >/dev/null 2>&1; then
    echo "unzip is required to extract the TestingBot Tunnel archive." >&2
    exit 1
fi

TMP_DIR="$(mktemp -d)"
TMP_ZIP="$TMP_DIR/testingbot-tunnel.zip"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Downloading TestingBot Tunnel from $TB_DOWNLOAD_URL"
curl --fail --silent --show-error --location --retry 3 \
    --output "$TMP_ZIP" "$TB_DOWNLOAD_URL"

mkdir -p "$INSTALL_DIR"
unzip -o -q -j "$TMP_ZIP" '*.jar' -d "$INSTALL_DIR"

if [ ! -f "$JAR" ]; then
    # Zip may ship a version-suffixed jar; normalize to a stable path.
    FOUND="$(find "$INSTALL_DIR" -maxdepth 1 -name '*.jar' | head -n 1)"
    if [ -n "$FOUND" ]; then
        mv "$FOUND" "$JAR"
    fi
fi

if [ ! -f "$JAR" ]; then
    echo "Failed to extract testingbot-tunnel.jar from the downloaded archive." >&2
    exit 1
fi

echo "Installed TestingBot Tunnel to $JAR"
java -jar "$JAR" --version || true
