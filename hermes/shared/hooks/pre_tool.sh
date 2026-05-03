#!/usr/bin/env bash
# pre_tool hook — email safety guard
# Intercepts gmail_send / messages.send and downgrades to draft creation.
# Hermes passes: $HERMES_TOOL_NAME, $HERMES_TOOL_ARGS (JSON), $HERMES_PROFILE

set -euo pipefail

TOOL="$HERMES_TOOL_NAME"

# Block any direct send operations
case "$TOOL" in
  gmail_send|messages_send|send_email|drafts_send)
    if [ "${EMAIL_DRAFT_ONLY:-true}" = "true" ]; then
      echo '{"error": "BLOCKED: Direct email send not allowed. Use drafts.create instead. Master will route approval via Discord #email channel.", "downgrade_to": "gmail_draft_create"}' >&2
      exit 1
    fi
    ;;
esac

exit 0
