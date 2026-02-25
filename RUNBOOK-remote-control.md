# Remote Control Runbook

Operational guide for using Claude Code Remote Control with sandbox containers. Remote Control lets you continue a local Claude Code session from your phone, tablet, or any browser via [claude.ai/code](https://claude.ai/code) or the Claude mobile app.

## Prerequisites

### Subscription

Remote Control requires an Anthropic **Pro or Max plan**. API keys are not supported.

### Authentication

Each container must be logged in via `/login` once. Credentials persist across container restarts.

```bash
# Attach to the container
docker exec -it <sandbox-name>-sandbox bash

# Start Claude and log in
claude
# Inside Claude Code, run:
/login
# Follow the browser-based auth flow
```

To verify authentication status:

```bash
docker exec -it <sandbox-name>-sandbox claude auth status
```

## Enabling Remote Control

### Option A: Auto-enable on container start (recommended)

Set `ENABLE_REMOTE_CONTROL=true` in your sandbox's `.env` file:

```bash
# In governance-agent/.env, polymarket/.env, etc.
ENABLE_REMOTE_CONTROL=true
```

This runs `setup-remote-control.sh` on every container start, which configures Claude Code to enable Remote Control for all sessions automatically.

After updating `.env`, restart the container:

```bash
cd <sandbox-folder>
docker compose down && docker compose up -d
```

### Option B: Enable manually inside a container

```bash
docker exec -it <sandbox-name>-sandbox bash

# Enable for all future sessions
~/setup-remote-control.sh

# Or enable via Claude Code config directly
claude config set remote_control_enabled true
```

### Option C: Per-session (no global config change)

Start a standalone remote control session:

```bash
docker exec -it <sandbox-name>-sandbox bash
cd /workspace
claude remote-control
```

Or from inside an existing Claude Code session:

```
/remote-control
```

Shorthand: `/rc`

## Connecting from Another Device

Once a Remote Control session is active, connect from any device:

1. **Session URL** — displayed in the terminal when the session starts. Open it in any browser.
2. **QR code** — press **spacebar** in the terminal running `claude remote-control` to show a QR code. Scan with your phone.
3. **claude.ai/code** — open the site and find the session by name. Remote sessions show a computer icon with a green dot when online.
4. **Claude mobile app** — available for [iOS](https://apps.apple.com/us/app/claude-by-anthropic/id6473753684) and [Android](https://play.google.com/store/apps/details?id=com.anthropic.claude). Sessions appear in the session list.

**Tip:** Use `/rename <descriptive-name>` before `/remote-control` to make the session easy to find across devices.

## How It Works

- The Claude Code session runs **locally inside the container** — nothing moves to the cloud
- Your filesystem, MCP servers, tools, and project configuration stay available
- The conversation stays in sync across all connected devices
- Only outbound HTTPS is used (no inbound ports opened)
- All traffic goes through the Anthropic API over TLS
- If the container sleeps or network drops, the session reconnects automatically when back online

## Starting a Remote Session in tmux (Long-Running)

For persistent remote sessions that survive terminal disconnects:

```bash
docker exec -it <sandbox-name>-sandbox bash

# Start a tmux session
tmux new -s remote

# Navigate to workspace and start remote control
cd /workspace
claude remote-control

# Detach with Ctrl+B then D
# Reattach later with:
tmux attach -t remote
```

## Disabling Remote Control

```bash
# Inside the container
claude config set remote_control_enabled false
```

Or remove `ENABLE_REMOTE_CONTROL=true` from your `.env` and restart the container.

## Limitations

| Limitation | Detail |
|-----------|--------|
| **One remote session per container** | Each Claude Code instance supports one remote connection at a time |
| **Process must stay running** | If `claude remote-control` is stopped, the session ends. Use tmux for persistence |
| **Network timeout** | If the container can't reach the network for ~10 minutes, the session times out |
| **Pro/Max plan required** | Not available on Team or Enterprise plans |
| **No API key support** | Must use `/login` authentication |

## Troubleshooting

### "Not authenticated" error

```bash
docker exec -it <sandbox-name>-sandbox bash
claude
/login
```

### Remote session not appearing on claude.ai/code

1. Verify the container has outbound internet access:
   ```bash
   docker exec -it <sandbox-name>-sandbox curl -s https://api.anthropic.com/v1/messages | head -1
   ```
2. Check that `claude remote-control` is still running inside the container
3. Verify you're logged into the same Anthropic account on both devices

### Session disconnected

Remote Control reconnects automatically when the machine/container comes back online. If it doesn't:

```bash
# Restart the remote control session
docker exec -it <sandbox-name>-sandbox bash
cd /workspace
claude remote-control
```

### QR code not showing

Press **spacebar** in the terminal running `claude remote-control` to toggle QR code display.

### "Remote Control is not available" error

Verify your subscription plan supports Remote Control (Pro or Max). Check at [claude.ai/settings](https://claude.ai/settings).

## Quick Reference

| Action | Command |
|--------|---------|
| Start new remote session | `claude remote-control` |
| Start from existing session | `/remote-control` or `/rc` |
| Enable globally | `claude config set remote_control_enabled true` |
| Disable globally | `claude config set remote_control_enabled false` |
| Rename session | `/rename my-project-session` |
| Show QR code | Press **spacebar** during `claude remote-control` |
| Check auth status | `claude auth status` |
| Get mobile app | `/mobile` inside Claude Code |
| Verbose logging | `claude remote-control --verbose` |
| With sandboxing | `claude remote-control --sandbox` |
