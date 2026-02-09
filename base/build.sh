#!/bin/bash
set -e

echo "=== Building Vibe Sandbox Base Image ==="
docker build --no-cache -t vibe-sandbox-base .
echo ""
echo "Base image built: vibe-sandbox-base"
echo "Projects can now use FROM vibe-sandbox-base in their Dockerfiles."
