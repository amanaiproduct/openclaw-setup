# Personal AI Assistant Setup Guides

Step-by-step setup prompts you can paste into **any coding agent** (Claude Code, Codex, Hermes, etc.) to install, configure, and harden a personal AI assistant on your Mac.

Two guides — pick one:

| | [OpenClaw](PROMPT.md) | [Hermes](HERMES.md) |
|---|---------|--------|
| **Runtime** | Node.js | Python |
| **By** | [OpenClaw](https://openclaw.ai) | [Nous Research](https://nousresearch.com) |
| **Providers** | Anthropic | 20+ (Anthropic, OpenAI, Google, DeepSeek, local, etc.) |
| **Config** | JSON (complex schema) | YAML (human-editable) |
| **Memory** | File-based (MEMORY.md) | Built-in persistent memory (automatic) |
| **Skills** | N/A | Community hub + auto-created from experience |
| **Personality** | Multi-file (SOUL, IDENTITY, USER, AGENTS) | Single SOUL.md |

Both connect to WhatsApp, Telegram, Discord, Slack, and more. Both run as 24/7 background services with watchdog monitoring.

## Quick Start

### Hermes Agent (recommended for new setups)

Open a coding agent and paste:

```
Read https://raw.githubusercontent.com/amanaiproduct/openclaw-setup/main/HERMES.md and follow every step. Ask me for my Anthropic API key when you need it.
```

### OpenClaw

Open a coding agent and paste:

```
Read https://raw.githubusercontent.com/amanaiproduct/openclaw-setup/main/PROMPT.md and follow every step. Ask me for my Anthropic API key when you need it.
```

## Prerequisites

- **macOS** (Apple Silicon recommended)
- **An API key** from [Anthropic](https://console.anthropic.com), [OpenRouter](https://openrouter.ai), or another provider
- A phone with **WhatsApp** (or a Telegram bot token, Slack app credentials, Discord bot token)

## What's Inside

```
├── README.md                          ← You're here
├── PROMPT.md                          ← OpenClaw setup guide
├── HERMES.md                          ← Hermes Agent setup guide
└── config/
    ├── ai.openclaw.gateway.plist      ← OpenClaw LaunchAgent
    ├── ai.openclaw.watchdog.plist     ← OpenClaw watchdog LaunchAgent
    ├── watchdog.sh                    ← OpenClaw watchdog script
    ├── ai.hermes.watchdog.plist       ← Hermes watchdog LaunchAgent
    └── hermes-watchdog.sh             ← Hermes watchdog script
```

## Switching from OpenClaw to Hermes

Hermes has a built-in migration tool:

```bash
hermes claw migrate
```

See the [migration section](HERMES.md#migrating-from-openclaw) in the Hermes guide for details.

## Links

- **Hermes:** [GitHub](https://github.com/NousResearch/hermes-agent) · [Docs](https://hermes-agent.nousresearch.com/docs/)
- **OpenClaw:** [Site](https://openclaw.ai) · [Docs](https://docs.openclaw.ai) · [GitHub](https://github.com/openclaw/openclaw)

---

Built by [Aman Khan](https://amanalikhan.com)
