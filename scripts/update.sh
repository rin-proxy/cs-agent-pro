#!/usr/bin/env bash
# cs-agent-pro — update to the latest version from the source repo, then re-activate.
# Pulls newest code, then re-runs install.sh --force. Your workspace data (knowledge pack)
# is NEVER touched. Safe to run anytime; no-op if already current.
#
# Usage:
#   bash scripts/update.sh --repo git:OWNER/REPO [--workspace DIR]
#   (or set SKILL_REPO=git:... once and run: bash scripts/update.sh)
set -euo pipefail

# Re-exec from a stable temp copy FIRST: `skills install --force` overwrites THIS file
# mid-run. We capture the slug from the real skill dir before re-exec and carry it over.
if [ "${SKILL_REEXEC:-}" != "1" ]; then
  _SD="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  SKILL_SLUG="$(sed -n 's/^name:[[:space:]]*//p' "$_SD/SKILL.md" | head -1 | sed 's/[[:space:]]*#.*//;s/[[:space:]]*$//')"
  t="$(mktemp)"; cp "$0" "$t"
  SKILL_REEXEC=1 SKILL_SLUG="$SKILL_SLUG" exec bash "$t" "$@"
fi

SLUG="${SKILL_SLUG:-cs-agent-pro}"
WS="${OPENCLAW_WORKSPACE:-$HOME/.openclaw/workspace}"
REPO="${SKILL_REPO:-}"
while [ $# -gt 0 ]; do case "$1" in
  --repo) REPO="$2"; shift 2;;
  --workspace) WS="$2"; shift 2;;
  -h|--help) grep -E '^#( |$)' "$0" | sed 's/^# \{0,1\}//'; exit 0;;
  *) echo "unknown arg: $1" >&2; exit 2;; esac; done

[ -n "$REPO" ] || { echo "Set --repo git:<url> (or env SKILL_REPO)." >&2; exit 2; }
command -v openclaw >/dev/null 2>&1 || { echo "openclaw CLI not found." >&2; exit 1; }

SKILL="$WS/skills/$SLUG"            # default install location (use ~/.openclaw/skills for --global)
ver(){ sed -n 's/^version:[[:space:]]*//p' "$SKILL/SKILL.md" 2>/dev/null | head -1 | sed 's/[[:space:]]*#.*//;s/[[:space:]]*$//'; }
before="$(ver)"

echo "[1/2] pulling latest from $REPO  (current: ${before:-none})"
openclaw skills install "$REPO" --as "$SLUG" --force

echo "[2/2] re-activating (refresh wiring, keep your data)"
bash "$SKILL/scripts/install.sh" --workspace "$WS" --force

after="$(ver)"
echo
echo "$SLUG updated: ${before:-none} -> ${after:-?}"
[ -f "$SKILL/CHANGELOG.md" ] && { echo "--- latest changelog ---"; sed -n '1,16p' "$SKILL/CHANGELOG.md"; }
