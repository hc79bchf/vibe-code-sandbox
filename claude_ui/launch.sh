#!/bin/bash
set -e

echo "=== Claude UI Sandbox Launcher ==="

# Stop and remove any existing sandbox container
echo "Cleaning up existing containers..."
docker rm -f claude-ui-sandbox 2>/dev/null || true
docker compose down -v 2>/dev/null || true

# Build the sandbox image (no cache for clean build)
echo "Building sandbox image..."
docker compose build --no-cache sandbox

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
