#!/bin/bash
# Install the Claude credential exporter as a launchd LaunchAgent.
#
# Why this exists: Claude Code on macOS stores its OAuth token in the login
# keychain ("Claude Code-credentials"), which Linux sandbox containers can't
# read. This installs a recurring job that exports the token to
# ~/.claude/.credentials.json, which the docker-compose mount of ~/.claude
# does carry into containers — eliminating the need to /login inside each one.
#
# Idempotent: re-running upgrades the script and reloads the agent.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SRC_SCRIPT="${REPO_DIR}/export-claude-credentials.sh"
DEST_SCRIPT="${HOME}/.local/bin/export-claude-credentials.sh"
LABEL="com.hongfeicao.claude-credentials-export"
PLIST="${HOME}/Library/LaunchAgents/${LABEL}.plist"
LOG="${HOME}/.claude/export-credentials.log"
INTERVAL_SECONDS=1800

# Install script outside ~/Downloads so launchd's TCC sandbox can execute it.
mkdir -p "$(dirname "$DEST_SCRIPT")"
install -m 0755 "$SRC_SCRIPT" "$DEST_SCRIPT"

uid="$(id -u)"

mkdir -p "$(dirname "$PLIST")" "${HOME}/.claude"
cat >"$PLIST" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>${DEST_SCRIPT}</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StartInterval</key>
    <integer>${INTERVAL_SECONDS}</integer>
    <key>StandardOutPath</key>
    <string>${LOG}</string>
    <key>StandardErrorPath</key>
    <string>${LOG}</string>
</dict>
</plist>
PLIST

launchctl bootout "gui/${uid}/${LABEL}" 2>/dev/null || true
launchctl bootstrap "gui/${uid}" "$PLIST"
launchctl enable "gui/${uid}/${LABEL}"
launchctl kickstart -k "gui/${uid}/${LABEL}"

echo "Installed: ${LABEL}"
echo "  script:   ${DEST_SCRIPT}"
echo "  plist:    ${PLIST}"
echo "  interval: every ${INTERVAL_SECONDS}s + at load"
echo "  log:      ${LOG}"
echo
echo "Uninstall: launchctl bootout gui/${uid}/${LABEL} && rm '${PLIST}'"
