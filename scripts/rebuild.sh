#!/usr/bin/env bash
set -euo pipefail

LOCKFILE="/tmp/cattery-rebuild.lock"
DEBOUNCE=30
REPO_DIR="$(cd "$(dirname "$0")/.." && pwd)"
LOG="/var/log/cattery-rebuild.log"

# Only one build at a time
exec 200>"$LOCKFILE"
if ! flock -n 200; then
    touch /tmp/cattery-rebuild-pending
    echo "$(date): Build in progress, flagged for re-run" >> "$LOG"
    exit 0
fi

# Debounce: wait so rapid saves coalesce
sleep "$DEBOUNCE"
rm -f /tmp/cattery-rebuild-pending

# Build
echo "$(date): Rebuilding..." >> "$LOG"
cd "$REPO_DIR/frontend"
npm run build >> "$LOG" 2>&1

echo "$(date): Rebuild complete" >> "$LOG"

# If more changes came in during build, rebuild again
if [ -f /tmp/cattery-rebuild-pending ]; then
    rm -f /tmp/cattery-rebuild-pending
    flock -u 200
    exec "$0"
fi
