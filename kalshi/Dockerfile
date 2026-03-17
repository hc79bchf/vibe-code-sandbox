# Inherit from shared base image (build base first: cd ../base && ./build.sh)
FROM vibe-sandbox-base

# Switch to root for global installs and file permissions
USER root

# Install kalshi-related dependencies (add specific CLI/packages as needed)
# RUN npm install -g kalshi-cli@latest

# Copy setup script
COPY setup-kalshi.sh /home/vscode/setup-kalshi.sh
RUN chmod +x /home/vscode/setup-kalshi.sh && chown vscode:vscode /home/vscode/setup-kalshi.sh

# Switch back to vscode user
USER vscode
