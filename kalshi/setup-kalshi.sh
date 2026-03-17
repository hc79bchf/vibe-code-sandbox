#!/bin/bash
# =============================================================================
# Kalshi Project Bootstrap — runs as vscode user inside the container
# Validates keys, sets up environment, starts any services
# =============================================================================

WORKSPACE="/workspace"
LOG_DIR="/tmp/kalshi"
LOG_FILE="$LOG_DIR/kalshi.log"

mkdir -p "$LOG_DIR"

# --- Environment ---
# Source workspace .env for any keys not already set via docker-compose
if [ -f "$WORKSPACE/.env" ]; then
    set -a
    source "$WORKSPACE/.env"
    set +a
fi

# Validate required keys
if [ -z "$KALSHI_API_KEY" ]; then
    echo "WARNING: KALSHI_API_KEY is not set."
    echo "Set it in .env or docker-compose environment."
fi

if [ -z "$KALSHI_API_SECRET" ]; then
    echo "WARNING: KALSHI_API_SECRET is not set."
    echo "Set it in .env or docker-compose environment."
fi

echo "Kalshi sandbox environment ready."
echo "Log: $LOG_FILE"
