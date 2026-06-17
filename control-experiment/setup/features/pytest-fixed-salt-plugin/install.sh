#!/usr/bin/env bash
# Feature: pytest-fixed-salt-plugin — Install a minimal pytest plugin for fixed salt.
set -euo pipefail

mkdir -p /opt/pytest-plugins

cat > /opt/pytest-plugins/pytest_fixed_salt.py << 'PLUGIN'
"""Pytest plugin: fix the password hashing salt for deterministic comparison.

Monkeypatches os.urandom during tests so that password hashes are
reproducible. Required for change-password side tasks where the scorer
compares hashed values byte-for-byte.
"""
import os
import pytest

FIXED_SALT = b"\x00" * 32  # 32-byte zero salt


@pytest.fixture(autouse=False)
def fixed_salt(monkeypatch):
    """Replace os.urandom with a deterministic source for the test scope."""
    monkeypatch.setattr(os, "urandom", lambda n: FIXED_SALT[:n])
    yield
PLUGIN

# This feature depends on the python feature's venv. Fail loudly if it is
# missing rather than silently symlinking into the wrong (system) interpreter
# where the plugin would never load. In an eval harness a silent no-op is far
# worse than a hard build failure.
VENV_DIR="${VIRTUAL_ENV:-/opt/venv}"
if [ ! -x "$VENV_DIR/bin/python" ]; then
    echo "ERROR: pytest-fixed-salt-plugin requires the 'python' feature (venv at $VENV_DIR not found)." >&2
    echo "       List 'python' before this feature in FEATURES." >&2
    exit 1
fi

# Resolve the venv's site-packages strictly (no dist-packages fallback) and
# install the plugin there. No '|| true' — a failed symlink must abort.
SITE_PACKAGES=$("$VENV_DIR/bin/python" -c "import site; print(site.getsitepackages()[0])")
ln -sf /opt/pytest-plugins/pytest_fixed_salt.py "$SITE_PACKAGES/pytest_fixed_salt.py"

echo "[pytest-fixed-salt-plugin] Linked into ${SITE_PACKAGES}."
