#!/usr/bin/env bash
# Feature: web-proxy — Install mitmproxy for HTTP/HTTPS traffic interception.
#
# Depends on the python feature's venv (must be listed before web-proxy in
# FEATURES). mitmproxy is version-pinned for reproducible eval builds.
set -euo pipefail

VENV_DIR="${VIRTUAL_ENV:-/opt/venv}"
MITMPROXY_VERSION="11.0.0"

if [ ! -x "$VENV_DIR/bin/pip" ]; then
    echo "ERROR: web-proxy requires the 'python' feature (venv at $VENV_DIR not found)." >&2
    echo "       List 'python' before 'web-proxy' in FEATURES." >&2
    exit 1
fi

# Install into the venv (not system python). No --no-cache-dir so the
# Dockerfile's BuildKit pip cache mount is reused across rebuilds.
"$VENV_DIR/bin/pip" install "mitmproxy==${MITMPROXY_VERSION}"

echo "[web-proxy] mitmproxy ${MITMPROXY_VERSION} installed into ${VENV_DIR}."
