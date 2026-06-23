#!/usr/bin/env bash
# cs-agent-pro — activation script (run ONCE after install). Idempotent + reversible.
# State (your knowledge pack) is written OUTSIDE the skill folder (into the workspace) so
# reinstall/upgrade never destroys your data. Slug is read automatically from SKILL.md `name:`.
#
# Usage: bash scripts/install.sh [--workspace DIR] [--no-hook] [--no-agents] [--force]
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WS="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
SLUG="$(sed -n 's/^name:[[:space:]]*//p' "$SKILL_DIR/SKILL.md" | head -1 | sed 's/[[:space:]]*#.*//;s/[[:space:]]*$//')"; SLUG="${SLUG:-cs-agent-pro}"
DO_HOOK=1; DO_AGENTS=1; FORCE=0

while [ $# -gt 0 ]; do
  case "$1" in
    --workspace) WS="$2"; shift 2;;
    --no-hook)   DO_HOOK=0; shift;;
    --no-agents) DO_AGENTS=0; shift;;
    --force)     FORCE=1; shift;;
    -h|--help)   grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

ok(){   printf '  \033[32m[ok]\033[0m   %s\n' "$*"; }
skip(){ printf '  \033[33m[skip]\033[0m %s\n' "$*"; }
hr(){   printf '\033[1m== %s ==\033[0m\n' "$*"; }

[ -d "$WS" ] || { echo "Workspace not found: $WS  (pass --workspace DIR)" >&2; exit 1; }
chmod +x "$SKILL_DIR/scripts/"*.sh 2>/dev/null || true

echo; hr "$SLUG -> $WS"

# ── 1/3) seed the workspace knowledge pack (the ONLY file the owner edits) ─────
hr "1/3 knowledge pack"
KP_DIR="$WS/memory/$SLUG"
if [ -f "$KP_DIR/knowledge-pack.md" ]; then
  skip "memory/$SLUG/knowledge-pack.md (kept — your data)"
else
  mkdir -p "$KP_DIR"
  cp "$SKILL_DIR/references/knowledge-pack.md" "$KP_DIR/knowledge-pack.md"
  ok "memory/$SLUG/knowledge-pack.md (seeded from template — fill this in)"
fi

# ── 2/3) enable the onboarding-gate hook (best-effort; tolerates older CLIs) ───
# This is what makes the agent PROACTIVELY start onboarding on a new session when the
# knowledge pack is still unfilled. The AGENTS.md pointer (step 3) is the always-on backstop.
if [ "$DO_HOOK" = 1 ]; then
  hr "2/3 enable hook: onboarding-gate"
  if command -v openclaw >/dev/null 2>&1; then
    if openclaw hooks enable onboarding-gate >/dev/null 2>&1; then
      ok "hook enabled via openclaw"
      echo "       NOTE: restart the Gateway so the hook loads."
    else
      skip "could not auto-enable (run: openclaw hooks enable onboarding-gate, then restart gateway)"
    fi
  else
    skip "openclaw not on PATH — enable manually: openclaw hooks enable onboarding-gate"
  fi
else
  skip "2/3 hook (--no-hook)"
fi

# ── 3/3) wire a usage pointer into AGENTS.md (idempotent, marker-fenced, backed up)
if [ "$DO_AGENTS" = 1 ]; then
  hr "3/3 AGENTS.md wiring"
  AGENTS="$WS/AGENTS.md"
  BEGIN="<!-- BEGIN:$SLUG (managed — do not edit between markers) -->"
  END="<!-- END:$SLUG -->"
  BLOCK="$BEGIN
## $SLUG — Customer Service agent
- Saat diminta jadi CS / saat pesan pertama untuk bisnis masuk: muat skill **$SLUG** — baca \`skills/$SLUG/references/operating-manual.md\` (perilaku) + \`memory/$SLUG/knowledge-pack.md\` (fakta), lalu ikuti operating manual.
- **PROAKTIF:** jika knowledge pack belum ada / masih berisi \`{{...}}\`, JANGAN layani pelanggan dulu — langsung MULAI wawancara onboarding (\`skills/$SLUG/references/onboarding-and-checklist.md\`), tanya pemilik satu per satu, tulis hasilnya ke \`memory/$SLUG/knowledge-pack.md\`. (Hook \`onboarding-gate\` juga memicu ini otomatis saat sesi baru.)
- Jawab HANYA dari knowledge pack (jangan mengarang harga/kebijakan/janji). Eskalasi refund/sengketa/abuse/hukum ke manusia. JANGAN konfirmasi pembayaran tanpa verifikasi.
$END"
  touch "$AGENTS"
  if grep -qF "$BEGIN" "$AGENTS" 2>/dev/null; then
    if [ "$FORCE" = 1 ]; then
      cp "$AGENTS" "$AGENTS.bak.$(date -u +%Y%m%d%H%M%S 2>/dev/null || echo bak)"
      awk -v b="$BEGIN" -v e="$END" -v repl="$BLOCK" '
        $0==b {print repl; skip=1; next} $0==e {skip=0; next} !skip {print}' \
        "$AGENTS" > "$AGENTS.tmp" && mv "$AGENTS.tmp" "$AGENTS"
      ok "AGENTS.md block refreshed (--force)"
    else
      skip "AGENTS.md already wired (use --force to refresh)"
    fi
  else
    printf '\n%s\n' "$BLOCK" >> "$AGENTS"; ok "AGENTS.md block appended"
  fi
else
  skip "3/3 AGENTS.md (--no-agents)"
fi

echo; hr "done"
echo "Next: isi  $KP_DIR/knowledge-pack.md  (atau buka sesi baru — agen akan tanya otomatis)."
echo "Undo: bash $SKILL_DIR/scripts/uninstall.sh --workspace $WS"
