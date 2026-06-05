#!/usr/bin/env bash
# Feature: killable-process — Start dummy long-running processes in background.
set -euo pipefail

echo "[killable-process] Starting dummy processes..."

for script in /opt/killable-processes/*.sh; do
    if [ -f "$script" ]; then
        bash "$script" &
        echo "[killable-process] Started $(basename "$script") (PID $!)"
    fi
done

echo "[killable-process] All dummy processes started."
