#!/bin/bash
# =============================================================================
# Configure Claude Code settings at container startup
# Usage: setup-hooks.sh <topic>
#   - ntfy.sh push notifications on Stop and Notification events
#   - Vibecraft event hooks (if hook script exists)
#   - Agent Teams experimental feature
# =============================================================================

TOPIC="${1:-sandbox}"
SETTINGS="$HOME/.claude/settings.json"
VIBECRAFT_HOOK="$HOME/.vibecraft/hooks/vibecraft-hook.sh"
AUTOLINK_HOOK="$HOME/vibecraft-autolink.sh"

if [ ! -f "$SETTINGS" ]; then
    echo "No settings.json found at $SETTINGS, skipping setup"
    exit 0
fi

# Ensure vibecraft data and hooks directories exist
mkdir -p "$HOME/.vibecraft/data" "$HOME/.vibecraft/hooks"

# Copy vibecraft hook script if not already present
if [ ! -f "$VIBECRAFT_HOOK" ] && [ -f "$HOME/vibecraft-hook.sh" ]; then
    cp "$HOME/vibecraft-hook.sh" "$VIBECRAFT_HOOK"
    chmod +x "$VIBECRAFT_HOOK"
fi

# Build hooks JSON with ntfy + vibecraft
jq --arg topic "$TOPIC" --arg vhook "$VIBECRAFT_HOOK" --arg autolink "$AUTOLINK_HOOK" '
def vibecraft_hook: {
    "hooks": [{
        "type": "command",
        "command": $vhook,
        "timeout": 5
    }]
};

def vibecraft_hook_all: {
    "matcher": "*",
    "hooks": [{
        "type": "command",
        "command": $vhook,
        "timeout": 5
    }]
};

.hooks = {
    "Stop": [
        {
            "matcher": "",
            "hooks": [{
                "type": "command",
                "command": ("curl -s -d \"Claude Code finished in " + $topic + " sandbox\" ntfy.sh/" + $topic + "-sandbox")
            }]
        },
        vibecraft_hook
    ],
    "Notification": [
        {
            "matcher": "",
            "hooks": [{
                "type": "command",
                "command": ("curl -s -d \"Attention needed in " + $topic + " sandbox\" ntfy.sh/" + $topic + "-sandbox")
            }]
        },
        vibecraft_hook
    ],
    "PreToolUse": [vibecraft_hook_all],
    "PostToolUse": [vibecraft_hook_all],
    "SubagentStop": [vibecraft_hook],
    "SessionStart": [
        vibecraft_hook,
        {
            "hooks": [{
                "type": "command",
                "command": $autolink,
                "timeout": 10
            }]
        }
    ],
    "SessionEnd": [vibecraft_hook],
    "UserPromptSubmit": [vibecraft_hook]
}
| .env.CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS = "1"
' "$SETTINGS" > "${SETTINGS}.tmp" && mv "${SETTINGS}.tmp" "$SETTINGS"

echo "=== ntfy.sh notifications enabled (topic: ${TOPIC}-sandbox) ==="
echo "=== Vibecraft hooks enabled ==="
echo "=== Agent Teams enabled ==="
