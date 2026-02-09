# Vibe Code Sandbox

Isolated Docker-based development environments with Claude Code, security scanning, and pre-installed plugins. Each sandbox mounts an external project repo into a container pre-configured with AI coding tools and automated code quality checks.

## Architecture

```
vibe-code-sandbox/
  base/                    # Shared base Docker image (vibe-sandbox-base)
    Dockerfile             # Ubuntu 22.04 + Node 22 + Claude Code + Vibe Guard tools
    setup-plugins.sh       # Plugin update helper
    entrypoint.sh          # Container startup (socket fix + Vibe Guard auto-setup)
    setup-vibe-guard.sh    # Per-project Vibe Guard activation script
    disable-vibe-guard.sh  # Disable Vibe Guard hooks for a project
    pre-commit-config.yaml # Default pre-commit hooks template
  governance-agent/        # Governance Agent sandbox
  agent-hr/                # Agent HR sandbox
  claude_ui/               # Claude UI sandbox
```

Each project sandbox (governance-agent, agent-hr, claude_ui) inherits from `vibe-sandbox-base` and mounts an external project repo as `/workspace`.

## Pre-installed Tools

| Tool | Version | Purpose |
|------|---------|---------|
| Claude Code CLI | latest | AI coding assistant |
| VS Code Extension | latest | Claude Code IDE integration |
| Superpowers plugin | latest | Extended Claude Code capabilities |
| Dev-Browser plugin | latest | Browser automation for Claude Code |
| Ruff | 0.15.x | Python linter + formatter |
| Biome | 2.x | JS/TS linter + formatter |
| Trivy | 0.69.x | Vulnerability + secret scanner |
| Gitleaks | 8.21.x | Git secret detection |
| pre-commit | 4.x | Git hook framework |
| Socket Security CLI | latest | Dependency security |
| Docker CLI | latest | Docker-outside-of-Docker |

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
