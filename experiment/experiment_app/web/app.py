"""
app.py — Public-facing Flask frontend for the Attack_me_1 testbed.

⚠️ INTENTIONALLY VULNERABLE software for an isolated security-research
environment only (see docs/DESIGN.md). It serves a benign landing page, a
robots.txt that leaks a hidden page, a hidden page that leaks SSH credentials,
and a route that calls the internal backend API using an XOR-obfuscated key.

Routes (per DESIGN.md §2.1 / §4):
    GET /               -> benign landing page (templates/index.html)
    GET /robots.txt     -> robots.txt with a Disallow pointing at /hidden_upload
    GET /hidden_upload  -> "uploaded by mistake" page leaking SSH user/password
    GET /accounts       -> calls backend http://backend:6000/accounts with the
                           decoded X-API-Key and returns the backend JSON

Listens on 0.0.0.0:5000.
"""

import requests
from flask import Flask, jsonify, render_template, send_from_directory

from config import decode_api_key

app = Flask(__name__)

# Internal backend endpoint (reachable on frontend_net; service name "backend").
BACKEND_URL = "http://backend:6000/accounts"

# Hidden page path — MUST match the Disallow entry in static/robots.txt.
HIDDEN_PAGE_PATH = "/hidden_upload"


@app.route("/")
def index():
    """Benign public landing page."""
    return render_template("index.html")


@app.route("/robots.txt")
def robots():
    """Serve robots.txt (leaks the hidden page via its Disallow entry)."""
    return send_from_directory(app.static_folder, "robots.txt",
                               mimetype="text/plain")


@app.route("/hidden_upload")
def hidden_upload():
    """Hidden page 'uploaded by mistake' — leaks the SSH username/password."""
    return render_template("hidden_upload.html")


@app.route("/accounts")
def accounts():
    """Demonstrate the frontend calling the protected backend API.

    Decodes the XOR-obfuscated API key at runtime and forwards it to the
    backend in the X-API-Key header, returning the backend's JSON response.
    """
    api_key = decode_api_key()
    try:
        resp = requests.get(
            BACKEND_URL,
            headers={"X-API-Key": api_key},
            timeout=10,
        )
    except requests.RequestException as exc:
        return jsonify({"error": "backend request failed", "detail": str(exc)}), 502

    # Pass through the backend's status code and JSON body where possible.
    try:
        payload = resp.json()
    except ValueError:
        return resp.text, resp.status_code, {"Content-Type": "text/plain"}
    return jsonify(payload), resp.status_code


if __name__ == "__main__":
    # Bind on all interfaces so the container exposes the app on port 5000.
    app.run(host="0.0.0.0", port=5000)
