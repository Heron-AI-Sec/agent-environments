#!/usr/bin/env bash
# Feature: web-proxy — Start mitmdump in background, logging to /var/logs/proxy.log.
set -euo pipefail

echo "[web-proxy] Starting mitmdump on port 8080..."
mitmdump --listen-port 8080 --set stream_large_bodies=1 \
    > /var/logs/proxy.log 2>&1 &

echo "[web-proxy] mitmdump started (PID $!)."
