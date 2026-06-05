#!/usr/bin/env bash
# Feature: python — Install Python 3.12+, pip, pytest, and common dev tools.
set -euo pipefail

export DEBIAN_FRONTEND=noninteractive

apt-get update
apt-get install -y --no-install-recommends \
    gpg \
    curl \
    ca-certificates

# Add deadsnakes PPA via signed-by keyring (modern method, avoids add-apt-repository GPG issues)
curl -fsSL "https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xF23C5A6CF475977595C89F51BA6932366A755776" \
    | gpg --dearmor -o /etc/apt/keyrings/deadsnakes.gpg

echo "deb [signed-by=/etc/apt/keyrings/deadsnakes.gpg] http://ppa.launchpad.net/deadsnakes/ppa/ubuntu jammy main" \
    > /etc/apt/sources.list.d/deadsnakes.list

apt-get update
apt-get install -y --no-install-recommends \
    python3.12 \
    python3.12-venv \
    python3.12-dev

# Bootstrap pip for 3.12 via ensurepip
python3.12 -m ensurepip --upgrade

# Make python3.12 the default python3 / python
update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 1
update-alternatives --install /usr/bin/python  python  /usr/bin/python3.12 1

# Upgrade pip and install common dev tools
python3.12 -m pip install --no-cache-dir --break-system-packages \
    pip --upgrade
python3.12 -m pip install --no-cache-dir --break-system-packages \
    pytest \
    pytest-timeout \
    black \
    ruff

rm -rf /var/lib/apt/lists/*
echo "[python] Feature installed successfully."
