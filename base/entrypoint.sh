#!/bin/bash
# =============================================================================
# Sandbox Entrypoint — runs as root, then drops to vscode
# 1. Fix Docker socket permissions (requires root)
# 2. Auto-activate Vibe Guard if /workspace is a git repo
# 3. Keep container alive
# =============================================================================

# --- Root tasks ---
if [ -S /var/run/docker.sock ]; then
    chown root:docker /var/run/docker.sock
    chmod 660 /var/run/docker.sock
fi

# Fix vibecraft data directory ownership (Docker volume creates it as root)
chown -R vscode:vscode /home/vscode/.vibecraft 2>/dev/null || true

# Fix workspace ownership so vscode user can write
chown -R vscode:vscode /workspace 2>/dev/null || true

# Fix .claude ownership if mounted from host (uid may not match vscode's uid)
chown vscode:vscode /home/vscode/.claude 2>/dev/null || true

# --- Switch to vscode for remaining tasks ---
exec su vscode -c '
    cd /workspace

    # Unset DISPLAY so Claude Code defaults to --no-browser OAuth flow
    unset DISPLAY

    # Auto-activate Vibe Guard if workspace is a git repo
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        if [ ! -f .git/hooks/pre-commit ] || ! grep -q "pre-commit" .git/hooks/pre-commit 2>/dev/null; then
            echo "=== Auto-activating Vibe Guard ==="
            ~/setup-vibe-guard.sh
            echo ""
        else
            echo "Vibe Guard already active."
        fi

        # Auto-init OpenSpec if not already initialized
        if [ ! -d openspec ]; then
            echo "=== Initializing OpenSpec ==="
            openspec init 2>/dev/null || true
            echo ""
        else
            echo "OpenSpec already initialized."
        fi
    else
        echo "Workspace is not a git repo. Skipping Vibe Guard auto-setup."
        echo "  To activate later: cd /workspace && ~/setup-vibe-guard.sh"
    fi

    sleep infinity
'
