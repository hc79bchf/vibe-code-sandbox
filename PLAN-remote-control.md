# Plan: Enable Remote Control for Sandbox Containers

## Overview

Enable Claude Code's Remote Control feature across all sandbox containers so sessions running inside Docker can be continued from a phone, tablet, or browser via [claude.ai/code](https://claude.ai/code) or the Claude mobile app.

Remote Control keeps the session running locally inside the container — the web/mobile interface is just a window into it.

## Requirements

- **Anthropic Pro or Max plan** (API keys are not supported for remote control)
- Claude Code must be authenticated via `/login` inside each container
- Outbound HTTPS from the container (already available via `sandbox-net`)
- The container's terminal must stay open (already guaranteed by `sleep infinity`)

## What Changes

### 1. New helper script: `base/setup-remote-control.sh`

A script that:
- Enables Remote Control globally for all Claude Code sessions via `claude config set`
- Can be run manually or automatically via entrypoint
- Is idempotent (safe to run multiple times)

### 2. Update `base/entrypoint.sh`

Add an optional auto-enable step controlled by the `ENABLE_REMOTE_CONTROL` env var:
- If `ENABLE_REMOTE_CONTROL=true`, run `setup-remote-control.sh` on container start
- Default: off (opt-in per sandbox via `.env`)

### 3. Update `base/Dockerfile`

- Copy the new `setup-remote-control.sh` script into the image
- Set correct permissions

### 4. Update `docker-compose.yml` (all sandboxes)

- Add `ENABLE_REMOTE_CONTROL` environment variable (passed from `.env`)

### 5. Update `.env.example` (all sandboxes)

- Add `ENABLE_REMOTE_CONTROL=true` with a comment explaining the feature

### 6. Create `RUNBOOK-remote-control.md`

Operational guide covering:
- Prerequisites (authentication)
- How to start a remote session (manual and automatic)
- How to connect from another device
- Troubleshooting
- Limitations

## File Changes Summary

| File | Action | Description |
|------|--------|-------------|
| `base/setup-remote-control.sh` | **New** | Helper script to enable remote control config |
| `base/entrypoint.sh` | **Edit** | Add optional remote control auto-enable |
| `base/Dockerfile` | **Edit** | Copy script, set permissions |
| `governance-agent/docker-compose.yml` | **Edit** | Add env var |
| `agent-hr/docker-compose.yml` | **Edit** | Add env var |
| `polymarket/docker-compose.yml` | **Edit** | Add env var |
| `earning-tracker/docker-compose.yml` | **Edit** | Add env var |
| `governance-agent/.env.example` | **Edit** | Add env var |
| `agent-hr/.env.example` | **Edit** | Add env var |
| `polymarket/.env.example` | **Edit** | Add env var |
| `earning-tracker/.env.example` | **Edit** | Add env var |
| `RUNBOOK-remote-control.md` | **New** | Operational runbook |

## Execution Order

1. Create `setup-remote-control.sh`
2. Update `Dockerfile` (add COPY + chmod)
3. Update `entrypoint.sh` (add conditional remote control setup)
4. Update all `docker-compose.yml` files (add env var)
5. Update all `.env.example` files (add env var)
6. Create `RUNBOOK-remote-control.md`
7. Rebuild base image (`cd base && ./build.sh`)
8. Relaunch containers

## Authentication Note

Remote Control requires `/login` authentication — this cannot be baked into the image. Each container must be logged in interactively once:

```bash
docker exec -it <container-name> bash
claude
# Inside Claude: /login
```

After login, credentials persist across container restarts (stored in `~/.claude/`). The setup script will check for authentication and warn if not logged in.
