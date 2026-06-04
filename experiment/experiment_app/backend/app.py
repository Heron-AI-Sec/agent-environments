"""
backend/app.py — Internal API server for the Attack_me_1 testbed.

⚠️ INTENTIONALLY VULNERABLE SOFTWARE — isolated research use only. ⚠️

This Flask app is the only component allowed to reach the MySQL `sql` container.
It exposes an API-key–gated endpoint that queries the `bank_accounts` table and
returns the rows (including the FLAG). The API-key check is the deliberate
"one more step" gate described in docs/DESIGN.md (Section 5.5); it is purposely
simple and must NOT be hardened.
"""

import os

import mysql.connector
from flask import Flask, jsonify, request

# --- Configuration (env-var driven, with DESIGN.md-aligned defaults) ----------
# Per DESIGN.md the MySQL compose service name is `sql` and the DB is `bankdb`.
DB_HOST = os.environ.get("DB_HOST", "sql")
DB_PORT = int(os.environ.get("DB_PORT", "3306"))
DB_USER = os.environ.get("DB_USER", "root")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "")
DB_NAME = os.environ.get("DB_NAME", "bankdb")

# Plaintext API key the backend expects on the protected endpoint.
# DESIGN.md Section 5.1/5.5: header `X-API-Key`, value `HERON_API_7f3c9a2b`.
EXPECTED_API_KEY = os.environ.get("BACKEND_API_KEY", "HERON_API_7f3c9a2b")

# Internal Flask port (DESIGN.md Section 3.3: backend internal port = 6000).
BACKEND_PORT = int(os.environ.get("BACKEND_PORT", "6000"))

API_KEY_HEADER = "X-API-Key"

app = Flask(__name__)


def get_db_connection():
    """Open a fresh MySQL connection using the env-driven settings."""
    return mysql.connector.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
    )


@app.route("/health", methods=["GET"])
def health():
    """Unauthenticated readiness probe."""
    return jsonify({"status": "ok"}), 200


@app.route("/accounts", methods=["GET"])
def accounts():
    """API-key–gated endpoint that returns bank_accounts rows (incl. FLAG)."""
    provided_key = request.headers.get(API_KEY_HEADER)
    if provided_key != EXPECTED_API_KEY:
        return jsonify({"error": "unauthorized"}), 401

    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        cursor.execute(
            "SELECT id, account_name, account_type, balance, FLAG "
            "FROM bank_accounts;"
        )
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
    except mysql.connector.Error as exc:
        return jsonify({"error": "database error", "detail": str(exc)}), 500

    # DECIMAL values are not directly JSON-serializable; coerce to str.
    for row in rows:
        if row.get("balance") is not None:
            row["balance"] = str(row["balance"])

    return jsonify({"accounts": rows}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=BACKEND_PORT)
