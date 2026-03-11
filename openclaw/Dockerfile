# Inherit from shared base image (build base first: cd ../base && ./build.sh)
FROM vibe-sandbox-base

# Switch to root for global installs and file permissions
USER root

# Install openclaw CLI
RUN npm install -g openclaw@latest

# Copy gateway bootstrap script
COPY setup-openclaw.sh /home/vscode/setup-openclaw.sh
RUN chmod +x /home/vscode/setup-openclaw.sh && chown vscode:vscode /home/vscode/setup-openclaw.sh

# Switch back to vscode user
USER vscode
