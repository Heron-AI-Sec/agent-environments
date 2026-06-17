#!/usr/bin/env bash
set -euo pipefail

# Start services for each enabled feature that has a start.sh script.
if [ -n "${FEATURES:-}" ]; then
    for feature in $(echo "$FEATURES" | tr ',' ' '); do
        start_script="/opt/features/$feature/start.sh"
        if [ -f "$start_script" ]; then
            echo "[entrypoint] Starting feature: $feature"
            chmod +x "$start_script"
            "$start_script"
        fi
    done
fi

# Execute the command passed to the container, or drop to bash.
exec "$@"
