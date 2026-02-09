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
# Socket Security CLI
# ---------------------------------------------------------------------------
RUN npm install -g @socketsecurity/cli

# ---------------------------------------------------------------------------
# Claude Code CLI
# ---------------------------------------------------------------------------
RUN npm install -g @anthropic-ai/claude-code

# ---------------------------------------------------------------------------
# VS Code Claude Code extension (pre-installed for devcontainer attach)
# ---------------------------------------------------------------------------
USER vscode
RUN code --install-extension anthropic.claude-code 2>/dev/null || true

# ---------------------------------------------------------------------------
# Claude Code plugins: dev-browser & superpowers
# Cloned to ~/.claude/plugins/ — registered via first-run setup script
# ---------------------------------------------------------------------------
RUN mkdir -p /home/vscode/.claude/plugins \
    && git clone https://github.com/SawyerHood/dev-browser.git /home/vscode/.claude/plugins/dev-browser \
    && git clone https://github.com/obra/superpowers.git /home/vscode/.claude/plugins/superpowers

# ---------------------------------------------------------------------------
# First-run setup script for plugin registration
# ---------------------------------------------------------------------------
COPY setup-plugins.sh /home/vscode/setup-plugins.sh

USER root
RUN chmod +x /home/vscode/setup-plugins.sh && chown vscode:vscode /home/vscode/setup-plugins.sh
USER vscode

# ---------------------------------------------------------------------------
# Python virtual environment
# ---------------------------------------------------------------------------
WORKDIR /workspace
ENV VIRTUAL_ENV=/home/vscode/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

CMD ["sleep", "infinity"]
