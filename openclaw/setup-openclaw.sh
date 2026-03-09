#!/bin/bash
# =============================================================================
# OpenClaw Gateway Bootstrap — runs as vscode user inside the container
# Creates inner symlinks, copies cron jobs, validates keys, starts gateway
# =============================================================================

OPENCLAW_DIR="$HOME/.openclaw"
WORKSPACE="/workspace"
LOG_DIR="/tmp/openclaw"
LOG_FILE="$LOG_DIR/gateway.log"

mkdir -p "$LOG_DIR"

# --- Symlinks ---
# Ensure openclaw.json config symlink exists
if [ -f "$WORKSPACE/.openclaw/openclaw.json" ] && [ ! -L "$OPENCLAW_DIR/openclaw.json" ]; then
    ln -sfn "$WORKSPACE/.openclaw/openclaw.json" "$OPENCLAW_DIR/openclaw.json"
    echo "Linked openclaw.json"
fi

# Ensure workspace symlink exists
if [ ! -L "$OPENCLAW_DIR/workspace" ]; then
    ln -sfn "$WORKSPACE" "$OPENCLAW_DIR/workspace"
    echo "Linked workspace"
fi

# --- Cron jobs ---
if [ -d "$WORKSPACE/.openclaw/cron" ] && [ -f "$WORKSPACE/.openclaw/cron/jobs.json" ]; then
    mkdir -p "$OPENCLAW_DIR/cron"
    cp "$WORKSPACE/.openclaw/cron/jobs.json" "$OPENCLAW_DIR/cron/jobs.json"
    echo "Copied cron/jobs.json"
fi

# --- Environment ---
# Source workspace .env for any keys not already set via docker-compose
if [ -f "$WORKSPACE/.env" ]; then
    set -a
    source "$WORKSPACE/.env"
    set +a
fi

# Validate required key
if [ -z "$GOOGLE_AI_API_KEY" ]; then
    echo "WARNING: GOOGLE_AI_API_KEY is not set. Gateway may not function correctly."
    echo "Set it in .env or docker-compose environment."
fi

# --- Start gateway ---
echo "Starting OpenClaw gateway..."
npx openclaw gateway run > "$LOG_FILE" 2>&1 &
GATEWAY_PID=$!

sleep 5

if kill -0 "$GATEWAY_PID" 2>/dev/null; then
    echo "OpenClaw gateway running (PID $GATEWAY_PID)"
    echo "Log: $LOG_FILE"
    echo "Endpoint: ws://localhost:18789"
else
    echo "ERROR: Gateway failed to start. Check $LOG_FILE"
    cat "$LOG_FILE"
    exit 1
fi
