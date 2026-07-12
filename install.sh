#!/usr/bin/env bash
# install.sh — FALLBACK installer for users who don't use the Claude Code plugin system.
#
# The primary install path is the plugin marketplace (see Readme.md):
#   /plugin marketplace add rolopez23/agent-harness
#   /plugin install rl-as@agent-harness
#
# This script is the no-plugin alternative. It copies skills into <claude-dir>/skills/
# and installs the verify + tone hooks at the user level, so skills are available
# un-namespaced (/verify, /plan, …). It does NOT write global AGENTS.md/CLAUDE.md —
# run /initialize inside a project to add the workflow/routing context there.
#
# Usage:
#   ./install.sh                          # default install into ~/.claude
#   ./install.sh --dir <path>             # alternate Claude Code dir (testing)
#   ./install.sh --with <skill>           # also install an optional skill
#                                         # (repeatable; e.g. --with next-react-boot)
#   ./install.sh --with all               # install every optional skill

set -euo pipefail

HARNESS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ── optional skills ───────────────────────────────────────────────────────────
# Skipped by default; opt in with --with <name>.
OPTIONAL_SKILLS=(next-react-boot python-psql-boot)

# ── arg parsing ───────────────────────────────────────────────────────────────
USER_CLAUDE_DIR="$HOME/.claude"
REQUESTED_OPTIONAL=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dir)
      USER_CLAUDE_DIR="$2"
      shift 2
      ;;
    --with)
      if [[ "$2" == "all" ]]; then
        REQUESTED_OPTIONAL=("${OPTIONAL_SKILLS[@]}")
      else
        REQUESTED_OPTIONAL+=("$2")
      fi
      shift 2
      ;;
    -h|--help)
      sed -n '2,19p' "$0"
      exit 0
      ;;
    *)
      printf 'unknown argument: %s\n' "$1" >&2
      printf 'see ./install.sh --help\n' >&2
      exit 1
      ;;
  esac
done

mkdir -p "$USER_CLAUDE_DIR"
USER_CLAUDE_DIR="$(cd "$USER_CLAUDE_DIR" && pwd)"
SKILLS_SRC="$HARNESS_DIR/skills"
SKILLS_DST="$USER_CLAUDE_DIR/skills"

# Validate any requested optional skills actually exist on disk.
for req in "${REQUESTED_OPTIONAL[@]+"${REQUESTED_OPTIONAL[@]}"}"; do
  if [[ ! -d "$SKILLS_SRC/$req" ]]; then
    printf 'requested optional skill not found: %s\n' "$req" >&2
    printf 'available optional skills: %s\n' "${OPTIONAL_SKILLS[*]}" >&2
    exit 1
  fi
done

# Helper: is this skill name an optional one?
is_optional() {
  local name="$1"
  local s
  for s in "${OPTIONAL_SKILLS[@]}"; do
    [[ "$s" == "$name" ]] && return 0
  done
  return 1
}

# Helper: was this optional skill requested?
is_requested() {
  local name="$1"
  local s
  for s in "${REQUESTED_OPTIONAL[@]+"${REQUESTED_OPTIONAL[@]}"}"; do
    [[ "$s" == "$name" ]] && return 0
  done
  return 1
}

# ── helpers ───────────────────────────────────────────────────────────────────

green()  { printf '\033[32m%s\033[0m\n' "$*"; }
yellow() { printf '\033[33m%s\033[0m\n' "$*"; }
bold()   { printf '\033[1m%s\033[0m\n' "$*"; }

# ── 1. copy skills ────────────────────────────────────────────────────────────

mkdir -p "$SKILLS_DST"

installed=()
updated=()
skipped=()

for skill_dir in "$SKILLS_SRC"/*/; do
  skill_name="$(basename "$skill_dir")"
  dst="$SKILLS_DST/$skill_name"

  if is_optional "$skill_name" && ! is_requested "$skill_name"; then
    skipped+=("$skill_name")
    continue
  fi

  if [[ -d "$dst" ]]; then
    rm -rf "$dst"
    cp -r "$skill_dir" "$dst"
    updated+=("$skill_name")
  else
    cp -r "$skill_dir" "$dst"
    installed+=("$skill_name")
  fi
done

# Prune skills that no longer exist in the harness source (handles renames + removals).
# An optional skill that wasn't requested is NOT pruned — it still exists in the source,
# so only genuinely deleted/renamed skills are removed.
removed=()
if [[ -d "$SKILLS_DST" ]]; then
  for dst_dir in "$SKILLS_DST"/*/; do
    [[ -d "$dst_dir" ]] || continue
    dst_name="$(basename "$dst_dir")"
    if [[ ! -d "$SKILLS_SRC/$dst_name" ]]; then
      rm -rf "$dst_dir"
      removed+=("$dst_name")
    fi
  done
fi

bold "Skills → $SKILLS_DST"
for s in "${installed[@]+"${installed[@]}"}"; do green  "  + $s"; done
for s in "${updated[@]+"${updated[@]}"}";    do yellow "  ↺ $s"; done
for s in "${removed[@]+"${removed[@]}"}";    do printf '  - %s (removed — no longer in harness)\n' "$s"; done
for s in "${skipped[@]+"${skipped[@]}"}";    do printf '  · %s (optional — request with --with %s)\n' "$s" "$s"; done

