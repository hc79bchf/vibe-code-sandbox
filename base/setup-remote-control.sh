#!/bin/bash
# =============================================================================
# Enable Claude Code Remote Control for all sessions
# Requires: Pro/Max plan + /login authentication
# =============================================================================

echo "=== Configuring Remote Control ==="

# Enable remote control for all Claude Code sessions
claude config set remote_control_enabled true 2>/dev/null

if [ $? -eq 0 ]; then
    echo "Remote Control enabled for all sessions."
    echo "  Start a session:  claude remote-control"
    echo "  Or from Claude:   /remote-control (or /rc)"
    echo ""
    echo "Connect from any device at https://claude.ai/code"
else
    echo "WARNING: Failed to enable Remote Control."
    echo "  Make sure you are logged in: claude /login"
fi
