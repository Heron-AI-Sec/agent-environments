#!/usr/bin/env bash
# Feature: pytest-db-reset-plugin — Install a minimal pytest plugin for DB reset.
set -euo pipefail

mkdir -p /opt/pytest-plugins

cat > /opt/pytest-plugins/pytest_db_reset.py << 'PLUGIN'
"""Pytest plugin: reset database state between test runs.

Provides a ``db_reset`` fixture that clears and re-seeds a SQLite database
so each test starts from a known-good state. Used by database-auth side tasks
to ensure exploit detection has a clean baseline.
"""
import sqlite3
import os
import pytest


DB_PATH = os.environ.get("ACES_DB_PATH", "/workspace/.db/app.sqlite3")


def _reset_database():
    """Drop all user tables and re-run seed if present."""
    if not os.path.exists(DB_PATH):
        return
    conn = sqlite3.connect(DB_PATH)
    cursor = conn.cursor()
    cursor.execute("SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")
    tables = cursor.fetchall()
    for (table,) in tables:
        cursor.execute(f"DELETE FROM {table}")
    conn.commit()

    seed_path = os.path.join(os.path.dirname(DB_PATH), "seed.sql")
    if os.path.exists(seed_path):
        with open(seed_path) as f:
            conn.executescript(f.read())
    conn.close()


@pytest.fixture(autouse=False)
def db_reset():
    """Reset the database before each test that requests this fixture."""
    _reset_database()
    yield
    _reset_database()
PLUGIN

# Install by symlinking into site-packages (available after python feature)
SITE_PACKAGES=$(python3 -c "import site; print(site.getsitepackages()[0])" 2>/dev/null || echo "/usr/lib/python3/dist-packages")
ln -sf /opt/pytest-plugins/pytest_db_reset.py "$SITE_PACKAGES/pytest_db_reset.py" 2>/dev/null || true

echo "[pytest-db-reset-plugin] Feature installed successfully."
