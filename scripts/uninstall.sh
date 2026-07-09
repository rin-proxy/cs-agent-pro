#!/usr/bin/env bash
# cs-agent-pro — reverse install.sh. Disables the onboarding-gate hook and removes the
# AGENTS.md managed block. Does NOT delete your data (the knowledge pack) — that's yours.
set -euo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WS="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
SLUG="$(sed -n 's/^name:[[:space:]]*//p' "$SKILL_DIR/SKILL.md" | head -1 | sed 's/[[:space:]]*#.*//;s/[[:space:]]*$//')"; SLUG="${SLUG:-cs-agent-pro}"
while [ $# -gt 0 ]; do case "$1" in
  --workspace) WS="$2"; shift 2;;
  -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
  *) echo "unknown arg: $1" >&2; exit 2;; esac; done

# ── disable the hooks (onboarding-gate + cs-ops) ──────────────────────────────
if command -v openclaw >/dev/null 2>&1; then
  for h in onboarding-gate cs-ops; do
    if openclaw hooks disable "$h" >/dev/null 2>&1; then echo "  [ok]   hook disabled: $h (restart gateway to fully unload)"
    else echo "  [skip] $h not disabled (already off)"; fi
  done
else
  echo "  [skip] hooks not disabled (openclaw not on PATH)"
fi

# ── strip the AGENTS.md managed block ─────────────────────────────────────────
AGENTS="$WS/AGENTS.md"
BEGIN="<!-- BEGIN:$SLUG (managed — do not edit between markers) -->"
END="<!-- END:$SLUG -->"
if [ -f "$AGENTS" ] && grep -qF "$BEGIN" "$AGENTS"; then
  cp "$AGENTS" "$AGENTS.bak.$(date -u +%Y%m%d%H%M%S 2>/dev/null || echo bak)"
  awk -v b="$BEGIN" -v e="$END" '$0==b{skip=1} !skip{print} $0==e{skip=0}' "$AGENTS" > "$AGENTS.tmp" \
    && mv "$AGENTS.tmp" "$AGENTS"
  echo "  [ok]   AGENTS.md block removed (backup kept)"
else
  echo "  [skip] no AGENTS.md block found"
fi
echo "  [i]    knowledge pack kamu di $WS/memory/$SLUG/ tetap aman."
