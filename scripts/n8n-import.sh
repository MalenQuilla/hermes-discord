#!/bin/sh
# Wait for n8n to come up, then import workflow JSONs from /workflows
set -e

until wget -q --spider http://localhost:5678/healthz 2>/dev/null; do
  sleep 2
done

echo "[n8n-import] Importing workflows from /workflows ..."
n8n import:workflow --separate --input=/workflows || true
n8n import:credentials --separate --input=/workflows 2>/dev/null || true
echo "[n8n-import] Done."
