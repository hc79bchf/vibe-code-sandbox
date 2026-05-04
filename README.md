# Vibe Code Sandbox

Isolated Docker-based development environments with Claude Code, security scanning, and pre-installed plugins. Each sandbox mounts an external project repo into a container pre-configured with AI coding tools and automated code quality checks.

## Architecture

```
vibe-code-sandbox/
  base/                       # Shared base Docker image (vibe-sandbox-base)
    Dockerfile                # Ubuntu 22.04 + Node 22 + Claude Code + Vibe Guard tools
    entrypoint.sh             # Container startup (socket fix + Vibe Guard auto-setup)
    setup-plugins.sh          # Plugin update helper
    setup-vibe-guard.sh       # Per-project Vibe Guard activation
    disable-vibe-guard.sh     # Disable Vibe Guard hooks for a project
    pre-commit-config.yaml    # Default pre-commit hooks template
    workspace-claude.md       # Per-workspace CLAUDE.md (OpenSpec + /implement)
    commands/implement.md     # /implement orchestrator command
  host-tools/                 # macOS host-side helpers
    install-credential-exporter.sh  # LaunchAgent that bridges keychain → ~/.claude/.credentials.json
    export-claude-credentials.sh
  agent-build-config/         # sandbox
  agent-hr/                   # sandbox
  arbitrage/                  # sandbox
  claude_ui/                  # sandbox
  day-trader/                 # sandbox
  governance-agent/           # sandbox
  kalshi/                     # sandbox
  openclaw/                   # sandbox
  vibecraft/                  # sandbox
```

Each sandbox inherits from `vibe-sandbox-base` and mounts an external project repo as `/workspace`. Sandbox container names are derived from `SANDBOX_NAME` in each sandbox's `.env` (e.g. `governance-agent/.env` with `SANDBOX_NAME=governance` → container `governance-sandbox`).

## Pre-installed Tools

Versions reflect what `base/Dockerfile` installs at image-build time (`@latest` resolves to whatever the upstream registry serves on rebuild). Pre-commit hook tools are pinned separately in `base/pre-commit-config.yaml` and may lag behind the system CLI — that is intentional, hooks need reproducible runs.

| Tool | Source / version | Purpose |
|------|------------------|---------|
| Claude Code CLI | `@anthropic-ai/claude-code@latest` | AI coding assistant |
| OpenSpec | `@fission-ai/openspec@latest` | Spec-driven dev workflow (see [base/workspace-claude.md](base/workspace-claude.md)) |
| Letta Code | `@letta-ai/letta-code` | Context-repo memory for coding agents |
| Superpowers plugin | latest (via `setup-plugins.sh`) | Extended Claude Code capabilities |
| Dev-Browser plugin | latest (via `setup-plugins.sh`) | Browser automation for Claude Code |
| Ruff | latest CLI; hooks pinned `v0.9.6` | Python linter + formatter |
| Biome | latest CLI; hooks pinned `v0.6.1` (biome `1.9.4`) | JS/TS linter + formatter |
| Trivy | latest (install.sh) | Vulnerability + secret scanner |
| Gitleaks | `v8.21.2` | Git secret detection |
| pre-commit | latest (pip) | Git hook framework |
| Socket Security CLI | `@socketsecurity/cli` | Dependency security |
| Docker CLI | apt `docker-ce-cli` | Docker-outside-of-Docker |
| Bun | latest (bun.sh installer) | Required by gstack |
| PostgreSQL client | apt `postgresql-client` | `psql` from the sandbox |
| Railway CLI | latest (`cli.new`) | Deploy from sandbox |
| Playwright + Chromium | npm `playwright` + browser | Browser automation (dev-browser plugin) |
| Computer-use deps | xvfb, xdotool, scrot, imagemagick | GUI automation primitives |

## Quick Start

### 1. Build the base image (one-time)

```bash
cd base
bash build.sh
```

### 2. Set up a sandbox

```bash
cd governance-agent          # or agent-hr, claude_ui

# Point to your project repo
cp .env.example .env
# Edit .env: PROJECT_PATH=~/projects/your-project

# Launch
bash launch.sh
```

### 3. Attach to the container

```bash
docker exec -it governance-sandbox /bin/bash
```

Vibe Guard activates automatically on container startup if `/workspace` is a git repo. No manual setup needed.

### 4. (macOS host only) Bridge Claude Code credentials

Sandboxes bind-mount `~/.claude/` so the container can reuse the host's logged-in Claude Code session. On macOS the OAuth token lives in the login keychain — unreachable from a Linux container — so a host-side launchd job exports it to `~/.claude/.credentials.json`:

```bash
bash host-tools/install-credential-exporter.sh
```

This installs once and runs on every keychain change plus every 30 min. See [host-tools/install-credential-exporter.sh](host-tools/install-credential-exporter.sh) for details. Skip on Linux hosts — `~/.claude/.credentials.json` is already the native storage there.

## Vibe Guard

Vibe Guard is a 3-layer automated code scanning system that runs on every `git commit` inside the sandbox. It activates automatically when the container starts. See [RUNBOOK.md](RUNBOOK.md) for detailed usage.

**Layer 1 - Auto-Fix Linters:** Ruff (Python) and Biome (JS/TS) catch lint errors and auto-fix what they can.

**Layer 2 - Security Gatekeepers:** Gitleaks detects hardcoded API keys and secrets in staged code.

**Layer 3 - Pre-commit Hooks:** Enforces all scans on every commit, plus blocks private keys, large files, and direct commits to master/main.

To disable Vibe Guard for a project (hooks only; tools remain available for manual use):

```bash
cd /workspace
~/disable-vibe-guard.sh
```

## Workspace Configuration

Each sandbox mounts an external project repo via `PROJECT_PATH` in `.env`:

```bash
# .env
PROJECT_PATH=~/projects/governance-agent
```

This directory appears as `/workspace` inside the container. The sandbox config repo (vibe-code-sandbox) stays separate from your project code.

## Plugin Management

Plugins (superpowers, dev-browser) are pre-installed during image build. To update or re-install:

```bash
docker exec -it governance-sandbox ~/setup-plugins.sh
```
