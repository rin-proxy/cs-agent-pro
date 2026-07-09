// cs-ops — the operational layer that turns cs-agent-pro from a prompt into a running
// service. It does three things the prompt alone cannot:
//   1. LOG every turn (inbound + outbound) to memory/cs-agent-pro/logs/conversations-<date>.jsonl
//   2. CAPTURE knowledge-pack gaps — when the agent uses the grounding fallback
//      ("...belum punya datanya..."), record the question so the owner can fill the pack.
//   3. DELIVER escalations — when the agent hands off to a human ("...hubungkan ke tim..."),
//      record it AND push it out-of-band to a configured webhook (Telegram/Slack/Discord/
//      generic). The prompt can compose a handoff but cannot reach the admin; this can.
//
// Fires on message:received + message:sent (docs.openclaw.ai/automation/hooks). Both are
// WRITE-ONLY here (append a file / POST a webhook) — it never pushes text back to chat, so
// the "only command:* + compact:* are replyable" limitation does NOT apply to this hook.
//
// Config (first found wins): env CS_ESCALATION_WEBHOOK / CS_LOG, then
// memory/cs-agent-pro/ops-config.json { "escalationWebhook": "...", "logging": true }.
// Every path is wrapped so a failure here can NEVER break message handling.
import { existsSync, readFileSync, appendFileSync, mkdirSync } from "node:fs";
import { join, dirname } from "node:path";

// The agent's OWN prescribed scripts, matched verbatim from the operating manual:
const FALLBACK_RE = /belum punya datanya|di luar cakupan(ku)?/i;              // §4.3 grounding fallback → KB gap
const ESCALATION_RE = /hubungkan (kakak )?ke tim|teruskan konteks|tim kami (akan|yang)|saya hubungkan ke/i; // §7 warm handoff

// Per-process memory so an outbound KB-gap/escalation can be paired with the question that
// triggered it (module scope persists across invocations, like onboarding-gate's Set).
const lastInbound = new Map();

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

function firstStr(...vals) {
  for (const v of vals) if (typeof v === "string" && v.trim()) return v;
  return "";
}

// Message text/channel live in different fields per gateway/adapter — probe broadly, degrade
// to "" (a no-op turn) rather than throwing if the adapter doesn't provide them.
function messageText(event) {
  const c = event.context || {};
  return firstStr(c.text, event.text, c.message?.text, event.message?.text, c.body, c.content, c.payload?.text);
}
function channelOf(event) {
  const c = event.context || {};
  return firstStr(c.channel, c.channelId, c.source, c.platform, event.channel) || "unknown";
}

function loadConfig(ws) {
  const cfg = {
    escalationWebhook: process.env.CS_ESCALATION_WEBHOOK || "",
    logging: process.env.CS_LOG !== "off",
  };
  try {
    const p = join(ws, "memory", "cs-agent-pro", "ops-config.json");
    if (existsSync(p)) {
      const j = JSON.parse(readFileSync(p, "utf8"));
      if (!cfg.escalationWebhook && typeof j.escalationWebhook === "string") cfg.escalationWebhook = j.escalationWebhook;
      if (j.logging === false) cfg.logging = false;
    }
  } catch { /* bad config must not disable the hook */ }
  return cfg;
}

function appendJsonl(file, obj) {
  mkdirSync(dirname(file), { recursive: true });
  appendFileSync(file, JSON.stringify(obj) + "\n");
}

// Single-line, quote-free key for grouping identical questions in report.sh.
function sanitize(s) {
  return (s || "").replace(/\s+/g, " ").replace(/[^\p{L}\p{N} ?.,%/-]/gu, "").trim().slice(0, 120);
}

async function postWebhook(url, payload) {
  if (!url) return;
  try {
    const ctrl = new AbortController();
    const t = setTimeout(() => ctrl.abort(), 4000); // never let a slow webhook stall the gateway
    // Send `text` (Slack/Telegram/generic) AND `content` (Discord) so one payload fits most sinks.
    await fetch(url, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ text: payload.text, content: payload.text, ...payload }),
      signal: ctrl.signal,
    }).catch(() => {});
    clearTimeout(t);
  } catch { /* delivery is best-effort; escalations.jsonl is the durable backstop */ }
}

const handler = async (event) => {
  try {
    const isIn = event.type === "message" && event.action === "received";
    const isOut = event.type === "message" && event.action === "sent";
    if (!isIn && !isOut) return;

    const ctx = event.context || {};
    const ws = workspaceDir(ctx);
    const cfg = loadConfig(ws);
    const memDir = join(ws, "memory", "cs-agent-pro");
    const text = messageText(event);
    const sid = String(sessionId(ctx) ?? "");
    const channel = channelOf(event);
    const ts = new Date().toISOString();
    const date = ts.slice(0, 10);

    if (isIn && sid) lastInbound.set(sid, text);

    // 1) durable conversation log
    if (cfg.logging && text) {
      appendJsonl(join(memDir, "logs", `conversations-${date}.jsonl`), {
        ts, dir: isIn ? "in" : "out", channel, session: sid || null, text,
      });
    }

    // 2) classify the agent's outbound reply (fallback = KB gap; handoff = escalation)
    if (isOut && text) {
      const question = (sid && lastInbound.get(sid)) || "";
      if (FALLBACK_RE.test(text)) {
        appendJsonl(join(memDir, "kb-gaps.jsonl"), {
          ts, session: sid || null, channel, q: sanitize(question), question, answer: text,
        });
      } else if (ESCALATION_RE.test(text)) {
        const rec = { ts, session: sid || null, channel, question, handoff: text };
        appendJsonl(join(memDir, "escalations.jsonl"), rec);
        await postWebhook(cfg.escalationWebhook, {
          text: `[cs-agent-pro] Eskalasi (${channel}) ${ts}\nPelanggan: ${question || "(tak terekam)"}\nAgen: ${text}`,
          ...rec,
        });
      }
    }
  } catch (error) {
    // a broken hook must never break message handling
    console.warn(`[cs-ops] failed: ${error instanceof Error ? error.message : String(error)}`);
  }
};

export default handler;
