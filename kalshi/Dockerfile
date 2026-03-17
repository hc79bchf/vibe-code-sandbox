# Inherit from shared base image (build base first: cd ../base && ./build.sh)
FROM vibe-sandbox-base

# Switch to root for global installs and file permissions
USER root

# Install openclaw CLI locally (not global) into ~/.local for vscode user
RUN mkdir -p /home/vscode/.local/bin /home/vscode/.local/lib/openclaw \
    && cd /home/vscode/.local/lib/openclaw \
    && npm init -y > /dev/null 2>&1 \
    && npm install openclaw@latest \
    && ln -s /home/vscode/.local/lib/openclaw/node_modules/.bin/openclaw /home/vscode/.local/bin/openclaw \
    && chown -R vscode:vscode /home/vscode/.local

# Copy setup script
COPY setup-kalshi.sh /home/vscode/setup-kalshi.sh
RUN chmod +x /home/vscode/setup-kalshi.sh && chown vscode:vscode /home/vscode/setup-kalshi.sh

# Ensure ~/.local/bin is on PATH for openclaw
ENV PATH="/home/vscode/.local/bin:$PATH"

# Switch back to vscode user
USER vscode
