#!/bin/bash
# =============================================================================
# Configure Claude Code settings at container startup
# Usage: setup-hooks.sh <topic>
#   - ntfy.sh push notifications on Stop and Notification events
#   - Agent Teams experimental feature
# =============================================================================

TOPIC="${1:-sandbox}"
SETTINGS="$HOME/.claude/settings.json"

if [ ! -f "$SETTINGS" ]; then
    echo "No settings.json found at $SETTINGS, skipping setup"
    exit 0
fi

# Merge hooks + agent teams env into existing settings (preserves plugins, permissions)
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
}
| .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"

echo "=== ntfy.sh notifications enabled (topic: ${TOPIC}-sandbox) ==="
echo "=== Agent Teams enabled ==="
