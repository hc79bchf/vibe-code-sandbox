#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/../base"

# Check for .env
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo ""
    echo "ERROR: No .env file found."
    echo ""
    echo "Set up your sandbox:"
    echo "  1. Copy .env.example:  cp .env.example .env"
    echo "  2. Edit .env with SANDBOX_NAME and PROJECT_PATH"
    echo "  3. Re-run:             bash launch.sh"
    exit 1
fi

# Load config
source "$SCRIPT_DIR/.env"

# Validate SANDBOX_NAME
if [ -z "$SANDBOX_NAME" ]; then
    echo "ERROR: SANDBOX_NAME not set in .env"
    exit 1
fi

CONTAINER_NAME="${SANDBOX_NAME}-sandbox"

echo "=== ${SANDBOX_NAME} Sandbox Launcher ==="

# Validate PROJECT_PATH exists
RESOLVED_PATH="${PROJECT_PATH/#\~/$HOME}"
if [ ! -d "$RESOLVED_PATH" ]; then
    echo ""
    echo "ERROR: PROJECT_PATH does not exist: $PROJECT_PATH"
    echo "  Resolved to: $RESOLVED_PATH"
    echo ""
    echo "Either clone the repo there or update .env with the correct path."
    exit 1
fi
echo "Project path: $RESOLVED_PATH"

# Auto-detect available dashboard port (avoids collisions with other sandboxes)
DASHBOARD_PORT=${DASHBOARD_PORT:-8080}
while lsof -i :"$DASHBOARD_PORT" >/dev/null 2>&1; do
    DASHBOARD_PORT=$((DASHBOARD_PORT + 1))
done
export DASHBOARD_PORT

# Build base image if it doesn't exist
if ! docker image inspect vibe-sandbox-base >/dev/null 2>&1; then
    echo "Base image not found. Building..."
    cd "$BASE_DIR" && bash build.sh
    cd "$SCRIPT_DIR"
fi

# Stop and remove any existing sandbox container
echo "Cleaning up existing containers..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null || true
docker compose down -v 2>/dev/null || true

# Build the project image
echo "Building project image..."
docker compose build sandbox

# Launch the sandbox container in detached mode
echo "Starting sandbox container..."
docker compose up -d

# Verify the container is running
echo ""
echo "=== Container Status ==="
docker ps --filter name="$CONTAINER_NAME" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"

echo ""
echo "Sandbox is ready. Attach with:"
echo "  docker exec -it $CONTAINER_NAME /bin/bash"
echo ""
echo "Workspace mounted from: $RESOLVED_PATH"
echo "Claude UI Dashboard:    http://localhost:$DASHBOARD_PORT"
echo "Plugins (superpowers, dev-browser) are pre-installed."
echo "Vibe Guard auto-activates on startup (if workspace is a git repo)."
echo "To update plugins:     docker exec -it $CONTAINER_NAME ~/setup-plugins.sh"
echo "To disable Vibe Guard: docker exec -it $CONTAINER_NAME bash -c 'cd /workspace && ~/disable-vibe-guard.sh'"
