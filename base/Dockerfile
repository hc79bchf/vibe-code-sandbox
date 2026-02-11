# =============================================================================
# Vibe Code Sandbox — Base Image
# Generic dev container with Claude Code, VS Code extension, and plugins
# =============================================================================
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

ENV DEBIAN_FRONTEND=noninteractive

# ---------------------------------------------------------------------------
# System dependencies
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-venv \
    build-essential \
    ca-certificates \
    curl \
    gnupg \
    git \
    jq \
    nginx \
    tmux \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Node.js 22 LTS via NodeSource (replaces the outdated v12 from Ubuntu repos)
# ---------------------------------------------------------------------------
RUN curl -fsSL https://deb.nodesource.com/setup_22.x | bash - \
    && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Docker CLI (Docker-outside-of-Docker pattern — no daemon inside container)
# ---------------------------------------------------------------------------
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" \
    > /etc/apt/sources.list.d/docker.list \
    && apt-get update && apt-get install -y \
    docker-ce-cli \
    docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd -f docker && usermod -aG docker vscode

# ---------------------------------------------------------------------------
# Playwright system dependencies (required for Chromium in dev-browser)
# ---------------------------------------------------------------------------
RUN npx playwright install-deps chromium

# ---------------------------------------------------------------------------
# Socket Security CLI
# ---------------------------------------------------------------------------
RUN npm install -g @socketsecurity/cli

# ---------------------------------------------------------------------------
# Claude Code CLI
# ---------------------------------------------------------------------------
RUN npm install -g @anthropic-ai/claude-code

# ===========================================================================
# Vibe Guard — 3-Layer Auto-Scan System
# ===========================================================================

# ---------------------------------------------------------------------------
# Layer 1: Auto-Fix Linters (Rust-based, millisecond-fast)
#   - Ruff: Python linter+formatter (replaces Flake8, Black, Isort)
#   - Biome: JS/TS linter+formatter (replaces ESLint + Prettier)
# ---------------------------------------------------------------------------
RUN pip3 install ruff \
    && npm install -g @biomejs/biome

# ---------------------------------------------------------------------------
# Layer 2: Security Gatekeepers
#   - Trivy: scans deps for CVEs + secrets in filesystem mode
#   - Gitleaks: catches hardcoded API keys in git staging area
# ---------------------------------------------------------------------------
RUN curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin \
    && curl -sSfL https://github.com/gitleaks/gitleaks/releases/download/v8.21.2/gitleaks_8.21.2_linux_arm64.tar.gz \
       | tar -xz -C /usr/local/bin gitleaks

# ---------------------------------------------------------------------------
# Layer 3: Pre-commit framework (enforces scans on every commit)
# ---------------------------------------------------------------------------
RUN pip3 install pre-commit

# ---------------------------------------------------------------------------
# VS Code Claude Code extension (pre-installed for devcontainer attach)
# ---------------------------------------------------------------------------
USER vscode
RUN code --install-extension anthropic.claude-code 2>/dev/null || true

# ---------------------------------------------------------------------------
# Claude Code plugins: dev-browser, superpowers, compound-engineering
# Registered via Claude Code's marketplace system
# ---------------------------------------------------------------------------
RUN claude plugin marketplace add obra/superpowers-marketplace \
    && claude plugin marketplace add sawyerhood/dev-browser \
    && claude plugin marketplace add EveryInc/compound-engineering-plugin \
    && claude plugin install superpowers@superpowers-marketplace \
    && claude plugin install dev-browser@dev-browser-marketplace \
    && claude plugin install compound-engineering@every-marketplace

# ---------------------------------------------------------------------------
# Playwright + Chromium browser (for dev-browser plugin)
# Global install requires root; browser binary download runs as vscode
# ---------------------------------------------------------------------------
USER root
RUN npm install -g playwright
USER vscode
RUN playwright install chromium

# ---------------------------------------------------------------------------
# Claude UI Dashboard (web UI for Claude Code sessions)
# Clone, build frontend + backend, configure nginx reverse proxy
# ---------------------------------------------------------------------------
RUN git clone https://github.com/hc79bchf/claude_ui.git /home/vscode/claude-ui \
    && cd /home/vscode/claude-ui && npm install && npm run build \
    && cd /home/vscode/claude-ui/server && npm install && npm run build

# Pre-create the project settings directory for /workspace
# (Claude Code derives this path from the workspace mount point)
RUN mkdir -p /home/vscode/.claude/projects/-workspace

# ---------------------------------------------------------------------------
# Helper scripts and config templates
# ---------------------------------------------------------------------------
COPY setup-plugins.sh /home/vscode/setup-plugins.sh
COPY setup-vibe-guard.sh /home/vscode/setup-vibe-guard.sh
COPY disable-vibe-guard.sh /home/vscode/disable-vibe-guard.sh
COPY setup-hooks.sh /home/vscode/setup-hooks.sh
COPY entrypoint.sh /home/vscode/entrypoint.sh
COPY pre-commit-config.yaml /home/vscode/pre-commit-config.yaml

USER root
RUN chmod o+x /home/vscode \
    && chmod +x /home/vscode/setup-plugins.sh /home/vscode/setup-vibe-guard.sh /home/vscode/disable-vibe-guard.sh /home/vscode/setup-hooks.sh /home/vscode/entrypoint.sh \
    && chown vscode:vscode /home/vscode/setup-plugins.sh /home/vscode/setup-vibe-guard.sh /home/vscode/disable-vibe-guard.sh /home/vscode/setup-hooks.sh /home/vscode/entrypoint.sh /home/vscode/pre-commit-config.yaml

# ---------------------------------------------------------------------------
# Nginx reverse proxy for Claude UI Dashboard
# Serves frontend static files + proxies /api and /ws to backend
# ---------------------------------------------------------------------------
COPY dashboard-nginx.conf /etc/nginx/sites-available/dashboard
RUN rm -f /etc/nginx/sites-enabled/default \
    && ln -sf /etc/nginx/sites-available/dashboard /etc/nginx/sites-enabled/dashboard

USER vscode

# ---------------------------------------------------------------------------
# Python virtual environment
# ---------------------------------------------------------------------------
WORKDIR /workspace
ENV VIRTUAL_ENV=/home/vscode/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

CMD ["sleep", "infinity"]
