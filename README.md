# OpenClaw: Hardened Personal AI Setup

A step-by-step setup prompt you can paste into **Claude Code** (or any coding agent) to install, configure, and harden [OpenClaw](https://openclaw.ai) on a Mac.

OpenClaw turns Claude into a 24/7 personal AI assistant — persistent memory, tool access, and a direct line to your messaging apps (WhatsApp, Telegram, Slack, Discord, iMessage).

## Prerequisites

- **macOS** (Apple Silicon recommended; Intel works too)
- **Homebrew** installed
- **An Anthropic API key** from [console.anthropic.com](https://console.anthropic.com)
- A phone with **WhatsApp** (or a Telegram bot token, or Slack app credentials)

## Usage

1. Open a fresh **Claude Code** terminal (or any coding agent with shell access)
2. Paste the contents of [`PROMPT.md`](./PROMPT.md) 
3. Follow along — it'll ask for your API key and show a QR code to scan
4. Send your first message: *"Hey, let's get you set up. Read BOOTSTRAP.md"*

That's it. The prompt handles installation, security hardening, watchdog setup, and first-run configuration.

## What It Does

### Phase 1: Install & Connect
- Installs OpenClaw via npm
- Runs the interactive onboarding wizard (API key, channel pairing, workspace creation)
- Installs the gateway as a launchd service (auto-starts on boot)

### Phase 2: Harden & Verify
- Locks down file permissions (`chmod 700` on config directory)
- Enforces loopback-only gateway binding
- Sets up token authentication
- Configures group chat safety (allowlist + require-mention)
- Installs a watchdog service for automatic crash recovery
- Runs a full security audit
- Verifies everything works end-to-end

## What's Inside

```
├── README.md       ← You're here
├── PROMPT.md       ← The setup prompt (paste into Claude Code)
└── config/
    ├── ai.openclaw.gateway.plist    ← LaunchAgent template
    ├── ai.openclaw.watchdog.plist   ← Watchdog LaunchAgent
    └── watchdog.sh                  ← Health check script
```

## Security Model

This setup is opinionated about security:

- **Gateway binds to localhost only** — not exposed to your network
- **Token auth required** — no unauthenticated access
- **Group chats require @mention** — bot won't speak unprompted in groups
- **Config files are owner-only** — `chmod 700` on `~/.openclaw`
- **Watchdog monitors health** — auto-restarts if gateway becomes unresponsive
- **Prompt injection awareness** — workspace files train the agent to reject embedded commands

If you use Tailscale, the gateway can be exposed to your tailnet (but never to the public internet via Funnel).

## After Setup

Your agent wakes up fresh each session but persists through files:

| File | What It Is |
|------|-----------|
| `SOUL.md` | Personality, values, boundaries |
| `AGENTS.md` | Operating manual (memory rules, security, workflow) |
| `MEMORY.md` | Long-term memory (curated by the agent) |
| `memory/*.md` | Daily notes |
| `IDENTITY.md` | Agent's name, vibe, emoji |
| `USER.md` | Your info (name, timezone, preferences) |

These are created by OpenClaw's onboarding. The hardening prompt adds security rules and operational patterns on top.

## Based On

A real setup running 24/7 on a headless Mac Mini with WhatsApp + iMessage, built over weeks of iteration. See the [blog post](https://amanalikhan.substack.com) for the full story.

## Links

- [OpenClaw](https://openclaw.ai) • [Docs](https://docs.openclaw.ai) • [Discord](https://discord.com/invite/clawd) • [GitHub](https://github.com/openclaw/openclaw)

---

Built by [Aman Khan](https://amanalikhan.com)