# ── 2. hooks + settings ───────────────────────────────────────────────────────
# verify-evidence.sh (PostToolUse) blocks marking a step verified without real evidence.
# tone-hooks.sh (SessionStart + UserPromptSubmit) injects the house tone / coding standards.

printf '\n'
bold "Hooks → $USER_CLAUDE_DIR/hooks"

HOOKS_DST="$USER_CLAUDE_DIR/hooks"
mkdir -p "$HOOKS_DST"
cp "$HARNESS_DIR/hooks/verify-evidence.sh" "$HOOKS_DST/verify-evidence.sh"
chmod +x "$HOOKS_DST/verify-evidence.sh"
green "  + verify-evidence.sh"

cp "$HARNESS_DIR/hooks/tone-hooks.sh" "$HOOKS_DST/tone-hooks.sh"
chmod +x "$HOOKS_DST/tone-hooks.sh"
green "  + tone-hooks.sh"

# Tone + coding-standards source files (read by tone-hooks.sh at runtime).
TONE_DST="$USER_CLAUDE_DIR/tone"
mkdir -p "$TONE_DST"
cp "$HARNESS_DIR/tone/tone.md" "$TONE_DST/tone.md"
cp "$HARNESS_DIR/tone/coding-standards.md" "$TONE_DST/coding-standards.md"
green "  + tone/ (tone.md, coding-standards.md)"

SETTINGS="$USER_CLAUDE_DIR/settings.json"
HOOK_CMD="$HOOKS_DST/verify-evidence.sh"

if command -v jq >/dev/null 2>&1; then
  [[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"
  if jq -e --arg c "$HOOK_CMD" '[.hooks.PostToolUse[]?.hooks[]?.command] | index($c)' "$SETTINGS" >/dev/null 2>&1; then
    yellow "  settings.json already registers the verify-evidence hook — no change"
  else
    tmp="$(mktemp)"
    jq --arg c "$HOOK_CMD" '
      .hooks.PostToolUse = ((.hooks.PostToolUse // []) + [
        { matcher: "Skill", hooks: [ { type: "command", command: $c } ] }
      ])' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    green "  + registered verify-evidence PostToolUse hook in settings.json"
  fi
else
  yellow "  jq not found — add this to $SETTINGS manually:"
  cat <<EOF
    "hooks": { "PostToolUse": [
      { "matcher": "Skill",
        "hooks": [ { "type": "command", "command": "$HOOK_CMD" } ] } ] }
EOF
fi

# Tone hooks: inject house tone (every turn) + coding standards (on coding prompts).
TONE_HOOK="$HOOKS_DST/tone-hooks.sh"

register_tone_hook() {
  local evt="$1" cmd="$2" tmp
  if jq -e --arg e "$evt" --arg c "$cmd" '[.hooks[$e][]?.hooks[]?.command] | index($c)' "$SETTINGS" >/dev/null 2>&1; then
    yellow "  $evt already registers the tone hook — no change"
  else
    tmp="$(mktemp)"
    jq --arg e "$evt" --arg c "$cmd" '
      .hooks[$e] = ((.hooks[$e] // []) + [
        { matcher: "", hooks: [ { type: "command", command: $c } ] }
      ])' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
    green "  + registered tone $evt hook in settings.json"
  fi
}

if command -v jq >/dev/null 2>&1; then
  [[ -f "$SETTINGS" ]] || echo '{}' > "$SETTINGS"
  register_tone_hook "SessionStart"     "$TONE_HOOK session-start"
  register_tone_hook "UserPromptSubmit" "$TONE_HOOK user-prompt-submit"
else
  yellow "  jq not found — add these tone hooks to $SETTINGS manually:"
  cat <<EOF
    "SessionStart":     [ { "matcher": "", "hooks": [ { "type": "command", "command": "$TONE_HOOK session-start" } ] } ],
    "UserPromptSubmit": [ { "matcher": "", "hooks": [ { "type": "command", "command": "$TONE_HOOK user-prompt-submit" } ] } ]
EOF
fi

# ── done ──────────────────────────────────────────────────────────────────────

printf '\n'
bold "Done. Skills installed un-namespaced at the user level ($USER_CLAUDE_DIR)."
echo "  claude          # start a session in any project — skills are active as /verify, /plan, …"
echo "  /initialize     # add the workflow + routing context to a project"
echo "  /problem-spec   # begin your first feature"
printf '\n'
yellow "Prefer the plugin? Uninstall these (rm -rf $SKILLS_DST/<harness skills>) and use:"
yellow "  /plugin marketplace add rolopez23/agent-harness && /plugin install rl-as@agent-harness"

if [[ ${#skipped[@]} -gt 0 ]]; then
  printf '\n'
  bold "Optional skills available (not installed):"
  for s in "${skipped[@]}"; do
    echo "  ./install.sh --with $s"
  done
  echo "  ./install.sh --with all   # install everything"
fi
