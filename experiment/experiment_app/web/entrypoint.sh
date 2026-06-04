#!/bin/sh
# entrypoint.sh - Start sshd (background) then the Flask app (foreground).
#
# Intentionally vulnerable testbed component (see docs/DESIGN.md).
# The web container runs BOTH an SSH server and the Flask frontend so that the
# documented attack chain (leaked SSH creds -> shell -> read config.py) works.

set -e

# Generate host keys if they do not already exist.
ssh-keygen -A

# Ensure the privilege-separation directory exists for sshd.
mkdir -p /run/sshd

# Start the SSH daemon in the background and send auth/session logs to stderr.
/usr/sbin/sshd -e

# Launch the Flask app in the foreground (PID 1 keeps the container alive).
exec python /app/app.py
