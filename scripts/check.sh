#!/usr/bin/env bash
# cs-agent-pro — readiness check (the Governance lever, operationalized). Run BEFORE go-live.
# Validates the OWNER'S knowledge pack against the "Checklist Kesiapan" (onboarding-and-checklist
# §B): filled, and with enough real content (products, FAQ, escalation contact) to serve customers.
# HARD gates exit non-zero. Also verifies engine integrity + that the hooks are declared.
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

# prints the lines under a "### <pat>" heading up to the next "### " heading
section(){ awk -v p="$1" '$0 ~ ("^### " p){f=1; next} /^### /{if(f) exit} f' "$KP" 2>/dev/null; }
# is a labeled line filled? $1 = case-insensitive label regex. Empty/placeholder-only => false.
field_filled(){
  local line val
  line="$(grep -m1 -iE "$1" "$KP" 2>/dev/null)" || return 1
  [ -n "$line" ] || return 1
  val="$(printf '%s' "$line" | sed -E 's/.*:[[:space:]]*//' | tr -d '`*_ ')"
  [ -n "$val" ]
}

# ── Context lever — knowledge pack present, filled & substantive ──
printf '\033[1m-- knowledge pack --\033[0m\n'
if [ ! -f "$KP" ]; then
  fail "knowledge pack missing ($KP) — run install.sh, then onboarding"
else
  pass "knowledge pack present"

  if grep -q '{{' "$KP"; then fail "{{placeholders}} still present — run onboarding to finish"
  else pass "no {{placeholders}} left"; fi

  # HARD: >=3 products (B2), >=5 FAQ (B6), escalation contact (B5)
  nprod="$(section 'B2' | grep -cE '^[0-9]+\.' || true)"
  [ "${nprod:-0}" -ge 3 ] && pass "products: $nprod (>=3)" || fail "products: ${nprod:-0} (need >=3 in B2)"

  nfaq="$(section 'B6' | grep -ciE '^Q:' || true)"
  [ "${nfaq:-0}" -ge 5 ] && pass "FAQ pairs: $nfaq (>=5)" || fail "FAQ pairs: ${nfaq:-0} (need >=5 in B6)"

  field_filled 'Kontak eskalasi' && pass "escalation contact filled (B5)" \
    || fail "escalation contact empty (B5) — the agent can't hand off without it"

  # RECOMMENDED (heuristic → warn only)
  field_filled 'Nama bisnis'     && pass "business name filled (B1)"   || warn "business name looks empty (B1)"
  field_filled 'Nama agen'       && pass "bot name filled (B1)"        || warn "bot name looks empty (B1)"
  field_filled 'Jam operasional' && pass "operating hours filled (B4)" || warn "operating hours look empty (B4)"
fi

# ── Governance / engine integrity — the shipped operating manual is intact ──
printf '\033[1m-- engine integrity --\033[0m\n'
if [ -f "$OM" ]; then
  pass "operating manual present"
  grep -qiE 'eskalasi|escalat'   "$OM" && pass "escalation rules intact"   || warn "escalation rules not found in manual"
  grep -qiE 'pembayaran|payment' "$OM" && pass "payment guardrail intact"  || warn "payment guardrail not found in manual"
  grep -qiE 'injection|identity-lock|tak-tepercaya|untrusted' "$OM" && pass "anti-injection rule intact" || warn "anti-injection rule not found"
else
  fail "operating manual missing ($OM) — the agent has no behavior; reinstall"
fi

# ── Loop / Ops lever — hooks declared ──
printf '\033[1m-- hooks --\033[0m\n'
PJ="$SKILL_DIR/openclaw.plugin.json"
grep -q '"onboarding-gate"' "$PJ" 2>/dev/null && pass "onboarding-gate hook declared" || warn "onboarding-gate hook not declared"
grep -q '"cs-ops"'          "$PJ" 2>/dev/null && pass "cs-ops hook declared (logging + escalation delivery)" || warn "cs-ops hook not declared"

# ── human-only check (cannot be automated) ──
warn "Not automated: run the red-team prompts (onboarding-and-checklist.md §B) — the agent must refuse all 5."

echo
if [ "$FAIL" -gt 0 ]; then printf '\033[31m%d failed\033[0m, %d passed, %d warn — NOT ready for go-live\n' "$FAIL" "$PASS" "$WARN"; exit 1; fi
printf '\033[32mready: %d passed\033[0m, %d warn\n' "$PASS" "$WARN"
