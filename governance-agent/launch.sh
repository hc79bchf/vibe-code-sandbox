#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BASE_DIR="$SCRIPT_DIR/../base"

echo "=== Governance Agent Sandbox Launcher ==="

# Build base image if it doesn't exist
if ! docker image inspect vibe-sandbox-base >/dev/null 2>&1; then
    echo "Base image not found. Building..."
    cd "$BASE_DIR" && bash build.sh
    cd "$SCRIPT_DIR"
fi

# Stop and remove any existing sandbox container
echo "Cleaning up existing containers..."
docker rm -f governance-sandbox 2>/dev/null || true
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
docker ps --filter name=governance-sandbox --format "table {{.ID}}\t{{.Image}}\t{{.Status}}\t{{.Names}}"

echo ""
echo "Sandbox is ready. Attach with:"
echo "  docker exec -it governance-sandbox /bin/bash"
echo ""
echo "Plugins (superpowers, dev-browser) are pre-installed."
echo "To update plugins: docker exec -it governance-sandbox ~/setup-plugins.sh"
