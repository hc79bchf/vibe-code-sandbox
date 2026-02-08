# Microsoft's Official DevContainer Image (Includes all dependencies)
FROM mcr.microsoft.com/devcontainers/base:ubuntu-22.04

# Avoid prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install tools + Docker CLI
RUN apt-get update && apt-get install -y \
    python3-pip \
    python3-venv \
    nodejs \
    npm \
    build-essential \
    ca-certificates \
    curl \
    gnupg \
    && rm -rf /var/lib/apt/lists/*

# Add Docker's official GPG key and repository
RUN install -m 0755 -d /etc/apt/keyrings \
    && curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg \
    && chmod a+r /etc/apt/keyrings/docker.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu jammy stable" \
    > /etc/apt/sources.list.d/docker.list

# Install Docker CLI only (no daemon needed - we use host's Docker)
RUN apt-get update && apt-get install -y \
    docker-ce-cli \
    docker-compose-plugin \
    && rm -rf /var/lib/apt/lists/*

# Allow vscode user to access Docker socket (for macOS Docker Desktop compatibility)
RUN groupadd -f docker && usermod -aG docker vscode

RUN npm install -g @socketsecurity/cli

# Use the vscode user from base image (expected by Antigravity/VSCode Remote)
USER vscode
WORKDIR /workspace

# Set up Python venv for vscode user
ENV VIRTUAL_ENV=/home/vscode/venv
RUN python3 -m venv $VIRTUAL_ENV
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

CMD ["sleep", "infinity"]
