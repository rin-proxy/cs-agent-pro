// onboarding-gate — proactively starts cs-agent-pro onboarding when the knowledge pack
// is still unfilled, so the owner never needs a special prompt.
//
// Fires on TWO replyable events (docs.openclaw.ai/automation/hooks):
//   • command:new      — a new session opened via /new (CLI / desktop)
//   • message:received — first inbound message (covers channel bots like WhatsApp /
//                        Telegram whose sessions start WITHOUT an explicit /new)
// On either, if memory/cs-agent-pro/knowledge-pack.md is missing or still has {{...}},
// it pushes exactly ONE nudge per session telling the agent to begin the onboarding
// interview. If the pack is filled, it stays silent (no disruption to live CS operation).
// The hook is the TRIGGER; the agent (SKILL.md step 3) is the EXECUTOR.
// Pattern mirrors smart-cache's file-hook (proven on the gateway).
import { existsSync, readFileSync } from "node:fs";
import { join } from "node:path";

// Process-lifetime state (module scope persists across invocations, like smart-cache's tee counter):
const NUDGED = new Set();   // session ids already nudged → at most one nudge per session
let lastNudgeAt = 0;        // universal time-throttle backstop (covers events with no session id)
const THROTTLE_MS = 60_000;

function workspaceDir(ctx) {
  return (
    ctx?.workspaceDir ||
    process.env.OPENCLAW_WORKSPACE ||
    join(process.env.HOME || ".", ".openclaw", "workspace")
  );
}

function sessionId(ctx) {
  return ctx?.sessionId ?? ctx?.sessionEntry?.id ?? ctx?.sessionEntry ?? ctx?.session?.id ?? null;
}

// returns a reason string if the knowledge pack is unfilled, else null (= ready, stay silent)
function unfilledReason(ctx) {
  const kp = join(workspaceDir(ctx), "memory", "cs-agent-pro", "knowledge-pack.md");
  if (!existsSync(kp)) return "Knowledge pack belum ada";
  if (readFileSync(kp, "utf8").includes("{{"))
    return "Knowledge pack masih punya placeholder {{...}} yang belum diisi";
  return null;
}

const handler = async (event) => {
  try {
    const isNewSession = event.type === "command" && event.action === "new";
    const isInboundMsg = event.type === "message" && event.action === "received";
    if (!isNewSession && !isInboundMsg) return; // ignore every other event

    const ctx = event.context || {};
    const reason = unfilledReason(ctx);
    if (!reason) return; // pack is ready → silent (check BEFORE the guard so it never burns a slot)

    // Nudge at most once per session: dedupe command:new + message:received of the same session.
    const sid = sessionId(ctx);
    if (sid != null) {
      if (NUDGED.has(sid)) return;
      NUDGED.add(sid);
    } else if (Date.now() - lastNudgeAt < THROTTLE_MS) {
      return; // no session id → fall back to a time-throttle so channels don't get spammed
    }
    lastNudgeAt = Date.now(); // universal backstop across mixed-id event types

    event.messages?.push(
      `[cs-agent-pro] Setup belum selesai — ${reason}. Sebelum melayani pelanggan, ` +
        `MULAI wawancara onboarding SEKARANG: baca skills/cs-agent-pro/references/onboarding-and-checklist.md, ` +
        `tanyakan ke pemilik satu pertanyaan per giliran, lalu tulis hasilnya ke ` +
        `memory/cs-agent-pro/knowledge-pack.md.`,
    );
  } catch (error) {
    // a broken hook must never break session start / message handling
    console.warn(
      `[onboarding-gate] failed: ${error instanceof Error ? error.message : String(error)}`,
    );
  }
};

export default handler;
