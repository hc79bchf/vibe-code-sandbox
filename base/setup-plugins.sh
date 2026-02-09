#!/bin/bash
# =============================================================================
# Plugin verification & update for Claude Code
# Marketplaces and plugins are pre-installed during image build.
# Run this to update plugins or re-install if missing: ~/setup-plugins.sh
# =============================================================================
set -e

echo "=== Claude Code Plugin Status ==="

# Ensure marketplaces are registered
claude plugin marketplace add obra/superpowers-marketplace 2>/dev/null || true
claude plugin marketplace add sawyerhood/dev-browser 2>/dev/null || true

# Ensure plugins are installed
claude plugin install superpowers@superpowers-marketplace 2>/dev/null || true
claude plugin install dev-browser@dev-browser-marketplace 2>/dev/null || true

echo ""
echo "Installed plugins:"
claude plugin list 2>/dev/null || echo "  (run 'claude plugin list' to check)"

echo ""
echo "Plugin setup complete."
