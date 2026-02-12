# Inherit from shared base image (build base first: cd ../base && ./build.sh)
FROM vibe-sandbox-base

# Vibecraft — 3D visualization for Claude Code tool usage
USER root
RUN npm install -g vibecraft

# Override base entrypoint with vibecraft-specific one
COPY entrypoint.sh /home/vscode/entrypoint.sh
RUN chmod +x /home/vscode/entrypoint.sh && chown vscode:vscode /home/vscode/entrypoint.sh
USER vscode
