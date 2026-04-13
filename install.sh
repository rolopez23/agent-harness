#!/usr/bin/env bash
# install.sh — install harness skills and context files at the user level
#
# Usage:
#   ./install.sh                          # default install into ~/.claude
#   ./install.sh --dir <path>             # alternate Claude Code dir (testing)
#   ./install.sh --with <skill>           # also install an optional skill
#                                         # (repeatable; e.g. --with next-react-boot)
#   ./install.sh --with all               # install every optional skill
#
# Skills land in <claude-dir>/skills/ and context files land in
# <claude-dir>/AGENTS.md and <claude-dir>/CLAUDE.md, so they apply to every
# project automatically.
#
# Optional skills are project bootstraps that only make sense in specific
# stacks. They are skipped by default. Request them explicitly with --with.

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
      sed -n '2,16p' "$0"
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

bold "Skills → $SKILLS_DST"
for s in "${installed[@]+"${installed[@]}"}"; do green  "  + $s"; done
for s in "${updated[@]+"${updated[@]}"}";    do yellow "  ↺ $s"; done
for s in "${skipped[@]+"${skipped[@]}"}";    do printf '  · %s (optional — request with --with %s)\n' "$s" "$s"; done

# ── 2. context files (AGENTS.md + CLAUDE.md) ─────────────────────────────────

HARNESS_REL="$(python3 -c "import os; print(os.path.relpath('$HARNESS_DIR', '$USER_CLAUDE_DIR'))" 2>/dev/null || echo "$HARNESS_DIR")"

skills_table() {
  cat <<EOF
| Skill | Invoke | SKILL.md |
|---|---|---|
| initialize | \`/initialize\` | [→]($HARNESS_REL/skills/initialize/SKILL.md) |
| problem-spec | \`/problem-spec\` | [→]($HARNESS_REL/skills/problem-spec/SKILL.md) |
| plan | \`/plan\` | [→]($HARNESS_REL/skills/plan/SKILL.md) |
| verify | \`/verify\` | [→]($HARNESS_REL/skills/verify/SKILL.md) |
| simplify | \`/simplify\` | [→]($HARNESS_REL/skills/simplify/SKILL.md) |
| refactor | \`/refactor\` | [→]($HARNESS_REL/skills/refactor/SKILL.md) |
| review | \`/review\` | [→]($HARNESS_REL/skills/review/SKILL.md) |
| pr-interactive-walkthrough | \`/pr-interactive-walkthrough\` | [→]($HARNESS_REL/skills/pr-interactive-walkthrough/SKILL.md) |
| learn-from-mistakes | \`/learn-from-mistakes\` | [→]($HARNESS_REL/skills/learn-from-mistakes/SKILL.md) |
| frontend-design | \`/frontend-design\` | [→]($HARNESS_REL/skills/frontend-design/SKILL.md) |
| systematic-debugging | \`/systematic-debugging\` | [→]($HARNESS_REL/skills/systematic-debugging/SKILL.md) |
| dispatching-parallel-agents | \`/dispatching-parallel-agents\` | [→]($HARNESS_REL/skills/dispatching-parallel-agents/SKILL.md) |
| skill-creator | \`/skill-creator\` | [→]($HARNESS_REL/skills/skill-creator/SKILL.md) |
| btw-pull-request | \`/btw-pull-request\` | [→]($HARNESS_REL/skills/btw-pull-request/skill.md) |
EOF
  for s in "${REQUESTED_OPTIONAL[@]+"${REQUESTED_OPTIONAL[@]}"}"; do
    printf '| %s | \`/%s\` | [→](%s/skills/%s/SKILL.md) |\n' "$s" "$s" "$HARNESS_REL" "$s"
  done
}

workflow_block() {
  printf '```\n'
  cat <<'EOF'
/initialize     →  write or update context files in a target project
/problem-spec   →  define the problem, produce docs/<feature>/spec.md
/plan           →  break into TDD chunks, produce docs/<feature>/plan.md

  For each step:
    write tests (red) → write code (green) → refactor → commit
    /verify    →  E2E check against live system
    /simplify  →  clean up staged code
    /review    →  correctness and edge case check
    /pr-interactive-walkthrough  →  cognitive understanding check
    human      →  sign off

/learn-from-mistakes  →  log corrections; updates .claude/learnings.md
EOF
  printf '```\n'
}

# write_context_file <path> <title>
write_context_file() {
  local file="$1"
  local title="$2"   # e.g. "AGENTS.md" or "CLAUDE.md"
  local nested_label="$title"

  cat > "$file" <<EOF
# $title

Read by Claude at the start of every session. Links to skill files rather than
duplicating them. For full instructions, read the linked SKILL.md.

---

## Nested $nested_label

Check for $nested_label in subdirectories before starting work in them.

<!-- nested-agents-index -->
<!-- nested-agents-index-end -->

---

## Workflow

For non-trivial features, follow this order:

$(workflow_block)

---

## Skills

$(skills_table)

---

## Behavioral Rules

Rules added by \`/learn-from-mistakes\` when a pattern recurs 3+ times.

<!-- learned-rules -->
<!-- learned-rules-end -->
EOF
}

# update_context_file <path> <label>
update_context_file() {
  local file="$1"
  local label="$2"
  local changed=false

  if ! grep -q '## Skills' "$file"; then
    printf '\n---\n\n## Skills\n\n%s\n' "$(skills_table)" >> "$file"
    green "  + added ## Skills"
    changed=true
  fi

  if ! grep -q '## Workflow' "$file"; then
    printf '\n---\n\n## Workflow\n\nFor non-trivial features, follow this order:\n\n%s\n' "$(workflow_block)" >> "$file"
    green "  + added ## Workflow"
    changed=true
  fi

  if ! grep -q 'nested-agents-index' "$file"; then
    printf '\n---\n\n## Nested %s\n\nCheck for %s in subdirectories before starting work in them.\n\n<!-- nested-agents-index -->\n<!-- nested-agents-index-end -->\n' "$label" "$label" >> "$file"
    green "  + added nested index"
    changed=true
  fi

  if ! grep -q 'learned-rules' "$file"; then
    printf '\n---\n\n## Behavioral Rules\n\nRules added by `/learn-from-mistakes` when a pattern recurs 3+ times.\n\n<!-- learned-rules -->\n<!-- learned-rules-end -->\n' >> "$file"
    green "  + added learned-rules block"
    changed=true
  fi

  if $changed; then
    green "Updated $file"
  else
    yellow "$file already complete — no changes"
  fi
}

# ── process each context file ─────────────────────────────────────────────────

printf '\n'
bold "Context files → $USER_CLAUDE_DIR"

for fname in AGENTS.md CLAUDE.md; do
  target_file="$USER_CLAUDE_DIR/$fname"
  if [[ ! -f "$target_file" ]]; then
    write_context_file "$target_file" "$fname"
    green "Created $target_file"
  else
    update_context_file "$target_file" "$fname"
  fi
done

# ── done ──────────────────────────────────────────────────────────────────────

printf '\n'
bold "Done. Next steps:"
echo "  claude          # start a session in any project — skills are active"
echo "  /problem-spec   # begin your first feature"
printf '\n'
yellow "Note: skills and context are installed at the user level ($USER_CLAUDE_DIR)."
yellow "They apply to every project automatically. No per-repo install needed."

if [[ ${#skipped[@]} -gt 0 ]]; then
  printf '\n'
  bold "Optional skills available (not installed):"
  for s in "${skipped[@]}"; do
    echo "  ./install.sh --with $s"
  done
  echo "  ./install.sh --with all   # install everything"
fi
