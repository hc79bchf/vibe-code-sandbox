#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/../base"

echo "=== Claude UI Sandbox Launcher ==="

# Check for .env with PROJECT_PATH
if [ ! -f "$SCRIPT_DIR/.env" ]; then
    echo ""
    echo "ERROR: No .env file found."
    echo ""
    echo "Set up your project workspace:"
    echo "  1. Clone your project repo:  git clone <repo-url> ~/projects/claude-ui"
    echo "  2. Create .env:              cp .env.example .env"
    echo "  3. Edit .env with the path to your project repo"
    echo "  4. Re-run:                   bash launch.sh"
    exit 1
fi

# Validate PROJECT_PATH exists
source "$SCRIPT_DIR/.env"
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

# Build base image if it doesn't exist
if ! docker image inspect vibe-sandbox-base >/dev/null 2>&1; then
    echo "Base image not found. Building..."
    cd "$BASE_DIR" && bash build.sh
    cd "$SCRIPT_DIR"
fi

# Stop and remove any existing sandbox container
echo "Cleaning up existing containers..."
docker rm -f claude-ui-sandbox 2>/dev/null || true
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
docker ps --filter name=claude-ui-sandbox --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"

echo ""
echo "Sandbox is ready. Attach with:"
echo "  docker exec -it claude-ui-sandbox /bin/bash"
echo ""
echo "Workspace mounted from: $RESOLVED_PATH"
echo "Plugins (superpowers, dev-browser) are pre-installed."
echo "To update plugins:     docker exec -it claude-ui-sandbox ~/setup-plugins.sh"
echo "To setup Vibe Guard:   docker exec -it claude-ui-sandbox bash -c 'cd /workspace && ~/setup-vibe-guard.sh'"
