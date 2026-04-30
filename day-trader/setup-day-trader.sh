#!/bin/bash
# =============================================================================
# Day-Trader Project Bootstrap — runs as vscode user inside the container
# Validates keys, sets up environment, starts any services
# =============================================================================

WORKSPACE="/workspace"
LOG_DIR="/tmp/day-trader"
LOG_FILE="$LOG_DIR/day-trader.log"

mkdir -p "$LOG_DIR"

# --- Environment ---
# Source workspace .env for any keys not already set via docker-compose
if [ -f "$WORKSPACE/.env" ]; then
    set -a
    source "$WORKSPACE/.env"
    set +a
fi

# Validate required keys
if [ -z "$BROKER_API_KEY" ]; then
    echo "WARNING: BROKER_API_KEY is not set."
    echo "Set it in .env or docker-compose environment."
fi

if [ -z "$BROKER_API_SECRET" ]; then
    echo "WARNING: BROKER_API_SECRET is not set."
    echo "Set it in .env or docker-compose environment."
fi

echo "Day-trader sandbox environment ready."
echo "Log: $LOG_FILE"
