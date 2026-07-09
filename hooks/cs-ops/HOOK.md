---
name: cs-ops
description: "Operational layer for cs-agent-pro. On message:received + message:sent it (1) logs every turn to memory/cs-agent-pro/logs/, (2) captures knowledge-pack gaps when the agent uses the grounding fallback, and (3) delivers escalations to a configured webhook (Telegram/Slack/Discord/generic) when the agent hands off to a human. Write-only — never pushes text back to chat."
metadata:
  {
    "openclaw":
      {
        "emoji": "🎧",
        "events": ["message:received", "message:sent"],
        "always": true
      }
  }
---

# CS Ops

Turns cs-agent-pro from a *prompt* into a *running service*. The operating manual makes the
agent behave correctly; this hook does the three things a prompt structurally cannot do by
itself:

1. **Log** — appends every inbound and outbound message to
   `memory/cs-agent-pro/logs/conversations-<date>.jsonl` (date-partitioned so it stays
   manageable). This is the raw material for `scripts/report.sh`.
2. **Capture KB gaps** — when the agent's reply contains the grounding-fallback phrase
   (operating manual §4.3, *"…belum punya datanya…"*), it records the customer's question to
   `memory/cs-agent-pro/kb-gaps.jsonl`. Those are exactly the questions the owner should add
   to the knowledge pack — the feedback loop that makes the agent better over time.
3. **Deliver escalations** — when the agent hands off to a human (operating manual §7,
   *"…hubungkan ke tim…"*), it records the escalation to `memory/cs-agent-pro/escalations.jsonl`
   **and** POSTs it to a configured webhook so a human is actually notified out-of-band. The
   agent can *compose* a handoff but cannot *reach* the admin outside the customer chat — this
   hook can.

## Why a hook (not the agent)
Logging and out-of-band delivery must happen even if the agent has no shell/tool access and
regardless of channel. A hook is the gateway's own code with filesystem + network access, so
it runs reliably. It is **write-only** (append a file / POST a URL) and never calls
`event.messages.push(...)`, so the "only `command:*` and `session:compact:*` are replyable"
limitation is irrelevant here.

## Configuration
First match wins:
- **Real-time escalation push:** env `CS_ESCALATION_WEBHOOK`, else `escalationWebhook` in
  `memory/cs-agent-pro/ops-config.json`. Empty = escalations are still logged (durable
  backstop), just not pushed. The payload carries both `text` and `content` keys, so one
  webhook fits Slack, Discord, Telegram (`?chat_id=` in the URL), n8n/Zapier/Make, etc.
- **Logging:** on by default. Turn off with env `CS_LOG=off` or `"logging": false` in
  ops-config.json. Logs are the owner's data in their own workspace — the owner is responsible
  for disclosing/retaining them per local privacy law (operating manual §8).

## Adapter dependency
The hook reads message text/channel/session from `event.context`. Field names vary per
gateway adapter, so it probes several and **degrades to a no-op turn** (no crash) if the
adapter doesn't provide them. If your logs come out empty, the adapter isn't passing message
text into hook context — the same dependency called out for §2b in `platform-recommendations.md`.

Enable with `openclaw hooks enable cs-ops` (install.sh does this). Restart the gateway after
enabling.
