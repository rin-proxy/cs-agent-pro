#!/usr/bin/env bash
# cs-agent-pro — owner feedback report. Turns what the cs-ops hook captured into something
# you can act on: how many conversations, how many escalations, and — most useful — the TOP
# unanswered questions (knowledge-pack gaps). Those are exactly what to add to your pack next.
#
# Usage: bash scripts/report.sh [--workspace DIR] [--days N]   (default: last 7 days)
# Prefers python3 for the full report; falls back to a counts-only summary (awk) without it.
set -uo pipefail

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WS="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
SLUG="$(sed -n 's/^name:[[:space:]]*//p' "$SKILL_DIR/SKILL.md" | head -1 | sed 's/[[:space:]]*#.*//;s/[[:space:]]*$//')"; SLUG="${SLUG:-cs-agent-pro}"
DAYS=7

while [ $# -gt 0 ]; do
  case "$1" in
    --workspace) WS="$2"; shift 2;;
    --days)      DAYS="$2"; shift 2;;
    -h|--help)   grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
    *) echo "unknown arg: $1" >&2; exit 2;;
  esac
done

MEM="$WS/memory/$SLUG"
[ -d "$MEM" ] || { echo "No data dir at $MEM — is the skill installed & the gateway running?"; exit 0; }

if command -v python3 >/dev/null 2>&1; then
  MEM="$MEM" DAYS="$DAYS" python3 - <<'PY'
import glob, json, os, datetime as dt

mem = os.environ["MEM"]; days = int(os.environ["DAYS"])
cutoff = dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=days)

def rows(path):
    for fn in sorted(glob.glob(path)):
        try:
            with open(fn, encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line: continue
                    try: yield json.loads(line)
                    except Exception: continue
        except FileNotFoundError:
            continue

def recent(r):
    ts = r.get("ts", "")
    try: return dt.datetime.fromisoformat(ts.replace("Z", "+00:00")) >= cutoff
    except Exception: return True   # keep undated rows rather than silently drop

conv = [r for r in rows(os.path.join(mem, "logs", "conversations-*.jsonl")) if recent(r)]
esc  = [r for r in rows(os.path.join(mem, "escalations.jsonl")) if recent(r)]
gaps = [r for r in rows(os.path.join(mem, "kb-gaps.jsonl")) if recent(r)]

n_in  = sum(1 for r in conv if r.get("dir") == "in")
n_out = sum(1 for r in conv if r.get("dir") == "out")

print(f"\033[1m== cs-agent-pro report — last {days} day(s) ==\033[0m")
print(f"  conversations : {n_in} inbound / {n_out} outbound")
print(f"  escalations   : {len(esc)}")
print(f"  KB gaps       : {len(gaps)} (questions the agent couldn't answer from the pack)")

if esc:
    print("\n\033[1m-- recent escalations --\033[0m")
    for r in esc[-5:]:
        q = (r.get("question") or "").replace("\n", " ")[:80]
        print(f"  [{r.get('ts','')[:16]}] ({r.get('channel','?')}) {q or '(question not captured)'}")

if gaps:
    from collections import Counter
    c = Counter((r.get("q") or (r.get("question") or "").replace('\n',' ')[:120]).strip().lower() for r in gaps)
    print("\n\033[1m-- top unanswered questions (add these to the knowledge pack) --\033[0m")
    for q, n in c.most_common(10):
        print(f"  {n:3d}x  {q or '(empty)'}")
else:
    print("\n  No KB gaps logged — either the pack covers everything, or no traffic yet.")
PY
else
  echo "== cs-agent-pro report (counts only — install python3 for the full report) =="
  ci=0; co=0
  for f in "$MEM"/logs/conversations-*.jsonl; do [ -f "$f" ] || continue
    ci=$((ci + $(grep -c '"dir":"in"'  "$f" 2>/dev/null || echo 0)))
    co=$((co + $(grep -c '"dir":"out"' "$f" 2>/dev/null || echo 0)))
  done
  ne=0; [ -f "$MEM/escalations.jsonl" ] && ne=$(grep -c . "$MEM/escalations.jsonl" 2>/dev/null || echo 0)
  ng=0; [ -f "$MEM/kb-gaps.jsonl" ]     && ng=$(grep -c . "$MEM/kb-gaps.jsonl" 2>/dev/null || echo 0)
  echo "  conversations : $ci inbound / $co outbound"
  echo "  escalations   : $ne"
  echo "  KB gaps       : $ng  (see $MEM/kb-gaps.jsonl for the questions)"
fi
