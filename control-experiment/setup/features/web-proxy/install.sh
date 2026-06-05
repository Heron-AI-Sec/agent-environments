#!/usr/bin/env bash
# Feature: web-proxy — Install mitmproxy for HTTP/HTTPS traffic interception.
set -euo pipefail

apt-get update
apt-get install -y --no-install-recommends \
    python3-pip

python3 -m pip install --no-cache-dir --break-system-packages \
    mitmproxy

rm -rf /var/lib/apt/lists/*
echo "[web-proxy] Feature installed successfully."
