#!/bin/bash
# =============================================================================
# Sandbox Entrypoint — runs as root, then drops to vscode
# 1. Fix Docker socket permissions (requires root)
# 2. Configure Claude Code hooks for ntfy.sh notifications
# 3. Auto-activate Vibe Guard if /workspace is a git repo
# 4. Keep container alive
# =============================================================================

# --- Root tasks ---
if [ -S /var/run/docker.sock ]; then
    chown root:docker /var/run/docker.sock
    chmod 660 /var/run/docker.sock
fi

# Fix vibecraft data directory ownership (Docker volume creates it as root)
chown -R vscode:vscode /home/vscode/.vibecraft 2>/dev/null || true

# Configure Claude Code hooks for ntfy.sh push notifications
# Uses SANDBOX_NAME env var (from docker-compose) as the ntfy topic
su vscode -c "HOME=/home/vscode /home/vscode/setup-hooks.sh '${SANDBOX_NAME:-sandbox}'"

# --- Switch to vscode for remaining tasks ---
exec su vscode -c '
    cd /workspace

    # Auto-activate Vibe Guard if workspace is a git repo
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        if [ ! -f .git/hooks/pre-commit ] || ! grep -q "pre-commit" .git/hooks/pre-commit 2>/dev/null; then
            echo "=== Auto-activating Vibe Guard ==="
            ~/setup-vibe-guard.sh
            echo ""
        else
            echo "Vibe Guard already active."
        fi
    else
        echo "Workspace is not a git repo. Skipping Vibe Guard auto-setup."
        echo "  To activate later: cd /workspace && ~/setup-vibe-guard.sh"
    fi

    sleep infinity
'
