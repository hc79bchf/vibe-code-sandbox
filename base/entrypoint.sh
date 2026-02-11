#!/bin/bash
# =============================================================================
# Sandbox Entrypoint — runs as root, then drops to vscode
# 1. Fix Docker socket permissions (requires root)
# 2. Configure Claude Code hooks for ntfy.sh notifications
# 3. Start Claude UI Dashboard (nginx as root, backend as vscode)
# 4. Auto-activate Vibe Guard if /workspace is a git repo
# 5. Keep container alive
# =============================================================================

# --- Root tasks ---
if [ -S /var/run/docker.sock ]; then
    chown root:docker /var/run/docker.sock
    chmod 660 /var/run/docker.sock
fi

# Configure Claude Code hooks for ntfy.sh push notifications
# Uses SANDBOX_NAME env var (from docker-compose) as the ntfy topic
su vscode -c "HOME=/home/vscode /home/vscode/setup-hooks.sh '${SANDBOX_NAME:-sandbox}'"

# Start nginx reverse proxy for Claude UI Dashboard (requires root)
nginx

# --- Switch to vscode for remaining tasks ---
exec su vscode -c '
    # Start Claude UI Dashboard backend
    cd /home/vscode/claude-ui/server
    HOME=/home/vscode node dist/index.js > /tmp/dashboard-backend.log 2>&1 &
    echo "=== Claude UI Dashboard started on port 8080 ==="

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
