---
name: onboarding-gate
description: "Proactively starts cs-agent-pro onboarding when the knowledge pack is unfilled. Fires on a new session (command:new) AND on the first inbound message (message:received, for channel bots), nudging the agent to begin the onboarding interview — once per session — so the owner needs no special prompt."
metadata:
  {
    "openclaw":
      {
        "emoji": "🎧",
        "events": ["command:new", "message:received"],
        "always": true
      }
  }
---

# Onboarding Gate

Checks `memory/cs-agent-pro/knowledge-pack.md` in the workspace; if it is missing or still
contains `{{...}}` placeholders, it pushes a nudge so the agent **starts the onboarding
wizard** (`references/onboarding-and-checklist.md`) right away. If the pack is already
filled, the hook stays silent — no disruption to normal CS operation.

## Two events, once per session
Both events are *replyable* surfaces (docs.openclaw.ai/automation/hooks), so
`event.messages.push(...)` reaches the agent:
- **`command:new`** — covers sessions opened via `/new` (CLI / desktop).
- **`message:received`** — covers **channel bots** (WhatsApp / Telegram) whose sessions
  start on the first inbound message, with no `/new`.

A process-level guard (a `Set` of session ids, with a 60s time-throttle fallback when no
session id is present) ensures the agent is nudged **at most once per session** — so
`command:new` + the first `message:received` of the same session never double-nudge, and
the owner's onboarding replies don't re-trigger it.

## Why a hook can't do the setup itself
The hook can only nudge — it cannot run the interview or write the pack; only the agent
(guided by `SKILL.md` step 3) can. The hook is the **trigger**, the agent is the **executor**.

## Backstop
Even if neither event fires on some exotic surface, the always-on `AGENTS.md` pointer still
instructs the agent to onboard-first the moment it is asked to act as CS — so onboarding is
never skipped.

Enable with `openclaw hooks enable onboarding-gate` (install.sh does this). Restart the
gateway after enabling.
