#!/bin/bash
# =============================================================================
# Configure Claude Code hooks for ntfy.sh push notifications
# Usage: setup-hooks.sh <topic>
# Sends notifications to ntfy.sh/<topic>-sandbox on Stop and Notification events
# =============================================================================

TOPIC="${1:-sandbox}"
SETTINGS="$HOME/.claude/settings.json"

if [ ! -f "$SETTINGS" ]; then
    echo "No settings.json found at $SETTINGS, skipping hooks setup"
    exit 0
fi

# Build the hooks JSON and merge into existing settings
jq --arg topic "$TOPIC" '
.hooks = {
    "Stop": [{
        "matcher": "",
        "hooks": [{
            "type": "command",
            "command": ("curl -s -d \"Claude Code finished in " + $topic + " sandbox\" ntfy.sh/" + $topic + "-sandbox")
        }]
    }],
    "Notification": [{
        "matcher": "",
        "hooks": [{
            "type": "command",
            "command": ("curl -s -d \"Attention needed in " + $topic + " sandbox\" ntfy.sh/" + $topic + "-sandbox")
        }]
    }]
}' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"

echo "=== ntfy.sh notifications enabled (topic: ${TOPIC}-sandbox) ==="
