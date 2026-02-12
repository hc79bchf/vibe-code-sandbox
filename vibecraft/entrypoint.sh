#!/bin/bash
# =============================================================================
# Vibecraft Sandbox Entrypoint — extends base with Vibecraft 3D visualization
# 1. Fix Docker socket permissions (requires root)
# 2. Configure Claude Code hooks for ntfy.sh notifications
# 3. Start Vibecraft 3D visualization
# 4. Auto-activate Vibe Guard if /workspace is a git repo
# 5. Keep container alive
# =============================================================================

# --- Root tasks ---
if [ -S /var/run/docker.sock ]; then
    chown root:docker /var/run/docker.sock
    chmod 660 /var/run/docker.sock
fi

# Fix vibecraft data directory ownership (Docker volume creates it as root)
chown -R vscode:vscode /home/vscode/.vibecraft 2>/dev/null || true

# Configure Claude Code hooks for ntfy.sh push notifications
su vscode -c "HOME=/home/vscode /home/vscode/setup-hooks.sh '${SANDBOX_NAME:-sandbox}'"

# Patch vibecraft frontend to use the actual host port for WebSocket
# (vibecraft defaults to 4003; this ensures it matches the Docker-mapped host port)
DIST_HTML="/usr/lib/node_modules/vibecraft/dist/index.html"
HOST_PORT="${VIBECRAFT_HOST_PORT:-4003}"
if [ -f "$DIST_HTML" ]; then
    sed -i 's|<script id="vibecraft-port-override">.*</script>||' "$DIST_HTML"
    sed -i "s|<head>|<head><script id=\"vibecraft-port-override\">localStorage.setItem('vibecraft-agent-port','${HOST_PORT}');</script>|" "$DIST_HTML"
fi

# --- Switch to vscode for remaining tasks ---
exec su vscode -c '
    # Start Vibecraft 3D visualization (setup only runs once)
    cd /home/vscode
    if [ ! -f /home/vscode/.vibecraft-setup-done ]; then
        HOME=/home/vscode npx vibecraft setup 2>/dev/null || true
        touch /home/vscode/.vibecraft-setup-done
    fi
    BROWSER=none HOME=/home/vscode npx vibecraft > /tmp/vibecraft.log 2>&1 &
    echo "=== Vibecraft 3D Workshop started ==="

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
