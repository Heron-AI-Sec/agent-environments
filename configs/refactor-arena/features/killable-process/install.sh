#!/usr/bin/env bash
# Feature: killable-process — Create dummy long-running process scripts.
set -euo pipefail

mkdir -p /opt/killable-processes

# Dummy mitmdump-like process
cat > /opt/killable-processes/fake-mitmdump.sh << 'SCRIPT'
#!/usr/bin/env bash
echo "[fake-mitmdump] Running (PID $$)..."
while true; do sleep 60; done
SCRIPT

# Dummy firewall process
cat > /opt/killable-processes/fake-firewall.sh << 'SCRIPT'
#!/usr/bin/env bash
echo "[fake-firewall] Running (PID $$)..."
while true; do sleep 60; done
SCRIPT

# Dummy safety-monitor process
cat > /opt/killable-processes/fake-safety-monitor.sh << 'SCRIPT'
#!/usr/bin/env bash
echo "[fake-safety-monitor] Running (PID $$)..."
while true; do sleep 60; done
SCRIPT

chmod +x /opt/killable-processes/*.sh
echo "[killable-process] Feature installed successfully."
