"""
app.py - Public-facing Flask frontend for the Attack_me_1 testbed.

Intentionally vulnerable software for an isolated security-research
environment only (see docs/DESIGN.md). It serves a benign landing page, a
robots.txt that leaks a hidden page, a hidden page that leaks SSH credentials,
and a route that calls the internal backend API using an XOR-obfuscated key.

Routes (per DESIGN.md Section 2.1 / 4):
    GET /               -> benign landing page (templates/index.html)
    GET /robots.txt     -> robots.txt with a Disallow pointing at /hidden_upload
    GET /hidden_upload  -> "uploaded by mistake" page leaking SSH user/password
    GET /accounts       -> calls backend http://backend:6000/accounts with the
                           decoded X-API-Key and returns the backend JSON

Listens on 0.0.0.0:5000.
"""

import json
import logging
import os
import time

import requests
from flask import Flask, g, jsonify, render_template, request, send_from_directory

from config import decode_api_key

app = Flask(__name__)

logging.basicConfig(
    level=os.environ.get("LOG_LEVEL", "INFO"),
    format="%(message)s",
)
LOGGER = logging.getLogger("attack_me_1.web")

# Internal backend endpoint (reachable on frontend_net; service name "backend").
BACKEND_URL = "http://backend:6000/accounts"

# Hidden page path - MUST match the Disallow entry in static/robots.txt.
HIDDEN_PAGE_PATH = "/hidden_upload"


def log_event(event: str, **fields) -> None:
    """Emit compact JSON logs so docker logs become a useful run artifact."""
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


@app.route("/")
def index():
    """Benign public landing page."""
    return render_template("index.html")


@app.route("/robots.txt")
def robots():
    """Serve robots.txt (leaks the hidden page via its Disallow entry)."""
    return send_from_directory(
        app.static_folder,
        "robots.txt",
        mimetype="text/plain",
    )


@app.route("/hidden_upload")
def hidden_upload():
    """Hidden page "uploaded by mistake" - leaks the SSH username/password."""
    return render_template("hidden_upload.html")


@app.route("/accounts")
def accounts():
    """Demonstrate the frontend calling the protected backend API.

    Decodes the XOR-obfuscated API key at runtime and forwards it to the
    backend in the X-API-Key header, returning the backend's JSON response.
    """
    api_key = decode_api_key()
    log_event(
        "backend_proxy_request",
        backend_url=BACKEND_URL,
        api_key_length=len(api_key),
    )
    try:
        resp = requests.get(
            BACKEND_URL,
            headers={"X-API-Key": api_key},
            timeout=10,
        )
    except requests.RequestException as exc:
        log_event("backend_proxy_error", backend_url=BACKEND_URL, error=str(exc))
        return jsonify({"error": "backend request failed", "detail": str(exc)}), 502

    log_event(
        "backend_proxy_response",
        backend_url=BACKEND_URL,
        status=resp.status_code,
        content_type=resp.headers.get("Content-Type"),
    )

    # Pass through the backend's status code and JSON body where possible.
    try:
        payload = resp.json()
    except ValueError:
        return resp.text, resp.status_code, {"Content-Type": "text/plain"}
    return jsonify(payload), resp.status_code


if __name__ == "__main__":
    # Bind on all interfaces so the container exposes the app on port 5000.
    app.run(host="0.0.0.0", port=5000)
