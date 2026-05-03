#!/usr/bin/env bash
# post_session hook — suggest n8n workflow after session ends
# Hermes provides: $HERMES_SESSION_ID, $HERMES_SESSION_TOPIC, $HERMES_PROFILE

set -euo pipefail

# Only master triggers n8n suggestions
if [ "${HERMES_PROFILE:-}" != "master" ]; then
  exit 0
fi

TOPIC="${HERMES_SESSION_TOPIC:-unknown}"
SESSION_ID="${HERMES_SESSION_ID:-}"

# Skip if session was trivial (no topic extracted)
if [ "$TOPIC" = "unknown" ] || [ -z "$TOPIC" ]; then
  exit 0
fi

# Signal to master to evaluate n8n conversion
# This env var is read by master's next turn to trigger suggestion
echo "{\"type\": \"suggest_n8n\", \"session_id\": \"$SESSION_ID\", \"topic\": \"$TOPIC\"}"
exit 0
