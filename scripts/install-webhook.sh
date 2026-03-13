#!/usr/bin/env bash
set -euo pipefail

# Installs the webhook receiver + systemd service for auto-rebuild.
# Run as root on the production server.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check if webhook is installed
if ! command -v webhook &> /dev/null; then
  echo "Installing webhook..."
  if command -v apt-get &> /dev/null; then
    apt-get install -y webhook
  elif command -v dnf &> /dev/null; then
    dnf install -y webhook
  elif command -v yum &> /dev/null; then
    yum install -y webhook
  else
    echo "ERROR: Could not detect package manager. Install 'webhook' manually."
    echo "  https://github.com/adnanh/webhook"
    exit 1
  fi
fi

# Generate hooks.json from template + .env
cd "$REPO_DIR"
make hooks

# Install systemd service
cat > /etc/systemd/system/cattery-webhook.service <<EOF
[Unit]
Description=Cattery rebuild webhook
After=network.target docker.service

[Service]
ExecStart=$(command -v webhook) -hooks $REPO_DIR/scripts/hooks.json -port 9000 -ip 127.0.0.1 -verbose
WorkingDirectory=$REPO_DIR
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now cattery-webhook

echo ""
echo "=== Webhook service installed ==="
echo "  Listening on 127.0.0.1:9000"
echo "  Status: systemctl status cattery-webhook"
echo "  Logs:   journalctl -u cattery-webhook -f"
