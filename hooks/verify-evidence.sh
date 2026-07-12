#!/usr/bin/env bash
# verify-evidence.sh — PostToolUse hook.
#
# Blocks marking a step's verification complete unless the /verify run produced
# concrete evidence of one of three verification modes:
#   1. a Playwright screenshot / video artifact
#   2. a curl command
#   3. a DB check (psql / sqlite / \dt / SELECT)
#
# Installed to ~/.claude/hooks/ by the harness install.sh and registered as a
# PostToolUse hook in ~/.claude/settings.json. It no-ops for every tool/skill
# call except the `verify` skill, so it is cheap to run globally.
#
# Manual settings.json registration (if install.sh could not use jq):
#   "hooks": { "PostToolUse": [
#     { "matcher": "Skill",
#       "hooks": [ { "type": "command", "command": "<abs path>/verify-evidence.sh" } ] }
#   ] }
set -euo pipefail

payload="$(cat)"

# Act only on the verify skill; no-op for all other tool/skill calls.
grep -Eq '"(skill|command|name)"[[:space:]]*:[[:space:]]*"/?verify"' <<<"$payload" || exit 0

# Determine the project dir the tool ran in (fall back to CWD).
proj=""
if command -v jq >/dev/null 2>&1; then
  proj="$(jq -r '.cwd // empty' <<<"$payload" 2>/dev/null || true)"
fi
[[ -z "$proj" ]] && proj="$(pwd)"

# Find the most recently written verify report (matches docs/<feature>/verify/*.md
# and the docs/verify/*.md fallback).
report="$(find "$proj" -type f -path '*verify*' -name '*.md' -print0 2>/dev/null \
  | xargs -0 ls -t 2>/dev/null | head -1 || true)"

fail() {
  # Exit 2 → stderr is fed back to Claude, which must NOT mark Verify complete.
  echo "$1" >&2
  exit 2
}

[[ -z "$report" ]] && fail "verify-evidence: no verify report found under $proj. Verification requires concrete evidence — a curl command, a Playwright screenshot/video, or a DB check (psql/sqlite). Do not mark the Verify column complete."

if grep -Eqi '(^|[^[:alnum:]])curl[[:space:]]' "$report" \
   || grep -Eqi '\.(png|jpe?g|webm|mp4)|playwright|screenshot|\.trace' "$report" \
   || grep -Eqi 'psql|sqlite3?|\\dt|\\d[[:space:]]|SELECT[[:space:]]|INSERT[[:space:]]' "$report"; then
  exit 0
fi

fail "verify-evidence: the verify report ($report) contains no concrete verification evidence. Add ONE of: (1) a Playwright screenshot/video, (2) a curl command, or (3) a DB check (psql/sqlite/\\dt/SELECT), then re-run /verify. Do not mark the Verify column complete."
