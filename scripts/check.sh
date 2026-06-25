#!/usr/bin/env bash
# cs-agent-pro — readiness check (the Governance lever, operationalized). Run BEFORE go-live.
# Automates the core of the "Checklist Kesiapan": is the knowledge pack filled, and are the
# operating-manual governance rules intact? Exits non-zero if a HARD gate fails.
#
# Usage: bash scripts/check.sh [--workspace DIR]
set -uo pipefail   # run every check, then report (no -e)

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WS="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
SLUG="$(sed -n 's/^name:[[:space:]]*//p' "$SKILL_DIR/SKILL.md" | head -1 | sed 's/[[:space:]]*#.*//;s/[[:space:]]*$//')"; SLUG="${SLUG:-cs-agent-pro}"

while [ $# -gt 0 ]; do
  case "$1" in
    --workspace) WS="$2"; shift 2;;
    -h|--help)   grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

PASS=0; FAIL=0; WARN=0
pass(){ printf '  \033[32m[pass]\033[0m %s\n' "$*"; PASS=$((PASS+1)); }
fail(){ printf '  \033[31m[FAIL]\033[0m %s\n' "$*"; FAIL=$((FAIL+1)); }
warn(){ printf '  \033[33m[warn]\033[0m %s\n' "$*"; WARN=$((WARN+1)); }
printf '\033[1m== cs-agent-pro — readiness check (%s) ==\033[0m\n' "$WS"

KP="$WS/memory/$SLUG/knowledge-pack.md"
OM="$SKILL_DIR/references/operating-manual.md"

# ── Context lever — knowledge pack present & filled ──
if [ -f "$KP" ]; then
  pass "Context: knowledge pack present"
  if grep -q '{{' "$KP"; then fail "Context: {{placeholders}} still in knowledge pack — run onboarding"
  else pass "Context: no {{placeholders}} left"; fi
else
  fail "Context: knowledge pack missing ($KP) — run install.sh, then onboarding"
fi

# ── Governance lever — operating-manual rules intact ──
if [ -f "$OM" ]; then
  grep -qiE 'eskalasi|escalat' "$OM" && pass "Governance: escalation rules present" || fail "Governance: escalation rules missing"
  grep -qiE 'pembayaran|payment'  "$OM" && pass "Governance: payment guardrail present" || warn "Governance: payment guardrail not found"
  grep -qiE 'injection|identity-lock|tak-tepercaya|untrusted' "$OM" && pass "Governance: anti-injection rule present" || warn "Governance: anti-injection rule not found"
else
  warn "Governance: operating-manual not found at $OM"
fi

# ── Loop lever — onboarding-gate hook declared ──
grep -q '"onboarding-gate"' "$SKILL_DIR/openclaw.plugin.json" 2>/dev/null \
  && pass "Loop: onboarding-gate hook declared" || warn "Loop: onboarding-gate hook not declared"

# ── human-only check (cannot be automated) ──
warn "Not automated: run the red-team prompts (onboarding-and-checklist.md §B) — the agent must refuse all 5."

echo
if [ "$FAIL" -gt 0 ]; then printf '\033[31m%d failed\033[0m, %d passed, %d warn — NOT ready for go-live\n' "$FAIL" "$PASS" "$WARN"; exit 1; fi
printf '\033[32mready: %d passed\033[0m, %d warn\n' "$PASS" "$WARN"
