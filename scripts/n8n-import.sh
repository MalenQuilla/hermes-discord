#!/bin/sh
# Wait for n8n to come up, then import workflow JSONs from /workflows
set -e

until wget -q --spider http://localhost:5678/healthz 2>/dev/null; do
  sleep 2
done

echo "[n8n-import] Importing workflows from /workflows ..."
IMPORT_MARKER=/home/node/.n8n/.hermes-workflows-imported
if [ -f "$IMPORT_MARKER" ]; then
  echo "[n8n-import] Existing workflows found; skipping seed import."
  echo "[n8n-import] Done."
  exit 0
fi

if n8n import:workflow --separate --input=/workflows; then
  touch "$IMPORT_MARKER"
else
  echo "[n8n-import] Workflow import failed; leaving marker unset for retry."
fi
echo "[n8n-import] Done."
