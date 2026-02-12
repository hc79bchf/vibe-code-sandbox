# Inherit from shared base image (build base first: cd ../base && ./build.sh)
FROM vibe-sandbox-base

# Claude UI Dashboard — nginx + Express backend + React frontend
USER root

# Install nginx for reverse proxy
RUN apt-get update && apt-get install -y nginx && rm -rf /var/lib/apt/lists/*

# Clone and build Claude UI Dashboard (as vscode user)
# Remove stale copy from base image if present
USER vscode
RUN rm -rf /home/vscode/claude-ui \
    && git clone https://github.com/hc79bchf/claude_ui.git /home/vscode/claude-ui \
    && cd /home/vscode/claude-ui \
    && npm install && npm run build \
    && cd server && npm install && npm run build

# Nginx config for Claude UI Dashboard
USER root
COPY dashboard-nginx.conf /etc/nginx/sites-enabled/default

# Override base entrypoint with claude_ui-specific one
COPY entrypoint.sh /home/vscode/entrypoint.sh
RUN chmod +x /home/vscode/entrypoint.sh && chown vscode:vscode /home/vscode/entrypoint.sh

USER vscode
