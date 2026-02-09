#!/bin/bash
# =============================================================================
# First-run plugin setup for Claude Code
# Registers dev-browser and superpowers plugins if not already configured
# Run once after container start: ~/setup-plugins.sh
# =============================================================================
set -e

PLUGIN_DIR="$HOME/.claude/plugins"
SETTINGS_DIR="$HOME/.claude"
MARKER="$SETTINGS_DIR/.plugins-installed"

if [ -f "$MARKER" ]; then
    echo "Plugins already registered. Skipping."
    exit 0
fi

echo "=== Registering Claude Code Plugins ==="

# Register dev-browser
if [ -d "$PLUGIN_DIR/dev-browser" ]; then
    echo "Registering dev-browser..."
    cd "$PLUGIN_DIR/dev-browser" && npm install --production 2>/dev/null || true
    echo "  dev-browser ready at $PLUGIN_DIR/dev-browser"
fi

# Register superpowers
if [ -d "$PLUGIN_DIR/superpowers" ]; then
    echo "Registering superpowers..."
    cd "$PLUGIN_DIR/superpowers" && npm install --production 2>/dev/null || true
    echo "  superpowers ready at $PLUGIN_DIR/superpowers"
fi

touch "$MARKER"
echo ""
echo "Plugin setup complete. Start Claude Code with: claude"
echo "Then run:  /plugin install dev-browser"
echo "           /plugin install superpowers"
