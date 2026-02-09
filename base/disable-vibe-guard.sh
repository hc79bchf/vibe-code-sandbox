#!/bin/bash
# =============================================================================
# Vibe Guard — Disable security scanning for a project
# Uninstalls pre-commit hooks. Tools remain available for manual use.
# Run from project root: ~/disable-vibe-guard.sh
# Re-enable anytime with: ~/setup-vibe-guard.sh
# =============================================================================
set -e

echo "=== Vibe Guard Disable ==="

# Check we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: Not inside a git repository."
    exit 1
fi

# Check if hooks are installed
if ! pre-commit --version >/dev/null 2>&1; then
    echo "pre-commit is not installed. Nothing to disable."
    exit 0
fi

# Uninstall pre-commit hooks
echo "Removing pre-commit hooks..."
pre-commit uninstall
echo "  Hooks removed. Commits will no longer trigger auto-scans."

# Remove pre-commit config if it matches the default template
if [ -f .pre-commit-config.yaml ]; then
    echo ""
    echo "Note: .pre-commit-config.yaml still exists in your project."
    echo "  To remove it:  rm .pre-commit-config.yaml"
    echo "  To keep it:    it will be reused if you re-enable Vibe Guard"
fi

echo ""
echo "=== Vibe Guard Disabled ==="
echo ""
echo "Hooks are removed. Commits will skip all auto-scans."
echo "Tools are still available for manual use:"
echo "  ruff check --fix .          # Python lint + auto-fix"
echo "  biome check --write .       # JS/TS lint + auto-fix"
echo "  trivy fs . --scanners vuln,secret  # Vulnerability scan"
echo "  gitleaks detect --source .  # Secret detection"
echo ""
echo "To re-enable:  ~/setup-vibe-guard.sh"
