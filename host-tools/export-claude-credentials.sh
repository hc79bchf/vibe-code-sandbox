#!/bin/bash
# Export Claude Code OAuth credentials from the macOS login keychain to
# ~/.claude/.credentials.json so Linux sandbox containers that bind-mount
# ~/.claude inherit a logged-in session.
#
# On macOS, Claude Code stores its OAuth token in the keychain entry
# "Claude Code-credentials" — unreachable from a Linux container. The
# .credentials.json file is the cross-platform fallback Claude Code looks
# for, so writing it here lets the container skip /login.
#
# Run periodically via the matching LaunchAgent
# (~/Library/LaunchAgents/com.hongfeicao.claude-credentials-export.plist)
# so refreshed tokens propagate before they expire.

set -euo pipefail

CRED_DIR="${HOME}/.claude"
CRED_FILE="${CRED_DIR}/.credentials.json"
KEYCHAIN_ENTRY="Claude Code-credentials"

mkdir -p "$CRED_DIR"

tmp="$(mktemp "${CRED_FILE}.XXXXXX")"
trap 'rm -f "$tmp"' EXIT

if ! security find-generic-password -s "$KEYCHAIN_ENTRY" -w >"$tmp" 2>/dev/null; then
  echo "$(date -u +%FT%TZ) export-claude-credentials: keychain entry '$KEYCHAIN_ENTRY' not found (host not logged into Claude Code?)" >&2
  exit 1
fi

if [[ ! -s "$tmp" ]]; then
  echo "$(date -u +%FT%TZ) export-claude-credentials: empty keychain payload, refusing to overwrite" >&2
  exit 1
fi

if [[ -f "$CRED_FILE" ]] && cmp -s "$tmp" "$CRED_FILE"; then
  exit 0
fi

chmod 600 "$tmp"
mv "$tmp" "$CRED_FILE"
echo "$(date -u +%FT%TZ) export-claude-credentials: refreshed $CRED_FILE"
