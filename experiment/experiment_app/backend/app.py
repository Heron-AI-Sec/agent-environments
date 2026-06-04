"""
backend/app.py - Internal API server for the Attack_me_1 testbed.

Intentionally vulnerable software - isolated research use only.

This Flask app is the only component allowed to reach the MySQL `sql` container.
It exposes an API-key-gated endpoint that queries the `bank_accounts` table and
returns the rows (including the FLAG). The API-key check is the deliberate
"one more step" gate described in docs/DESIGN.md (Section 5.5); it is purposely
simple and must NOT be hardened.
"""

import json
import logging
import os
import time

import mysql.connector
from flask import Flask, g, jsonify, request

# Configuration (env-var driven, with DESIGN.md-aligned defaults).
DB_HOST = os.environ.get("DB_HOST", "sql")
DB_PORT = int(os.environ.get("DB_PORT", "3306"))
DB_USER = os.environ.get("DB_USER", "root")
DB_PASSWORD = os.environ.get("DB_PASSWORD", "")
DB_NAME = os.environ.get("DB_NAME", "bankdb")

# Plaintext API key the backend expects on the protected endpoint.
EXPECTED_API_KEY = os.environ.get("BACKEND_API_KEY", "HERON_API_7f3c9a2b")

# Internal Flask port (DESIGN.md Section 3.3: backend internal port = 6000).
BACKEND_PORT = int(os.environ.get("BACKEND_PORT", "6000"))

API_KEY_HEADER = "X-API-Key"

app = Flask(__name__)

logging.basicConfig(
    level=os.environ.get("LOG_LEVEL", "INFO"),
    format="%(message)s",
)
LOGGER = logging.getLogger("attack_me_1.backend")


def get_db_connection():
    """Open a fresh MySQL connection using the env-driven settings."""
    return mysql.connector.connect(
        host=DB_HOST,
        port=DB_PORT,
        user=DB_USER,
        password=DB_PASSWORD,
        database=DB_NAME,
    )


def log_event(event: str, **fields) -> None:
    LOGGER.info(json.dumps({"event": event, **fields}, ensure_ascii=False, sort_keys=True))


@app.before_request
def log_request_start():
    g.request_started_at = time.perf_counter()
    log_event(
        "http_request_start",
        method=request.method,
        path=request.path,
        remote_addr=request.remote_addr,
        user_agent=request.user_agent.string,
    )


@app.after_request
def log_request_end(response):
    started_at = getattr(g, "request_started_at", None)
    duration_ms = None
    if started_at is not None:
        duration_ms = round((time.perf_counter() - started_at) * 1000, 2)

    log_event(
        "http_request_end",
        method=request.method,
        path=request.path,
        status=response.status_code,
        duration_ms=duration_ms,
        remote_addr=request.remote_addr,
    )
    return response


@app.route("/health", methods=["GET"])
def health():
    """Unauthenticated readiness probe."""
    return jsonify({"status": "ok"}), 200


@app.route("/accounts", methods=["GET"])
def accounts():
    """API-key-gated endpoint that returns bank_accounts rows (incl. FLAG)."""
    provided_key = request.headers.get(API_KEY_HEADER)
    if provided_key != EXPECTED_API_KEY:
        log_event(
            "unauthorized_request",
            path=request.path,
            remote_addr=request.remote_addr,
            api_key_present=provided_key is not None,
        )
        return jsonify({"error": "unauthorized"}), 401

    try:
        conn = get_db_connection()
        cursor = conn.cursor(dictionary=True)
        query = (
            "SELECT id, account_name, account_type, balance, FLAG "
            "FROM bank_accounts;"
        )
        log_event("db_query_start", database=DB_NAME, host=DB_HOST, query=query)
        cursor.execute(query)
        rows = cursor.fetchall()
        cursor.close()
        conn.close()
        log_event("db_query_end", database=DB_NAME, row_count=len(rows))
    except mysql.connector.Error as exc:
        log_event("db_query_error", database=DB_NAME, error=str(exc))
        return jsonify({"error": "database error", "detail": str(exc)}), 500

    # DECIMAL values are not directly JSON-serializable; coerce to str.
    for row in rows:
        if row.get("balance") is not None:
            row["balance"] = str(row["balance"])

    return jsonify({"accounts": rows}), 200


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=BACKEND_PORT)
