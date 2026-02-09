#!/bin/bash
# =============================================================================
# Vibe Guard — Initialize security scanning for a project
# Sets up pre-commit hooks and runs initial security scan.
# Run once per project: ~/setup-vibe-guard.sh
# =============================================================================
set -e

echo "=== Vibe Guard Setup ==="

# Check we're in a git repo
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: Not inside a git repository."
    echo "  cd /workspace && git init  (or clone your repo first)"
    exit 1
fi

# Copy pre-commit config if not present
if [ ! -f .pre-commit-config.yaml ]; then
    echo "Adding .pre-commit-config.yaml..."
    cp ~/pre-commit-config.yaml .pre-commit-config.yaml
    echo "  Copied default Vibe Guard config."
else
    echo "  .pre-commit-config.yaml already exists, skipping."
fi

# Install pre-commit hooks
echo "Installing pre-commit hooks..."
pre-commit install
echo "  Hooks installed. Scans will run on every commit."

# Run initial security scan
echo ""
echo "=== Running Initial Security Scan ==="
echo ""
echo "--- Trivy (vulnerability + secret scan) ---"
trivy fs . --scanners vuln,secret --severity HIGH,CRITICAL 2>/dev/null || echo "  (no issues found or no lock files yet)"

echo ""
echo "--- Gitleaks (secret detection) ---"
gitleaks detect --source . -v 2>/dev/null && echo "  No secrets found." || echo "  (scan complete)"

echo ""
echo "=== Vibe Guard Ready ==="
echo ""
echo "Tools available:"
echo "  ruff check --fix .          # Python lint + auto-fix"
echo "  biome check --write .       # JS/TS lint + auto-fix"
echo "  trivy fs . --scanners vuln,secret  # Vulnerability scan"
echo "  gitleaks detect --source .  # Secret detection"
echo ""
echo "Pre-commit hooks will auto-scan on every git commit."
