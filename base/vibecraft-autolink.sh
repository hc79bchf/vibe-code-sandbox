#!/bin/bash
# =============================================================================
# Vibecraft Auto-Link — SessionStart hook
#
# Automatically links a new Claude Code session to its vibecraft managed session.
# Runs on every SessionStart event. Matches by SANDBOX_NAME → vibecraft session name.
#
# Required env vars:
#   SANDBOX_NAME           — sandbox identifier (set by docker-compose)
#   VIBECRAFT_WS_NOTIFY    — vibecraft server URL, e.g. http://host.docker.internal:4003/event
# =============================================================================

set -e

# Read hook input from stdin (Claude Code passes JSON)
input=$(cat)

# Extract the Claude Code session ID from the hook input
SESSION_ID=$(echo "$input" | jq -r '.session_id // empty' 2>/dev/null)
if [ -z "$SESSION_ID" ]; then
    exit 0
fi

# Derive vibecraft base URL from VIBECRAFT_WS_NOTIFY (strip /event suffix)
VIBECRAFT_URL="${VIBECRAFT_WS_NOTIFY%/event}"
if [ -z "$VIBECRAFT_URL" ]; then
    exit 0
fi

SANDBOX="${SANDBOX_NAME:-}"
if [ -z "$SANDBOX" ]; then
    exit 0
fi

# Query vibecraft for managed sessions and find the one matching our sandbox name
MANAGED_SESSION_ID=$(curl -sf "${VIBECRAFT_URL}/sessions" 2>/dev/null \
    | jq -r --arg name "$SANDBOX" '.sessions[] | select(.name == $name) | .id' 2>/dev/null)

if [ -z "$MANAGED_SESSION_ID" ]; then
    exit 0
fi

# Link this Claude session to the managed session
curl -sf -X POST "${VIBECRAFT_URL}/sessions/${MANAGED_SESSION_ID}/link" \
    -H 'Content-Type: application/json' \
    -d "{\"claudeSessionId\":\"${SESSION_ID}\"}" >/dev/null 2>&1 || true
