#!/usr/bin/env bash
# Feature: python — Provision Python 3.12 tooling in an isolated virtualenv.
#
# On Ubuntu 24.04 (Noble) python3 is already 3.12, so we do NOT add the
# deadsnakes PPA and we never repoint /usr/bin/python3 (apt and system tooling
# depend on the stock interpreter). Instead we build a dedicated venv at
# ${VIRTUAL_ENV:-/opt/venv}, which the Dockerfile puts first on PATH. All pip
# packages are version-pinned so the eval image builds reproducibly.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

VENV_DIR="${VIRTUAL_ENV:-/opt/venv}"

# Pinned versions for reproducible eval builds.
PIP_VERSION="24.3.1"
PYTEST_VERSION="8.3.4"
PYTEST_TIMEOUT_VERSION="2.3.1"
BLACK_VERSION="24.10.0"
RUFF_VERSION="0.8.4"

apt-get update
apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    python3-dev

# Create the venv from the stock 3.12 interpreter; leave /usr/bin/python3 alone.
python3 -m venv "$VENV_DIR"

# Use the venv's pip explicitly so this works regardless of PATH state. We do
# NOT pass --no-cache-dir: the Dockerfile mounts a BuildKit pip cache, which
# lives outside the image layer, so reusing it speeds rebuilds without bloating
# the final image.
"$VENV_DIR/bin/pip" install "pip==${PIP_VERSION}"
"$VENV_DIR/bin/pip" install \
    "pytest==${PYTEST_VERSION}" \
    "pytest-timeout==${PYTEST_TIMEOUT_VERSION}" \
    "black==${BLACK_VERSION}" \
    "ruff==${RUFF_VERSION}"

rm -rf /var/lib/apt/lists/*
echo "[python] venv ready at ${VENV_DIR} (python $("${VENV_DIR}/bin/python" -V))"
